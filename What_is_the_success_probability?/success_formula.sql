--ingredients required: user, attributes, attributes_weight, attribute_lift, score_formula like  (z_points * 0.65) + (cat_points * 0.20) +  (exp_points * 0.15) AS success_score,

WITH success_calc AS (
	SELECT 
	   u.user_id,
	   u.is_success,
	   u.funnel_category,
	   u.experiment_name,
	   u.z_segmentation,
	   z.cat_avg_lift AS z_avg_lift_val,
	   f.cat_avg_lift AS fun_avg_lift_val,
	   e.cat_avg_lift AS exp_avg_lift_val, -- Assuming correct column name from previous scripts
		( (1 + COALESCE(z.cat_avg_lift, 0)) * 0.65 ) + 
		( (1 + COALESCE(f.cat_avg_lift, 0)) * 0.20 ) + 
		( (1 + COALESCE(e.cat_avg_lift, 0)) * 0.15 )
		AS success_score
	FROM Datawarehouse.gold.user_zscore_segmentation u
	    LEFT JOIN Datawarehouse.gold.dim_by_category f ON f.funnel_category = u.funnel_category
	    LEFT JOIN Datawarehouse.gold.dim_by_experiment e ON e.experiment_name = u.experiment_name
	    LEFT JOIN Datawarehouse.gold.dim_by_z_segment z ON z.z_segmentation = u.z_segmentation
),

final_standardization AS (
    SELECT 
        *,
        -- Step 1: Z-Score Normalization
        (success_score - AVG(success_score) OVER()) 
        / NULLIF(STDEV(success_score) OVER(), 0) AS success_score_norm
    FROM success_calc
),

success_probability AS (
    SELECT 
        *,
        -- Step 2: Sigmoid Probability
        1.0 / (1.0 + EXP(-success_score_norm)) AS success_probability_final
    FROM final_standardization
)

-- FINAL OUTPUT: Individual user probabilities with Global Model Fit (KL)
SELECT 
    *,
    -- KL Divergence as a Window Function (OVER()) so we don't need GROUP BY
    AVG(
        CASE 
            WHEN is_success = 1 THEN LOG(1.0 / NULLIF(success_probability_final, 0)) / LOG(2)
            WHEN is_success = 0 THEN LOG(1.0 / NULLIF(1.0 - success_probability_final, 0)) / LOG(2)
            ELSE 0 
        END
    ) OVER() AS sorpresa
FROM success_probability
ORDER BY success_probability_final DESC;
