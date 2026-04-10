-- SUCCESS PROBABILITY CALCULATION TEMPLATE (MANUAL INPUT VERSION)
-- INSTRUCTIONS: 
-- 1. In the 'user_config' CTE below, type your actual column names and the source table.
-- 2. Set your weights and success logic in the 'user_config' and 'mapping' sections.

WITH mapping AS (
    SELECT 
        /* ---------------------------------------------------------
           STEP 1: TYPE YOUR COLUMN NAMES AND SOURCE TABLE HERE
        --------------------------------------------------------- */
        u.user_id              AS uid,            -- <--- Type your User ID column name
        u.max_level_reached    AS success_col,    -- <--- Type your Success Attribute column
        u.z_avg_lift           AS lift_1,         -- <--- Type Attribute 1 Lift column
        u.cat_avg_lift         AS lift_2,         -- <--- Type Attribute 2 Lift column
        u.exp_avg_lift         AS lift_3          -- <--- Type Attribute 3 Lift column
        
    FROM Datawarehouse.gold.user_zscore_segmentation u -- <--- Type your Source Table here
),

user_config AS (
    SELECT 
        *,
        /* ---------------------------------------------------------
           STEP 2: DEFINE YOUR WEIGHTS AND SUCCESS LOGIC
        --------------------------------------------------------- */
        -- Weight definitions (ensure they sum to 1.0 or your desired total)
        0.65 AS w1, 
        0.20 AS w2, 
        0.15 AS w3,
        
        -- Success Condition Logic (Success if True)
        CASE WHEN success_col = 5 THEN 1 ELSE 0 END AS is_success -- <--- Define "Success" here
    FROM mapping
),

success_calc AS (
    SELECT 
        uid AS user_id,
        is_success,
        -- Formula: Sum of ((1 + lift) * weight)
        ( (1 + COALESCE(lift_1, 0)) * w1 ) + 
        ( (1 + COALESCE(lift_2, 0)) * w2 ) + 
        ( (1 + COALESCE(lift_3, 0)) * w3 )
        AS success_score
    FROM user_config
),

final_standardization AS (
    SELECT 
        *,
        -- Step 1: Z-Score Normalization
        (success_score - AVG(success_score) OVER()) 
        / NULLIF(STDEV(success_score) OVER(), 0) AS success_score_norm
    FROM success_calc
)

SELECT 
    *,
    -- Step 2: Sigmoid Function (Probabilidad final)
    1.0 / (1.0 + EXP(-success_score_norm)) AS success_probability_final
FROM final_standardization;
