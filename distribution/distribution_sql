/* TEMPLATE: Regional Outlier & Pareto Analysis
Purpose: Identify top contributors (Top 20%) and measure distribution health (Skewness/Z-Score).
*/

WITH raw_data AS (
    -- Step 1: Join and define your dimension and metric
    SELECT
        a.region AS group_id,
        CAST(d.amount AS FLOAT) AS val
    FROM donations d
    JOIN assignments a ON a.assignment_id = d.assignment_id
),

stats_base AS (
    -- Step 2: Calculate basic stats using Window Functions (Avoids the Join-Back)
    SELECT 
        *,
        COUNT(*) OVER(PARTITION BY group_id) AS n_count,
        SUM(val) OVER(PARTITION BY group_id) AS total_val,
        AVG(val) OVER(PARTITION BY group_id) AS avg_val,
        STDDEV(val) OVER(PARTITION BY group_id) AS stdev_val
    FROM raw_data
),

metrics_calc AS (
    -- Step 3: Advanced Stats (Running Totals, Z-Score, Skewness)
    SELECT
        group_id,
        val,
        total_val,
        avg_val,
        stdev_val,
        -- Coefficient of Variation (CV)
        ROUND(stdev_val / NULLIF(avg_val, 0), 2) AS cv_ratio,
        -- Running Percentage (Pareto Logic)
        SUM(val) OVER(PARTITION BY group_id ORDER BY val DESC) / NULLIF(total_val, 0) AS running_perc,
        -- Relative Rank (0 to 1)
        PERCENT_RANK() OVER(PARTITION BY group_id ORDER BY val DESC) AS p_rank,
        -- Z-Score (Outlier Detection)
        (val - avg_val) / NULLIF(stdev_val, 0) AS z_score,
        -- Skewness (Fisher’s)
        SUM(POWER(val - avg_val, 3)) OVER(PARTITION BY group_id) 
            / (NULLIF((n_count - 1) * POWER(stdev_val, 3), 0)) AS skewness_val
    FROM stats_base
)

-- Step 4: Final Filter & Reporting
SELECT
    group_id,
    ROUND(total_val, 2) AS total,
    ROUND(avg_val, 2) AS average,
    ROUND(cv_ratio, 2) AS volatility_index,
    ROUND(running_perc * 100, 2) AS pct_of_total_revenue,
    ROUND(z_score, 2) AS outlier_score,
    ROUND(skewness_val, 2) AS skewness
FROM metrics_calc
WHERE p_rank <= 0.20  -- Focusing on the Top 20% (Pareto Principle)
ORDER BY group_id, val DESC;
