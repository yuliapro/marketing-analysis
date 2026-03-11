/* TEMPLATE: Experiment Marginal Impact (Shapley-style)
Use this to see how much each experiment improves Conversion Rate compared to a Baseline.
*/

-- Step 0: Define your target experiments here
WITH active_exps AS (
    SELECT 'exp_0' AS exp_id UNION ALL
    SELECT 'exp_1' UNION ALL
    SELECT 'exp_4' UNION ALL
    SELECT 'exp_5'
),

-- Step 1: Normalize raw data
raw_data AS (
    SELECT 
        funnel_category,
        experiment_name,
        -- Success criteria: 1 if converted, 0 if not
        CASE WHEN max_level_reached = 5 THEN 1.0 ELSE 0.0 END AS is_success
    FROM Datawarehouse.gold.vw_user_zscore_segmentation
),

-- Step 2: Calculate CR for Baseline (Users with no experiment or not in our list)
baseline_stats AS (
    SELECT 
        funnel_category,
        AVG(is_success) * 100.0 AS cr_baseline
    FROM raw_data
    WHERE experiment_name IS NULL 
       OR experiment_name NOT IN (SELECT exp_id FROM active_exps)
    GROUP BY funnel_category
),

-- Step 3: Calculate CR for each Experiment individually
experiment_stats AS (
    SELECT 
        funnel_category,
        experiment_name,
        AVG(is_success) * 100.0 AS cr_variant
    FROM raw_data
    WHERE experiment_name IN (SELECT exp_id FROM active_exps)
    GROUP BY funnel_category, experiment_name
),

-- Step 4: Final Calculation (The "Shapley" Lift)
final_comparison AS (
    SELECT 
        e.funnel_category,
        e.experiment_name,
        b.cr_baseline,
        e.cr_variant,
        (e.cr_variant - b.cr_baseline) AS absolute_lift,
        (e.cr_variant - b.cr_baseline) / NULLIF(b.cr_baseline, 0) AS relative_lift_perc
    FROM experiment_stats e
    JOIN baseline_stats b ON e.funnel_category = b.funnel_category
)

SELECT 
    *,
    -- Global average for the experiment across all categories
    AVG(relative_lift_perc) OVER(PARTITION BY experiment_name) AS global_avg_lift
FROM final_comparison
ORDER BY funnel_category, absolute_lift DESC;
