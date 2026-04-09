-- ingredients to get the success_probability_final are useser, attributes_lift, attributes_weight, formula
WITH success_calc AS	(
	SELECT top 1000
	   u. user_id,
-- Numeric attributes (what the model will actually use)
	   CASE WHEN max_level_reached=5 THEN 1
	    	ELSE 0
	    	END AS is_success, 
		( (1 + COALESCE(z.z_avg_lift, 0)) * 0.65 ) + 
		( (1 + COALESCE(f.cat_avg_lift, 0)) * 0.20 ) + 
		( (1 + COALESCE(e.exp_avg_lift, 0)) * 0.15 )
		AS success_score
	FROM Datawarehouse.gold.user_zscore_segmentation u
	    LEFT JOIN Datawarehouse.gold.dim_by_category f ON f.funnel_category = u.funnel_category
	    LEFT JOIN Datawarehouse.gold.dim_by_experiment e ON e.experiment_name = u.experiment_name
	    LEFT JOIN Datawarehouse.gold.dim_by_z_segment z ON z.z_segmentation = u.z_segmentation
	    )
,final_standardization AS (
    SELECT 
        *,
    -- Paso 1: Calculamos el Z del score normalized
        (success_score - AVG(success_score) OVER()) 
        / NULLIF(STDEV(success_score) OVER(), 0) AS success_score_norm
    FROM success_calc
    )

SELECT 
    *,
    -- Paso 2: Aplicamos la Sigmoide (Probabilidad final)
    -- En SQL usamos EXP(-z_final)
    1.0 / (1.0 + EXP(-success_score_norm)) AS success_probability_final
FROM final_standardization

	    

    
    ;




    
--user_id, [date], funnel_type, funnel_category, experiment_name, experiment_group, max_level_reached, duration_seconds, row_num, diff_cube, avg_labour_time, st_dev, z_score, z_segmentation
