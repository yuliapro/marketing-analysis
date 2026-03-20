-- ===========================================================================
-- UNIVERSAL A/B TESTING & LIFT CALCULATOR (Dynamic T-SQL)
-- ===========================================================================
--
-- HOW TO USE THIS SCRIPT:
-- ---------------------------------------------------------------------------
-- 1. TABLE: Set @TableName to your source table.
-- 2. DIMENSIONS: Set @GroupByDimensions to the columns for segments.
--    **LEAVE EMPTY** ('') if you want global results with no grouping.
-- 3. EXP COLUMN: Set @ExperimentColumn to the column identifying the test group.
-- 4. INCLUSION: Set @ExperimentsToInclude to a comma-separated list like
--    'exp_1, exp_4'. Use 'ALL' to include every variant found.
-- 5. TOTAL USERS: Set @TotalUsersCol to the column for reach (or '1' for raw count).
-- 6. CONVERSIONS: Set @ConvertedUsersCol to the column for success.
-- 7. BASELINE: Set @BaselineValue to the value representing the control.
-- ---------------------------------------------------------------------------

-- [USER INPUT SECTION]
DECLARE @TableName             NVARCHAR(256) = 'Datawarehouse.gold.user_statistics';
DECLARE @GroupByDimensions     NVARCHAR(MAX) = ''; 
DECLARE @ExperimentColumn      NVARCHAR(128) = 'experiment_name';
DECLARE @ExperimentsToInclude  NVARCHAR(MAX) = 'exp_1, exp_4, exp_0, exp_2, exp_3, exp_5, exp_7, exp_8, exp_9'; -- e.g. 'exp_1, exp_4, exp_0, exp_2, exp_3, exp_5, exp_7, exp_8, exp_9' or 'ALL'
DECLARE @TotalUsersCol         NVARCHAR(128) = '1'; 
DECLARE @ConvertedUsersCol     NVARCHAR(128) = 'CASE WHEN max_level_reached = 5 THEN 1 ELSE 0 END'; 
DECLARE @BaselineValue         NVARCHAR(128) = 'NULL'; 

-------------------------------------------------------------------------------
-- [CORE ENGINE] - Do not modify below this line
-------------------------------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX);
DECLARE @FinalGroupBy NVARCHAR(MAX) = @ExperimentColumn;
DECLARE @JoinCondition NVARCHAR(MAX) = '1=1';

-- Handle grouping logic
IF ISNULL(@GroupByDimensions, '') <> ''
BEGIN
    SET @FinalGroupBy = @GroupByDimensions + ', ' + @ExperimentColumn;
    SELECT @JoinCondition = '';
    SELECT @JoinCondition = @JoinCondition + 'v.[' + TRIM(value) + '] = b.[' + TRIM(value) + '] AND '
    FROM STRING_SPLIT(@GroupByDimensions, ',');
    SET @JoinCondition = LEFT(@JoinCondition, LEN(@JoinCondition) - 4);
END

-- Handle experiment inclusion filter
DECLARE @ExpFilter NVARCHAR(MAX) = '1=1';
IF @ExperimentsToInclude <> 'ALL'
BEGIN
    SET @ExpFilter = @ExperimentColumn + ' IN (SELECT TRIM(value) FROM STRING_SPLIT(''' + @ExperimentsToInclude + ''', '',''))';
END

SET @SQL = N'
WITH raw_stats AS (
    SELECT 
        ' + CASE WHEN @GroupByDimensions = '' THEN '' ELSE @GroupByDimensions + ',' END + '
        ' + @ExperimentColumn + ' AS exp_variant,
        SUM(CAST(' + @TotalUsersCol + ' AS FLOAT)) AS reach,
        SUM(CAST(' + @ConvertedUsersCol + ' AS FLOAT)) AS conversions
    FROM ' + @TableName + '
    -- Apply experiment list filter OR allow baseline through
    WHERE (' + @ExpFilter + ') 
       OR (' + @ExperimentColumn + ' ' + CASE WHEN @BaselineValue = 'NULL' THEN 'IS NULL' ELSE '= ''' + @BaselineValue + '''' END + ')
    GROUP BY ' + @FinalGroupBy + '
),
cr_calculation AS (
    SELECT 
        *,
        (conversions / NULLIF(reach, 0)) * 100.0 AS conversion_rate
    FROM raw_stats
),
baseline_stats AS (
    SELECT 
        ' + CASE WHEN @GroupByDimensions = '' THEN '' ELSE @GroupByDimensions + ',' END + '
        conversion_rate AS cr_baseline
    FROM cr_calculation
    WHERE exp_variant ' + CASE WHEN @BaselineValue = 'NULL' THEN 'IS NULL' ELSE '= ''' + @BaselineValue + '''' END + '
),
variant_stats AS (
    SELECT 
        ' + CASE WHEN @GroupByDimensions = '' THEN '' ELSE @GroupByDimensions + ',' END + '
        exp_variant,
        conversion_rate AS cr_variant,
        reach AS reach_variant
    FROM cr_calculation
    WHERE exp_variant ' + CASE WHEN @BaselineValue = 'NULL' THEN 'IS NOT NULL' ELSE '<> ''' + @BaselineValue + '''' END + '
)
SELECT 
    v.exp_variant,
    ' + CASE WHEN @GroupByDimensions = '' THEN '' ELSE @GroupByDimensions + ',' END + '
    ROUND(v.cr_variant, 2) AS cr_variant,
    ROUND(b.cr_baseline, 2) AS cr_baseline,
    ROUND(v.cr_variant - b.cr_baseline, 2) AS absolute_lift,
    ROUND(((v.cr_variant - b.cr_baseline) / NULLIF(b.cr_baseline, 0)) * 100.0, 2) AS relative_lift_perc
FROM variant_stats v
INNER JOIN baseline_stats b ON ' + @JoinCondition + '
ORDER BY ' + CASE WHEN @GroupByDimensions = '' THEN 'absolute_lift' ELSE @GroupByDimensions END + ' DESC;
';

EXEC sp_executesql @SQL;
