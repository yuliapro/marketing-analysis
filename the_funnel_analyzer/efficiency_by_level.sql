-- ===========================================================================
-- TEMPLATE: ADVANCED FUNNEL EFFICIENCY (SOLOW-STYLE)
-- ===========================================================================
-- This templat calculates efficiency for each funnel level.
-- based on Solow model and return and waste metrics.
-- Models:  Solow Efficiency: Success / (sqrt(Initial) * Infrastructure). Shows efficiency of each level.
--          Marginal Return: Success / (Initial * Infrastructure).  Shows conversions per resource.
--			Infrastructure Waste: (Initial - Success) * Infrastructure.	Shows resources wasted per each abandoned user
--			Efficiency Delta: (Eficiencia Actual / Eficiencia Anterior) - 1.Change of Efficiency between steps.
-- [USER INPUT SECTION]
DECLARE @TableName         NVARCHAR(256) = 'Datawarehouse.gold.user_zscore_segmentation';
DECLARE @LevelCol          NVARCHAR(128) = 'max_level_reached';
DECLARE @InfrastructureCol NVARCHAR(128) = 'duration_seconds';
DECLARE @TotalUsersCol     NVARCHAR(128) = '1';

-------------------------------------------------------------------------------
-- [CORE ENGINE]
-------------------------------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
WITH base_data AS (
    SELECT 
        ' + @LevelCol + ' AS level_id, 
        CAST(' + @InfrastructureCol + ' AS FLOAT) AS infra_metric,
        CAST(AVG(' + @InfrastructureCol + ') OVER(PARTITION BY ' + @LevelCol + ') AS FLOAT) AS avg_infra,
        CAST(COUNT(*) OVER(PARTITION BY ' + @LevelCol + ') AS FLOAT) AS level_count
    FROM ' + @TableName + '
),
calc_stats AS (
    SELECT 
        *,
        infra_metric - avg_infra AS diff,
        POWER(infra_metric - avg_infra, 2) AS diff_sq,
        POWER(infra_metric - avg_infra, 3) AS diff_cb,
        ROW_NUMBER() OVER(PARTITION BY level_id ORDER BY infra_metric) AS row_num
    FROM base_data
),
summary_stats AS (
    SELECT 
        level_id,
        level_count,
        avg_infra,
        POWER(SUM(diff_sq) / NULLIF(level_count - 1, 0), 0.5) AS std_dev,
        SUM(diff_cb) AS sum_diff_cb
    FROM calc_stats
    GROUP BY level_id, level_count, avg_infra
),
median_lookup AS (
    SELECT level_id, infra_metric AS median_value FROM calc_stats WHERE row_num = CEILING(level_count / 2.0)
),
funnel_calculation AS (
    SELECT 
        s.level_id,
        SUM(s.level_count) OVER(ORDER BY s.level_id DESC) AS users_initialized,
        s.avg_infra,
        m.median_value,
        s.std_dev,
        s.sum_diff_cb,
        s.level_count
    FROM summary_stats s
    JOIN median_lookup m ON s.level_id = m.level_id
),
raw_results AS (
    SELECT 
        f.level_id AS level,
        f.users_initialized AS initial,
        LEAD(f.users_initialized) OVER (ORDER BY f.level_id) AS success,
        f.avg_infra AS infra,
        f.median_value,
        f.std_dev,
        f.sum_diff_cb,
        f.level_count
    FROM funnel_calculation f
),
efficiency_calc AS (
    SELECT 
        *,
        -- FORMULA: SOLOW EFFICIENCY
        -- success / (sqrt(initial) * infra)
        -- Mide la eficiencia técnica del nivel considerando la escala (sqrt) y el recurso (infra).
        ROUND(success / NULLIF(POWER(initial, 0.5) * infra, 0), 4) AS solow_eff,

        -- FORMULA: MARGINAL RETURN
        -- success / (initial * infra)
        -- ¿Cuántas conversiones obtenemos por cada unidad total de "esfuerzo" invertida?
        ROUND(success / NULLIF(initial * infra, 0), 4) AS marginal_return,

        -- FORMULA: INFRASTRUCTURE WASTE
        -- (initial - success) * infra
        -- Cantidad de infraestructura (tiempo/recursos) consumida por usuarios que NO convirtieron.
        ROUND((initial - success) * infra, 2) AS infra_waste
    FROM raw_results
)
SELECT 
    level,
    initial AS [users initials as resources],
    success AS [users success as result],
    ROUND(infra, 2) AS [infrastructure_avg],
    
    solow_eff AS efficiency_solow,
    marginal_return,
    infra_waste,

    -- FORMULA: EFFICIENCY DELTA
    -- (current_eff / prev_eff) - 1
    -- Porcentaje de mejora o deterioro de la eficiencia respecto al nivel anterior.
    ROUND((solow_eff / NULLIF(LAG(solow_eff) OVER (ORDER BY level), 0)) - 1, 4) AS efficiency_delta,

    ROUND(median_value, 2) AS [key_median],
    ROUND(std_dev, 2) AS [key_stdev],
    ROUND(CASE WHEN std_dev = 0 THEN 0 ELSE (sum_diff_cb / (level_count * POWER(std_dev, 3))) END, 2) AS [key_skewness]
FROM efficiency_calc
ORDER BY level;';

PRINT @SQL;
EXEC sp_executesql @SQL;
