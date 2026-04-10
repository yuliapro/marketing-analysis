--ingredients: user_id, dimention to group by,is_success, attributes_lift, attributes_weight, success_formula
--add user input variables, user should put columns of user_id, dimention to group by, is_success, attributes_lift, attributes_weight, success_formula
WITH raw_metrics AS (
    SELECT 
        u.user_id,
        u.experiment_name, -- Necesario para agrupar en la capa de Bernoulli
        CASE WHEN u.max_level_reached = 5 THEN 1.0 ELSE 0.0 END AS is_success,
        (1 + COALESCE(z.z_avg_lift, 0)) AS z_factor,
        (1 + COALESCE(f.cat_avg_lift, 0)) AS cat_factor,
        (1 + COALESCE(e.exp_avg_lift, 0)) AS exp_factor
    FROM Datawarehouse.gold.user_zscore_segmentation u
    LEFT JOIN Datawarehouse.gold.dim_by_category f ON f.funnel_category = u.funnel_category
    LEFT JOIN Datawarehouse.gold.dim_by_experiment e ON e.experiment_name = u.experiment_name
    LEFT JOIN Datawarehouse.gold.dim_by_z_segment z ON z.z_segmentation = u.z_segmentation
),

scoring_base AS (
    SELECT 
        *,
        (z_factor * 0.65) + (cat_factor * 0.20) + (exp_factor * 0.15) AS success_score
    FROM raw_metrics
),

standardization AS (
    SELECT 
        *,
        (success_score - AVG(success_score) OVER()) 
        / NULLIF(STDEV(success_score) OVER(), 0) AS z_final
    FROM scoring_base
),

-- CAPA SIGMOIDE: Probabilidad Individual
probability_layer AS (
    SELECT 
        *,
        1.0 / (1.0 + EXP(-ISNULL(z_final, 0))) AS success_probability_final
    FROM standardization
),

-- CAPA DE BERNOULLI (URN MODEL): Validación de la Muestra por Experimento
bernoulli_layer AS (
    SELECT 
        *,
        -- Calculamos el Error Estándar de la Urna: sqrt(p*(1-p)/n)
        SQRT(
            (AVG(success_probability_final) OVER(PARTITION BY experiment_name) * (1.0 - AVG(success_probability_final) OVER(PARTITION BY experiment_name))) 
            / NULLIF(COUNT(user_id) OVER(PARTITION BY experiment_name), 0)
        ) AS urn_standard_error
    FROM probability_layer
)

-- CONSULTA FINAL: Clasificación y Seguridad
SELECT TOP 1000
    user_id,
    is_success,
    ROUND(success_score, 4) AS success_score,
    ROUND(success_probability_final, 4) AS success_probability_final,
    ROUND(urn_standard_error, 4) AS uncertainty_risk, -- El riesgo de la urna
    
    -- Clasificación de Wolfram basada en Riesgo y Probabilidad
    CASE 
        WHEN urn_standard_error > 0.05 THEN 'Class 3: Chaotic (Low Data)'
        WHEN success_probability_final > 0.80 AND urn_standard_error <= 0.02 THEN 'Class 1: Stable VIP'
        WHEN success_probability_final BETWEEN 0.40 AND 0.80 THEN 'Class 4: Complex Edge'
        ELSE 'Class 2: Periodic/Standard'
    END AS wolfram_segmentation

FROM bernoulli_layer
ORDER BY success_probability_final DESC;
