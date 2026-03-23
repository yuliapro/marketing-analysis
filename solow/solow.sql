/* TEMPLATE: Universal Traffic & Behavior Analysis
Instructions: 
1. Replace 'Datawarehouse.gold.user_zscore_segmentation' with your source table.
2. Replace 'duration_seconds' with the metric you want to analyze (e.g., sessions, spend).
3. Replace 'max_level_reached' with your grouping dimension (e.g., campaign_id, country).
*/

WITH base_data AS (
    -- Step 1: Define your metric and dimension here
    SELECT 
        max_level_reached AS grouping_id, 
        CAST(duration_seconds AS FLOAT)  AS metric_value,
        CAST(COUNT(*)  OVER(PARTITION BY max_level_reached)AS FLOAT) AS total_count,
        AVG(duration_seconds) OVER(PARTITION BY max_level_reached) AS avg_value
    FROM Datawarehouse.gold.user_zscore_segmentation
),

calc_stats AS (
    -- Step 2: Calculate differences for Variance and Skewness
    SELECT 
        *,
        metric_value - avg_value AS diff,
		CAST(POWER(metric_value - avg_value, 2) AS FLOAT) AS diff_sq,
		CAST(POWER(metric_value - avg_value, 3) AS FLOAT) AS diff_cb,
        ROW_NUMBER() OVER(PARTITION BY grouping_id ORDER BY metric_value) AS row_num
    FROM base_data
),

summary_stats AS (
    -- Step 3: Aggregate standard descriptive statistics
    SELECT 
        grouping_id,
        total_count,
        avg_value,
        -- Population Variance
        SUM(diff_sq) / total_count AS variance,
        -- Sample Standard Deviation
        POWER(SUM(diff_sq) / NULLIF(total_count - 1, 0), 0.5) AS std_dev,
        -- Sum of cubes for Fisher's Skewness
        SUM(diff_cb) AS sum_diff_cb
    FROM calc_stats
    GROUP BY grouping_id, total_count, avg_value
),

median_lookup AS (
    -- Step 4: Calculate Median (Middle value)
    SELECT 
        grouping_id,
        metric_value AS median_value
    FROM calc_stats
    WHERE row_num = CEILiNG(total_count / 2.0)
)

--- Final Output ---
SELECT 
    s.grouping_id,
    s.total_count,
    s.avg_value,
    m.median_value,
    s.std_dev,
    -- Efficiency Ratio: Custom marketing metric next/sqt avg * current
    (LEAD(s.total_count) OVER (ORDER BY s.grouping_id) / NULLIF(POWER(s.avg_value, 0.5) * POWER(s.total_count, 0.5), 0)) AS efficiency_index,
    -- Pearson’s Skewness: (Mean - Median) / StdDev
    CASE WHEN s.std_dev = 0 THEN 0 ELSE (3 * (s.avg_value - m.median_value)) / s.std_dev END AS skewness_pearson,
    -- Fisher's Skewness: Adjusted for sample size
    CASE WHEN s.std_dev = 0 THEN 0 ELSE (s.sum_diff_cb / (s.total_count * POWER(s.std_dev, 3))) END AS skewness_fisher
FROM summary_stats s
JOIN median_lookup m ON s.grouping_id = m.grouping_id;
