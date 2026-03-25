-- ===========================================================================
-- TEMPLATE: ADVANCED FUNNEL EFFICIENCY BY SEGMENT (SOLOW-STYLE)
-- ===========================================================================
--
-- HOW TO USE THIS TEMPLATE:
-- ---------------------------------------------------------------------------
-- 1. @TableName: Set the source table (e.g., 'Gold.user_stats').
-- 2. @LevelCol: Set the column representing the funnel steps (e.g., 'step_number').
-- 3. @InfrastructureCol: Set the metric that acts as "Capital/Effort" (e.g., 'cost', 'time').
-- 4. @SegmentCol: Set a dimension to split the analysis (e.g., 'country', 'platform').
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

-- [USER INPUT SECTION]
DECLARE @TableName         NVARCHAR(256) = 'Datawarehouse.gold.user_zscore_segmentation';
DECLARE @LevelCol          NVARCHAR(128) = 'max_level_reached';
DECLARE @InfrastructureCol NVARCHAR(128) = 'duration_seconds';
DECLARE @SegmentCol        NVARCHAR(128) = 'z_segmentation'; -- Set to '1' for global analysis.
DECLARE @CustomFilter      NVARCHAR(MAX) = '1=1';            -- Use '1=1' for no filter.
DECLARE @TotalUsersCol     NVARCHAR(128) = '1';

-------------------------------------------------------------------------------
-- [CORE ENGINE]
-------------------------------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
WITH base_data AS (
    SELECT 
        ' + @SegmentCol + ' AS segment_id,
        ' + @LevelCol + ' AS level_id, 
        CAST(' + @InfrastructureCol + ' AS FLOAT) AS infra_metric,
        CAST(AVG(' + @InfrastructureCol + ') OVER(PARTITION BY ' + @SegmentCol + ', ' + @LevelCol + ') AS FLOAT) AS avg_infra,
        CAST(COUNT(*) OVER(PARTITION BY ' + @SegmentCol + ', ' + @LevelCol + ') AS FLOAT) AS level_count
    FROM ' + @TableName + '
    WHERE ' + ISNULL(@CustomFilter, '1=1') + '
),
calc_stats AS (
    SELECT 
        *,
        infra_metric - avg_infra AS diff,
        POWER(infra_metric - avg_infra, 2) AS diff_sq,
        POWER(infra_metric - avg_infra, 3) AS diff_cb,
        ROW_NUMBER() OVER(PARTITION BY segment_id, level_id ORDER BY infra_metric) AS row_num
    FROM base_data
),
summary_stats AS (
    SELECT 
        segment_id,
        level_id,
        level_count,
        avg_infra,
        POWER(SUM(diff_sq) / NULLIF(level_count - 1, 0), 0.5) AS std_dev,
        SUM(diff_cb) AS sum_diff_cb
    FROM calc_stats
    GROUP BY segment_id, level_id, level_count, avg_infra
),
median_lookup AS (
    SELECT segment_id, level_id, infra_metric AS median_value 
    FROM calc_stats 
    WHERE row_num = CEILING(level_count / 2.0)
),
funnel_calculation AS (
    SELECT 
        s.segment_id,
        s.level_id,
        -- Initialized: Sum of users at this level or higher within the same segment
        SUM(s.level_count) OVER(PARTITION BY s.segment_id ORDER BY s.level_id DESC) AS users_initialized,
        s.avg_infra,
        m.median_value,
        s.std_dev,
        s.sum_diff_cb,
        s.level_count
    FROM summary_stats s
    JOIN median_lookup m ON s.level_id = m.level_id AND s.segment_id = m.segment_id
),
efficiency_calc AS (
    SELECT 
        *,
        -- success: users_initialized of the next level within the same segment
        LEAD(users_initialized) OVER (PARTITION BY segment_id ORDER BY level_id) AS success
    FROM funnel_calculation
)
SELECT 
    segment_id AS segment,
    level_id AS level,
    users_initialized AS [users initials as resources],
    success AS [users success as result],
    ROUND(avg_infra, 2) AS [infrastructure_avg],
    
    -- Solow Efficiency
    ROUND(success / NULLIF(POWER(users_initialized, 0.5) * avg_infra, 0), 4) AS efficiency_solow,
    
    -- Marginal Return
    ROUND(success / NULLIF(users_initialized * avg_infra, 0), 4) AS marginal_return,
    
    -- Infrastructure Waste
    ROUND((users_initialized - success) * avg_infra, 2) AS infra_waste,

    -- Efficiency Delta (vs previous step in the same segment)
    ROUND((success / NULLIF(POWER(users_initialized, 0.5) * avg_infra, 0)) / 
          NULLIF(LAG(success / NULLIF(POWER(users_initialized, 0.5) * avg_infra, 0)) OVER (PARTITION BY segment_id ORDER BY level_id), 0) - 1, 4) AS efficiency_delta,

    ROUND(median_value, 2) AS [key_median],
    ROUND(std_dev, 2) AS [key_stdev],
    ROUND(CASE WHEN std_dev = 0 THEN 0 ELSE (sum_diff_cb / (level_count * POWER(std_dev, 3))) END, 2) AS [key_skewness]
FROM efficiency_calc
ORDER BY segment_id, level_id;';

PRINT @SQL;
EXEC sp_executesql @SQL;
