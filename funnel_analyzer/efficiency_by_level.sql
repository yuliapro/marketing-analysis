-- ===========================================================================
-- TEMPLATE: MULTI-CATEGORY FUNNEL EFFICIENCY (SOLOW-STYLE)
-- ===========================================================================
-- This template runs the Solow Efficiency analysis for multiple categories
-- and combines them into a single report using UNION ALL.
-- Now includes Average Benchmarks per level across all segments.
--
-- HOW TO USE:
-- ---------------------------------------------------------------------------
-- 1. @TableName: Set the source table.
-- 2. @LevelCol: Set the funnel steps column.
-- 3. @InfrastructureCol: Set the effort/capital metric.
-- 4. @GroupByColumns: List the categories you want to analyze, separated by commas.
--    - Use '1' if you want a global analysis without segmentation.
-- 5. @CustomFilter: Set a WHERE clause (e.g., 'date > ''2026-01-01''').
--    - Use '1=1' or NULL to process all data.
-- ---------------------------------------------------------------------------
--
-- FORMULAS USED:
-- - Solow Efficiency: Success / (sqrt(Initial) * Infrastructure). Shows efficiency of each level.
-- - Marginal Return: Success / (Initial * Infrastructure). Shows conversions per resource.
-- - Infrastructure Waste: (Initial - Success) * Infrastructure. Shows resources wasted per each abandoned user
-- - Efficiency Delta: % change in efficiency compared to the previous step. Shows change of Efficiency between steps.
-- ===========================================================================
-- ---------------------------------------------------------------------------

-- [USER INPUT SECTION]
DECLARE @TableName         NVARCHAR(256) = 'Datawarehouse.gold.user_zscore_segmentation';
DECLARE @LevelCol          NVARCHAR(128) = 'max_level_reached';
DECLARE @InfrastructureCol NVARCHAR(128) = 'duration_seconds';
DECLARE @GroupByColumns    NVARCHAR(MAX) = 'funnel_category, z_segmentation, CONVERT(VARCHAR(7), date, 120)'; 
DECLARE @CustomFilter      NVARCHAR(MAX) = '1=1';

-------------------------------------------------------------------------------
-- [CORE ENGINE]
-------------------------------------------------------------------------------
DECLARE @UnionSQL NVARCHAR(MAX) = '';

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
        DECLARE @full_dim NVARCHAR(MAX) = LTRIM(RTRIM(SUBSTRING(@GroupByColumns, @start, CASE WHEN @pos = @len AND @char <> ',' THEN @pos - @start + 1 ELSE @pos - @start END)));
        
        IF @full_dim <> ''
        BEGIN
            DECLARE @expression NVARCHAR(MAX) = @full_dim;
            DECLARE @alias NVARCHAR(128) = '';
            DECLARE @as_pos INT = CHARINDEX(' AS ', UPPER(@full_dim));

            IF @as_pos > 0
            BEGIN
                SET @expression = LTRIM(RTRIM(SUBSTRING(@full_dim, 1, @as_pos - 1)));
                SET @alias = LTRIM(RTRIM(REPLACE(REPLACE(SUBSTRING(@full_dim, @as_pos + 4, LEN(@full_dim)), '[', ''), ']', '')));
            END
            ELSE IF CHARINDEX('(', @full_dim) = 0 
                SET @alias = REPLACE(REPLACE(@full_dim, '[', ''), ']', '');
            ELSE
                SET @alias = 'category_' + CAST(@dim_idx AS NVARCHAR);

            -- Build the SQL block for this specific category
            IF @UnionSQL <> '' SET @UnionSQL = @UnionSQL + ' UNION ALL ';
            
            SET @UnionSQL = @UnionSQL + '
            SELECT 
                ''' + @alias + ''' AS segment_type,
                CAST(' + @expression + ' AS NVARCHAR(MAX)) AS segment_value,
                ' + @LevelCol + ' AS level_id,
                CAST(' + @InfrastructureCol + ' AS FLOAT) AS infra_metric
            FROM ' + @TableName + '
            WHERE ' + ISNULL(@CustomFilter, '1=1');
            
            SET @dim_idx = @dim_idx + 1;
        END
        SET @start = @pos + 1;
    END
    SET @pos = @pos + 1;
END

DECLARE @FinalSQL NVARCHAR(MAX) = N'
WITH raw_data AS (
    ' + @UnionSQL + '
),
base_stats AS (
    SELECT 
        segment_type,
        segment_value,
        level_id,
        CAST(COUNT(*) AS FLOAT) AS level_count,
        CAST(AVG(infra_metric) AS FLOAT) AS avg_infra,
        CAST(STDEV(infra_metric) AS FLOAT) AS std_infra
    FROM raw_data
    GROUP BY segment_type, segment_value, level_id
),
initials_calc AS (
    SELECT 
        *,
        SUM(level_count) OVER(PARTITION BY segment_type, segment_value ORDER BY level_id DESC) AS initial
    FROM base_stats
),
success_calc AS (
    SELECT 
        *,
        LEAD(initial) OVER(PARTITION BY segment_type, segment_value ORDER BY level_id) AS success
    FROM initials_calc
),
efficiency_metrics AS (
    SELECT 
        *,
        -- FORMULA: SOLOW EFFICIENCY = success / (sqrt(initial) * infra)
        ROUND(success / NULLIF(POWER(initial, 0.5) * avg_infra, 0), 4) AS solow_eff,
        -- FORMULA: MARGINAL RETURN = success / (initial * infra)
        ROUND(success / NULLIF(initial * avg_infra, 0), 4) AS marginal_return,
        -- FORMULA: INFRASTRUCTURE WASTE = (initial - success) * infra
        ROUND((initial - success) * avg_infra, 2) AS infra_waste
    FROM success_calc
),
delta_calc AS (
    SELECT 
        *,
        -- FORMULA: EFFICIENCY DELTA
        ROUND((solow_eff / NULLIF(LAG(solow_eff) OVER (PARTITION BY segment_type, segment_value ORDER BY level_id), 0)) - 1, 4) AS efficiency_delta
    FROM efficiency_metrics
)
SELECT 
    segment_type,
    segment_value,
    level_id AS level,
    initial AS [users initials as resources],
    success AS [users success as result],
    ROUND(avg_infra, 2) AS [infrastructure_avg],
    
    solow_eff AS efficiency,
    marginal_return AS return_per_resource,
    infra_waste AS _waste_per_user,
    efficiency_delta,

    -- Benchmarks: Average values per level across ALL segments
    ROUND(AVG(solow_eff) OVER(PARTITION BY level_id), 4) AS [avg_efficiency_level],
    ROUND(AVG(marginal_return) OVER(PARTITION BY level_id), 4) AS [avg_return_per_resource_level],
    ROUND(AVG(infra_waste) OVER(PARTITION BY level_id), 2) AS [avg_waste_per_user_level],
    ROUND(AVG(efficiency_delta) OVER(PARTITION BY level_id), 4) AS [avg_efficiency_delta_level],

    ROUND(std_infra, 2) AS [stdev_infra]
FROM delta_calc
ORDER BY segment_type, segment_value, level_id;';

PRINT @FinalSQL;
EXEC sp_executesql @FinalSQL;
