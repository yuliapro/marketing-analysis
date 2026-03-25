-- ===========================================================================
-- TEMPLATE: MULTI-CATEGORY FUNNEL EFFICIENCY (SOLOW-STYLE)
-- ===========================================================================
-- This template runs the Solow Efficiency analysis for multiple categories
-- and combines them into a single report using UNION ALL.
-- Includes Averages, Medians, Skewness, and Level Benchmarks.
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

-- Robust splitting logic to handle expressions with commas
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
base_means AS (
    SELECT 
        segment_type, segment_value, level_id,
        AVG(infra_metric) AS avg_infra,
        COUNT(*) AS level_count
    FROM raw_data
    GROUP BY segment_type, segment_value, level_id
),
diffs AS (
    SELECT 
        r.*,
        m.avg_infra,
        m.level_count,
        r.infra_metric - m.avg_infra AS diff,
        ROW_NUMBER() OVER(PARTITION BY r.segment_type, r.segment_value, r.level_id ORDER BY r.infra_metric) AS row_num
    FROM raw_data r
    JOIN base_means m ON r.segment_type = m.segment_type AND r.segment_value = m.segment_value AND r.level_id = m.level_id
),
summary_stats AS (
    SELECT 
        segment_type, segment_value, level_id, level_count, avg_infra,
        POWER(SUM(POWER(diff, 2)) / NULLIF(level_count - 1, 0), 0.5) AS std_infra,
        SUM(POWER(diff, 3)) AS sum_diff_cb
    FROM diffs
    GROUP BY segment_type, segment_value, level_id, level_count, avg_infra
),
median_lookup AS (
    SELECT segment_type, segment_value, level_id, infra_metric AS median_infra
    FROM diffs
    WHERE row_num = CEILING(level_count / 2.0)
),
funnel_calc AS (
    SELECT 
        s.*, m.median_infra,
        SUM(s.level_count) OVER(PARTITION BY s.segment_type, s.segment_value ORDER BY s.level_id DESC) AS initial
    FROM summary_stats s
    JOIN median_lookup m ON s.segment_type = m.segment_type AND s.segment_value = m.segment_value AND s.level_id = m.level_id
),
success_calc AS (
    SELECT 
        *,
        LEAD(initial) OVER(PARTITION BY segment_type, segment_value ORDER BY level_id) AS success
    FROM funnel_calc
),
efficiency_metrics AS (
    SELECT 
        *,
        ROUND(success / NULLIF(POWER(initial, 0.5) * avg_infra, 0), 4) AS efficiency,
        ROUND(success / NULLIF(initial * avg_infra, 0), 4) AS return_per_resource,
        ROUND((initial - success) * avg_infra, 2) AS _waste_per_user
    FROM success_calc
),
delta_calc AS (
    SELECT 
        *,
        ROUND((efficiency / NULLIF(LAG(efficiency) OVER (PARTITION BY segment_type, segment_value ORDER BY level_id), 0)) - 1, 4) AS efficiency_delta
    FROM efficiency_metrics
)
SELECT 
    segment_type,
    segment_value,
    level_id AS level,
    initial AS [users initials as resources],
    success AS [users success as result],
    ROUND(avg_infra, 2) AS [infrastructure_avg],
    efficiency,
    return_per_resource,
    _waste_per_user,
    efficiency_delta,

    -- Benchmarks
    ROUND(AVG(efficiency) OVER(PARTITION BY level_id), 4) AS [avg_efficiency_level],
    ROUND(AVG(return_per_resource) OVER(PARTITION BY level_id), 4) AS [avg_return_per_resource_level],
    ROUND(AVG(_waste_per_user) OVER(PARTITION BY level_id), 2) AS [avg_waste_per_user_level],
    ROUND(AVG(efficiency_delta) OVER(PARTITION BY level_id), 4) AS [avg_efficiency_delta_level],

    -- Detailed Stats
    ROUND(median_infra, 2) AS [infrastructure_median],
    ROUND(std_infra, 2) AS [infrastructure_stdev],
    ROUND(CASE WHEN std_infra = 0 THEN 0 ELSE (sum_diff_cb / (level_count * POWER(std_infra, 3))) END, 2) AS [infrastructure_skewness]
FROM delta_calc
ORDER BY segment_type, segment_value, level_id;';

PRINT @FinalSQL;
EXEC sp_executesql @FinalSQL;
