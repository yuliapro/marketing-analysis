--ingredients required: user, attributes, attributes_weight, attribute_lift, score_formula like  (z_points * 0.65) + (cat_points * 0.20) +  (exp_points * 0.15) AS success_score,

WITH user_attributes AS (
    SELECT 
        u.user_id,
        u.funnel_type, 
        u.funnel_category, 
        u.experiment_name, 
        u.z_segmentation,
        u.max_level_reached, 
        u.duration_seconds,
        u.z_score,
        COALESCE(f.cat_avg_lift, 0) AS cat_weight, 
        COALESCE(e.exp_avg_lift, 0) AS exp_weight,
        COALESCE(z.z_avg_lift, 0) AS z_avg_lift
    FROM Datawarehouse.gold.user_zscore_segmentation u
        LEFT JOIN Datawarehouse.gold.dim_by_category f ON f.funnel_category = u.funnel_category
        LEFT JOIN Datawarehouse.gold.dim_by_experiment e ON e.experiment_name = u.experiment_name
        LEFT JOIN Datawarehouse.gold.dim_by_z_segment z ON z.z_segmentation = u.z_segmentation
    WHERE u.experiment_name <> 'exp_6' -- Excluded as it was a perfect predictor
),
scored_data AS (
    SELECT 
        *,
        -- 1. Normalize Z-Score (Scale -1 to 2.5 into 0 to 100)
        CASE 
            WHEN z_score <= -1 THEN 0
            WHEN z_score >= 2.5 THEN 100
            ELSE (z_score + 1) / 3.5 * 100 
        END AS z_points,

        -- 2. Normalize Category Lift (0% lift = 50 pts, +50% lift = 100 pts)
        CASE 
            WHEN cat_weight >= 50 THEN 100
            WHEN cat_weight <= -50 THEN 0
            ELSE (cat_weight + 50) 
        END AS cat_points,

        -- 3. Normalize Experiment Lift (0% lift = 50 pts, +50% lift = 100 pts)
        CASE 
            WHEN exp_weight >= 50 THEN 100
            WHEN exp_weight <= -50 THEN 0
            ELSE (exp_weight + 50) 
        END AS exp_points
    FROM user_attributes
)
SELECT 
    user_id,
    z_segmentation,
    experiment_name,
    ROUND(z_score, 2) AS z_score,
    ROUND(cat_weight, 2) AS cat_lift,
    ROUND(exp_weight, 2) AS exp_lift,
    -- FINAL SUCCESS SCORE (Weighted sum)
    ROUND(
        (z_points * 0.65) + 
        (cat_points * 0.20) + 
        (exp_points * 0.15), 
    2) AS success_score,
    -- Simple Success Flag for validation
    CASE WHEN max_level_reached = 5 THEN 1 ELSE 0 END AS actual_success
FROM scored_data
ORDER BY success_score DESC;
