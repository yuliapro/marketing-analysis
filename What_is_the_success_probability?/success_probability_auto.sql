-- PROBABILITY TRUSTOMETER TEMPLATE
-- This model calculates Success Probability + Uncertainty (Risk) based on sample size.
-- INSTRUCTIONS: 
-- 1. STEP 1: Type your actual column names and source table in the 'mapping' CTE.
-- 2. STEP 2: Define your weights and success logic in the 'config' CTE.

WITH mapping AS (
    SELECT 
        /* ---------------------------------------------------------
           STEP 1: TYPE YOUR COLUMN NAMES AND SOURCE TABLE HERE
        --------------------------------------------------------- */
        u.user_id              AS uid,            -- <--- Your User ID column
        u.experiment_name      AS group_dim,      -- <--- Column to group by for Trust/Error calc (e.g., experiment_name)
        u.is_success           AS success_raw,    -- <--- Raw column for success check
        z.z_avg_lift           AS l1,             -- <--- Attribute 1 Lift column
        f.cat_avg_lift         AS l2,             -- <--- Attribute 2 Lift column
        e.exp_avg_lift         AS l3              -- <--- Attribute 3 Lift column
        
    FROM Datawarehouse.gold.user_zscore_segmentation u -- <--- Your Source Table here
    -- Add your JOINs here if your lifts are in other tables:
    LEFT JOIN Datawarehouse.gold.dim_by_category f ON f.funnel_category = u.funnel_category
    LEFT JOIN Datawarehouse.gold.dim_by_experiment e ON e.experiment_name = u.experiment_name
    LEFT JOIN Datawarehouse.gold.dim_by_z_segment z ON z.z_segmentation = u.z_segmentation
),

config AS (
    SELECT 
        *,
        /* ---------------------------------------------------------
           STEP 2: DEFINE YOUR WEIGHTS AND SUCCESS LOGIC
        --------------------------------------------------------- */
        -- Weights for the formula
        0.65 AS w1, 
        0.20 AS w2, 
        0.15 AS w3
    FROM mapping
),

/* ---------------------------------------------------------
           STEP CORE: AUTOMATIC CALCULATION
--------------------------------------------------------- */

scoring_base AS (
    SELECT 
        *,
        -- Success Score calculation: Sum of ((1 + lift) * weight)
        ( (1 + COALESCE(l1, 0)) * w1 ) + 
        ( (1 + COALESCE(l2, 0)) * w2 ) + 
        ( (1 + COALESCE(l3, 0)) * w3 )
        AS success_score
    FROM config
),

standardization AS (
    SELECT 
        *,
        -- Z-Score Normalization
        (success_score - AVG(success_score) OVER()) 
        / NULLIF(STDEV(success_score) OVER(), 0) AS z_final
    FROM scoring_base
),

-- CAPA SIGMOIDE: Individual Probability
probability_layer AS (
    SELECT 
        *,
        1.0 / (1.0 + EXP(-ISNULL(z_final, 0))) AS success_probability_final
    FROM standardization
),

-- CAPA DE BERNOULLI (URN MODEL): Validation of Sample Trust by Grouping Dimension
bernoulli_layer AS (
    SELECT 
        *,
        -- Standard Error of the Urn: sqrt(p*(1-p)/n)
        -- Represents the statistical "Uncertainty" of the segment
        SQRT(
            (AVG(success_probability_final) OVER(PARTITION BY group_dim) * (1.0 - AVG(success_probability_final) OVER(PARTITION BY group_dim))) 
            / NULLIF(COUNT(uid) OVER(PARTITION BY group_dim), 0)
        ) AS urn_standard_error
    FROM probability_layer
)

-- FINAL OUTPUT: Classification and Trust Metrics
SELECT 
    uid AS user_id,
    group_dim AS segment,
    success_raw,
    success_score,
    ROUND(success_probability_final, 4) AS success_probability,
    ROUND(urn_standard_error, 4) AS uncertainty_risk, -- Statistical risk of the segment
    
    -- Wolfram-style Segmentation based on Risk and Probability
    CASE 
        WHEN urn_standard_error > 0.05 THEN 'Class 3: Chaotic (Low Data/High Uncertainty)'
        WHEN success_probability_final > 0.80 AND urn_standard_error <= 0.02 THEN 'Class 1: Stable Success'
        WHEN success_probability_final BETWEEN 0.40 AND 0.80 THEN 'Class 4: Complex Edge (Sensitive)'
        ELSE 'Class 2: Standard/Periodic'
    END AS trustometer_segmentation

FROM bernoulli_layer
ORDER BY success_probability DESC;
