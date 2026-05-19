/* 
=============================================================================
🚀 BEHAVIORAL PHYSICS ENGINE (BPE) - STRATEGIC ACTION TEMPLATE
=============================================================================
An advanced analytical framework that applies thermodynamic principles and 
statistical physics to user duration data. 

This engine goes beyond simple funnel metrics to identify the "WHY" behind 
user behavior using the Psychological Stability Index (PSI / ψ).

💡 KEY METRICS & THRESHOLDS:
-----------------------------------------------------------------------------
1. FLOW (ψ > 2.0): 
   Momentum >> Instability. The user is "locked in." 
   Target: Value Capture. Action: UPSELL / MONETIZE.

2. AT EDGE (ψ 0.5 - 2.0): 
   Equilibrium. User is on the edge; tiny friction can cause churn.
   Target: Retention. Action: REWARD / BOOST MOTIVATION.

3. DIFFICULT (ψ 0.0 - 0.5): 
   Instability > Momentum. Behavior is forced or chaotic. 
   Target: UX Friction. Action: GUIDE / TRIGGER TUTORIAL.

4. CONFLICT (ψ < 0.0): 
   System Conflict. Intent is negative or crashing. High churn risk.
   Target: Recovery. Action: RE-ENGAGE / RECOVER.

5. INTENT FLUX (Efficiency):
   Ratio of Conversion vs. Churn. 
   > 1.0 = "Heating Up" (Efficient). < 1.0 = "Leaking" (Wasteful).

INSTRUCTIONS:
1. Set @TableName and core columns (@UserIDCol, @SuccessCol, Dimensions).
2. The engine calculates Z-Scores for Momentum and Instability to derive PSI.
3. Use the ''action'' column for surgical product interventions.
=============================================================================
*/

DECLARE @TableName    NVARCHAR(MAX) = 'Datawarehouse.gold.user_zscore_segmentation';
DECLARE @UserIDCol    NVARCHAR(MAX) = 'user_id';
DECLARE @SuccessCol   NVARCHAR(MAX) = 'is_success';
DECLARE @Dim1Col      NVARCHAR(MAX) = 'FLOOR(duration_seconds / 60)'; -- Dimension 1: Time
DECLARE @Dim2Col      NVARCHAR(MAX) = 'max_level_reached';           -- Dimension 2: Level

-- -----------------------------------------------------------------------------
-- ⚙️ ENGINE (Dynamic execution)
-- -----------------------------------------------------------------------------
DECLARE @DynamicSQL NVARCHAR(MAX);

SET @DynamicSQL = N'
WITH base AS (
    SELECT 
        ' + @UserIDCol + N' AS user_id,
        ' + @SuccessCol + N' AS is_success, 
        ' + @Dim1Col + N' AS minutes,
        ' + @Dim2Col + N' AS level,
        -- CRITICAL: Create a numeric sequence for correct physics ordering
        DENSE_RANK() OVER (ORDER BY ' + @Dim1Col + N', ' + @Dim2Col + N') AS progression_step
    FROM ' + @TableName + N'
),

by_min AS (
    SELECT
        progression_step,
        MAX(minutes) AS minutes,
        MAX(level) AS level,
        COUNT(user_id) AS users_cnt,
        SUM(CAST(is_success AS INT)) AS success_cnt,
        ROUND(AVG(CAST(is_success AS FLOAT)) * 100, 2) AS success_rate_step
    FROM base
    GROUP BY progression_step 
),

by_cumm AS (
    SELECT *,
        -- Total users who reached AT LEAST this progression step (Survival)
        SUM(users_cnt) OVER (ORDER BY progression_step DESC) AS survival_cumm, 
        -- Total successes up to this step
        SUM(success_cnt) OVER (ORDER BY progression_step ASC) AS success_cumm,
        -- Cumulative success rate
        ROUND(CAST(SUM(success_cnt) OVER (ORDER BY progression_step ASC) AS FLOAT) / 
              NULLIF(SUM(users_cnt) OVER (ORDER BY progression_step ASC), 0) * 100, 2) AS success_rate,
        ROUND(AVG(success_rate_step) OVER(), 2) AS global_avg_success
    FROM by_min
),

calc AS (
    SELECT *,
        -- MARKOV: Survival Probability between steps
        ROUND((CAST(LEAD(survival_cumm) OVER (ORDER BY progression_step) AS FLOAT) / NULLIF(survival_cumm, 0)) * 100, 2) AS p_stay
    FROM by_cumm
),

metrics_report AS (
    SELECT 
        progression_step,
        minutes,
        level,
        users_cnt,
        success_cnt,
        success_rate,
        success_rate_step,
        survival_cumm,
        success_cumm,
        p_stay,
        
        -- TIPPING POINT: When survival momentum deviates from the population average
        ROUND(p_stay - AVG(p_stay) OVER(ORDER BY progression_step), 2) AS tipping_point,
        
        -- INSTABILITY: System Energy 
        ROUND(POWER(p_stay - (100.0 - global_avg_success), 2), 2) AS instability,

        -- INSTABILITY DELTA: Rate of change of stability
        ROUND(POWER(p_stay - (100.0 - global_avg_success), 2) - 
              LAG(POWER(p_stay - (100.0 - global_avg_success), 2)) OVER (ORDER BY progression_step), 2) AS instability_delta,
        
        -- BEHAVIORAL MOMENTUM: Golden Points intersection
        ROUND(success_cnt * p_stay, 0) AS behavioral_momentum,

        -- INTENT FLUX (Efficiency Ratio): Conversion vs. Churn
         ROUND(success_rate - LAG(success_rate) OVER (ORDER BY progression_step), 2) AS intent

    FROM calc
    WHERE users_cnt >= 20 -- Lowered threshold for high-resolution 2D data
),

final_analysis AS (
    SELECT 
        *,
        -- STATISTICAL Z-SCORES (Self-healing thresholds)
        ROUND((behavioral_momentum - AVG(behavioral_momentum) OVER()) / NULLIF(STDEV(behavioral_momentum) OVER(), 0), 2) AS z_momentum,
        ROUND((instability - AVG(instability) OVER()) / NULLIF(STDEV(instability) OVER(), 0), 2) AS z_instability,
        -- PSI (ψ)
        ROUND(ROUND((behavioral_momentum - AVG(behavioral_momentum) OVER()) / NULLIF(STDEV(behavioral_momentum) OVER(), 0), 2) / 
              NULLIF(ROUND((instability - AVG(instability) OVER()) / NULLIF(STDEV(instability) OVER(), 0), 2), 0), 2) AS psi
    FROM metrics_report
)

SELECT 
    progression_step,
    minutes,
    level,
    users_cnt,
    success_rate AS cr_cum,
	tipping_point AS grip,
    intent,
    p_stay AS retention,
    
    -- PSYCHOLOGICAL STABILITY INDEX (PSI / ψ)
    psi ,

    -- SESSION HEALTH (Diagnostic)
    CASE 
        WHEN psi > 2.0 THEN ''VIBRANT: Flow State''
        WHEN psi BETWEEN 0.5 AND 2.0 THEN ''AT EDGE: Turbulent''
        WHEN psi BETWEEN 0.0 AND 0.5 THEN ''DIFFICULT: Stagnant''
        WHEN psi < 0.0 THEN ''CONFLICT: Terminal''
        ELSE ''NEUTRAL''
    END AS session_health,

    -- STRATEGIC ACTION
    CASE 
        WHEN psi > 2.0 THEN ''UPSELL: Pro / Monetize''
        WHEN psi BETWEEN 0.5 AND 2.0 THEN ''REWARD: Boost Motivation''
        WHEN psi BETWEEN 0.0 AND 0.5 THEN ''GUIDE: Trigger Tutorial / Skip''
        WHEN psi < 0.0 THEN ''RE-ENGAGE: Recover User''
        ELSE ''PIN: Micro-retention hook''
    END AS action
FROM final_analysis
ORDER BY progression_step;
';

EXEC sp_executesql @DynamicSQL;
