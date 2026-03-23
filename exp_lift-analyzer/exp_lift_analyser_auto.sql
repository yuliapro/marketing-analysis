-- ===========================================================================
-- DETAILED CATEGORY BREAKDOWN A/B TEST LIFT
-- ===========================================================================
-- This script provides a granular breakdown of lift for each experiment variant
-- inside every segment of the specified grouping columns.
--
-- [USER INPUT SECTION]
DECLARE @TableName             NVARCHAR(256) = 'Datawarehouse.gold.user_zscore_segmentation';
DECLARE @ExperimentColumn      NVARCHAR(128) = 'experiment_name';
DECLARE @GroupByColumns        NVARCHAR(MAX) = 'funnel_category, z_segmentation, CONVERT(VARCHAR(7), date, 120)'; 
DECLARE @TotalUsersCol         NVARCHAR(128) = '1'; 
DECLARE @ConvertedUsersCol     NVARCHAR(128) = 'CASE WHEN max_level_reached = 5 THEN 1 ELSE 0 END'; 
DECLARE @BaselineValue         NVARCHAR(128) = 'NULL'; 
DECLARE @ExperimentsToInclude  NVARCHAR(MAX) = 'ALL'; 

-------------------------------------------------------------------------------
-- [CORE ENGINE]
-------------------------------------------------------------------------------
DECLARE @UnionSections NVARCHAR(MAX) = '';

-- Robust splitting logic to handle expressions with commas (Pure T-SQL)
DECLARE @pos INT = 1;
DECLARE @start INT = 1;
DECLARE @depth INT = 0;
DECLARE @len INT = LEN(@GroupByColumns);
DECLARE @dim_idx INT = 1;

WHILE @pos <= @len
BEGIN
    DECLARE @char NCHAR(1) = SUBSTRING(@GroupByColumns, @pos, 1);
    IF @char = '(' SET @depth = @depth + 1;
    ELSE IF @char = ')' SET @depth = @depth - 1;
    
    IF (@char = ',' AND @depth = 0) OR @pos = @len
    BEGIN
        DECLARE @dim_val NVARCHAR(MAX) = LTRIM(RTRIM(SUBSTRING(@GroupByColumns, @start, CASE WHEN @pos = @len AND @char <> ',' THEN @pos - @start + 1 ELSE @pos - @start END)));
        
        IF @dim_val <> ''
        BEGIN
            DECLARE @detected_alias NVARCHAR(128) = '';
            IF CHARINDEX(' AS ', UPPER(@dim_val)) > 0
                SET @detected_alias = LTRIM(RTRIM(REPLACE(REPLACE(SUBSTRING(@dim_val, CHARINDEX(' AS ', UPPER(@dim_val)) + 4, LEN(@dim_val)), '[', ''), ']', '')));
            ELSE IF CHARINDEX('(', @dim_val) = 0 
                SET @detected_alias = REPLACE(REPLACE(@dim_val, '[', ''), ']', '');
            ELSE
                SET @detected_alias = 'category_' + CAST(@dim_idx AS NVARCHAR);

            -- Build a UNION segment for this category
            IF @UnionSections <> '' SET @UnionSections = @UnionSections + ' UNION ALL ';
            
            SET @UnionSections = @UnionSections + '
    SELECT 
        ''' + @detected_alias + ''' AS category_name,
        CAST(' + @dim_val + ' AS NVARCHAR(MAX)) AS segment_value,
        ' + @ExperimentColumn + ' AS exp_variant,
        SUM(CAST(' + @TotalUsersCol + ' AS FLOAT)) AS reach,
        (SUM(CAST(' + @ConvertedUsersCol + ' AS FLOAT)) / NULLIF(SUM(CAST(' + @TotalUsersCol + ' AS FLOAT)), 0)) * 100.0 AS cr
    FROM ' + @TableName + '
    GROUP BY ' + @ExperimentColumn + ', ' + @dim_val;
            
            SET @dim_idx = @dim_idx + 1;
        END
        SET @start = @pos + 1;
    END
    SET @pos = @pos + 1;
END

-- Handle experiment inclusion filter
DECLARE @ExpInclusionFilter NVARCHAR(MAX) = '1=1';
IF @ExperimentsToInclude <> 'ALL'
BEGIN
    SET @ExpInclusionFilter = ''',' + REPLACE(@ExperimentsToInclude, ' ', '') + ','' LIKE ''%,'' + CAST(' + @ExperimentColumn + ' AS VARCHAR) + '',%''';
END

DECLARE @SQL NVARCHAR(MAX) = '
WITH raw_data AS (' + @UnionSections + '
),
baseline_data AS (
    SELECT category_name, segment_value, cr AS cr_baseline, reach AS reach_baseline
    FROM raw_data
    WHERE exp_variant ' + CASE WHEN @BaselineValue = 'NULL' THEN 'IS NULL' ELSE '= ''' + @BaselineValue + '''' END + '
)
SELECT 
    v.category_name,
    v.segment_value,
    v.exp_variant,
    CAST(v.reach AS INT) AS reach_variant,
    ROUND(v.cr, 2) AS cr_variant_perc,
    ROUND(b.cr_baseline, 2) AS cr_baseline_perc,
    ROUND(v.cr - b.cr_baseline, 2) AS absolute_lift,
    ROUND(((v.cr - b.cr_baseline) / NULLIF(b.cr_baseline, 0)) * 100.0, 2) AS relative_lift_perc,
	ROUND(AVG(((v.cr - b.cr_baseline) / NULLIF(b.cr_baseline, 0)) )OVER (PARTITION BY v.exp_variant)* 100.0, 2) AS avg_relative_lift_perc
FROM raw_data v
LEFT JOIN baseline_data b ON v.category_name = b.category_name AND v.segment_value = b.segment_value
WHERE v.exp_variant ' + CASE WHEN @BaselineValue = 'NULL' THEN 'IS NOT NULL' ELSE '<> ''' + @BaselineValue + '''' END + '
  AND (' + REPLACE(@ExpInclusionFilter, @ExperimentColumn, 'v.exp_variant') + ') 
	AND v.reach > 200
ORDER BY v.exp_variant;';

PRINT @SQL;
EXEC sp_executesql @SQL;
