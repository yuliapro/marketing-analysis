/* TEMPLATE: Multi-Metric Weighted Scoring (Normalization)
Purpose: Rank users by combining two different metrics (e.g., Volume vs. Value).
*/

WITH raw_metrics AS (
    -- Step 1: Replace these columns with whatever you want to rank
    SELECT
        donor_id AS entity_id,
        CAST(COUNT(donation_id) AS FLOAT) AS metric_a, -- e.g., Frequency
        CAST(SUM(amount) AS FLOAT)      AS metric_b  -- e.g., Monetary Value
    FROM donations
    GROUP BY 1
),

limits AS (
    -- Step 2: Get Min/Max for normalization using window functions (no join needed)
    SELECT 
        *,
        MAX(metric_a) OVER() AS max_a,
        MIN(metric_a) OVER() AS min_a,
        MAX(metric_b) OVER() AS max_b,
        MIN(metric_b) OVER() AS min_b
    FROM raw_metrics
),

normalized AS (
    -- Step 3: Scale metrics between 0 and 1
    SELECT 
        entity_id,
        metric_a,
        metric_b,
        (metric_a - min_a) / NULLIF(max_a - min_a, 0) AS norm_a,
        (metric_b - min_b) / NULLIF(max_b - min_b, 0) AS norm_b
    FROM limits
)

-- Step 4: Apply Weights and Score
-- ADJUST WEIGHTS HERE: Ensure they sum to 1.0 (e.g., 0.3 and 0.7)
SELECT 
    entity_id,
    metric_a AS frequency,
    metric_b AS monetary,
    ROUND(norm_a, 4) AS score_frequency,
    ROUND(norm_b, 4) AS score_monetary,
    ROUND((norm_a * 0.3) + (norm_b * 0.7), 4) AS final_donor_score
FROM normalized
ORDER BY final_donor_score DESC;
