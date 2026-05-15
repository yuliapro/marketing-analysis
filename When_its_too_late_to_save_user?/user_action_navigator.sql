/* 
=============================================================================
🚀 BEHAVIORAL PHYSICS ENGINE (BPE) - STRATEGIC ACTION TEMPLATE
=============================================================================
An advanced analytical framework that applies thermodynamic principles and 
statistical physics to user duration data. 

This engine goes beyond simple funnel metrics to answer the "WHY" behind 
user behavior using Markov Survival, Lyapunov Instability, and Z-Score Momentum.

💡 KEY QUESTIONS THIS ANALYSIS ANSWERS:
-----------------------------------------------------------------------------
1. THE ACTION POINT: At what exact minute is the user most likely to convert 
   before their interest begins to decay?
2. INERTIA VS. FORCE: Is the user staying because of a genuine habit (Inertia) 
   or because the system is pushing them through friction (External Force)?
3. UX OPTIMIZATION: Where should we simplify the UI (High Friction) vs. where 
   should we trigger monetization (High Habit)?
4. SESSION HEALTH: Is the user "Warming Up" (Intent Hardening) or is the 
   session entering "Cooling Down" (System Decay)?
5. STATISTICAL CERTAINTY: Is a specific behavior a random flicker or a 
   statistically significant trend (Z-Score > 1)?

INSTRUCTIONS:
1. Set the @TableName and core column names in the variables below.
2. The script calculates Instability, Tipping Points, and Z-Scores.
3. It identifies strategic ACTIONS and USER STATES.
=============================================================================
*/

DECLARE @TableName    NVARCHAR(MAX) = 'Datawarehouse.gold.user_zscore_segmentation';
DECLARE @UserIDCol    NVARCHAR(MAX) = 'user_id';
DECLARE @SuccessCol   NVARCHAR(MAX) = 'is_success';
DECLARE @MinutesCol   NVARCHAR(MAX) = 'FLOOR(duration_seconds / 60)'; 

-- -----------------------------------------------------------------------------
-- ⚙️ ENGINE (Dynamic execution)
-- -----------------------------------------------------------------------------
DECLARE @DynamicSQL NVARCHAR(MAX);

SET @DynamicSQL = N'
WITH base AS (
    SELECT 
        ' + @UserIDCol + N' AS user_id,
        ' + @SuccessCol + N' AS is_success, 
        ' + @MinutesCol + N' AS minutes
    FROM ' + @TableName + N'
),

by_min AS (
    SELECT
        minutes,
        COUNT(user_id) AS users_cnt,
        SUM(CAST(is_success AS INT)) AS success_cnt,
        ROUND(AVG(CAST(is_success AS FLOAT)) * 100, 2) AS success_rate
    FROM base
    GROUP BY minutes 
),

by_cumm AS (
    SELECT *,
        -- Total users who lasted AT LEAST this long (Survival)
        SUM(users_cnt) OVER (ORDER BY minutes DESC) AS survival_cumm, 
        -- Total successes up to this minute
        SUM(success_cnt) OVER (ORDER BY minutes ASC) AS success_cumm,
        ROUND(AVG(success_rate) OVER(), 2) AS global_avg_success
    FROM by_min
),

calc AS (
    SELECT *,
        -- MARKOV: Survival Probability
        ROUND((CAST(LEAD(survival_cumm) OVER (ORDER BY minutes) AS FLOAT) / NULLIF(survival_cumm, 0)) * 100, 2) AS p_stay
    FROM by_cumm
),

metrics_report AS (
    SELECT 
        minutes,
        users_cnt,
        success_cnt,
        success_rate,
        global_avg_success,
        p_stay,
        
        -- TIPPING POINT: When survival momentum deviates from the population average
        ROUND(p_stay - AVG(p_stay) OVER(), 4) AS tipping_point,
        
        -- INSTABILITY: System Energy 
        ROUND(POWER(p_stay - (100.0 - global_avg_success), 2), 2) AS instability,

        -- INSTABILITY DELTA: Rate of change of stability
        ROUND(POWER(p_stay - (100.0 - global_avg_success), 2) - 
              LAG(POWER(p_stay - (100.0 - global_avg_success), 2)) OVER (ORDER BY minutes), 2) AS instability_delta,
        
        -- BEHAVIORAL MOMENTUM: Golden Minutes intersection
        ROUND(success_cnt * p_stay, 0) AS behavioral_momentum

    FROM calc
    WHERE users_cnt >= 200
),

final_analysis AS (
    SELECT 
        *,
        -- STATISTICAL Z-SCORES (Self-healing thresholds)
        ROUND((behavioral_momentum - AVG(behavioral_momentum) OVER()) / NULLIF(STDEV(behavioral_momentum) OVER(), 0), 2) AS z_momentum,
        ROUND((instability - AVG(instability) OVER()) / NULLIF(STDEV(instability) OVER(), 0), 2) AS z_instability
    FROM metrics_report
)

SELECT 
    *,
    -- ACTIONABLE PHYSICS
    CASE 
        -- ¿Estamos forzando demasiado? FORCE: High friction detected; the goal is to remove barriers.
        WHEN z_instability > 1 AND z_momentum < 0 THEN ''FORCE: Simplify the UI''
        
        -- ¿Estamos ignorando un hábito? INERTIA: Habitual movement detected; the goal is to capture value.
        WHEN z_momentum > 1 AND z_instability < 0 THEN ''INERTIA: Monetize''
        
        -- ¿Es este nuestro estado ideal? EQUILIBRIUM: Balanced growth; the goal is consistency.
        WHEN ABS(z_momentum) < 0.5 AND ABS(z_instability) < 0.5 THEN ''EQUILIBRIUM: keep doing it''
        
        -- ¿Hacia dónde caerá el usuario? TRANSITION: Uncertain behavior; the goal is to secure retention.
        ELSE ''TRANSITION: Pin user''
    END AS action,

    CASE 
        -- THE ACTION POINT: The exact minute BEFORE retention flips to negative
        WHEN tipping_point >= 0 
             AND LEAD(tipping_point) OVER(ORDER BY minutes) < 0
             AND success_rate >= LAG(success_rate) OVER(ORDER BY minutes)
        THEN ''ACTION POINT: PIVOT TO CONVERT''

        WHEN tipping_point > 0 
             AND success_rate > LAG(success_rate) OVER(ORDER BY minutes)
        THEN ''WARMING UP''

        WHEN tipping_point < 0 
             AND success_rate < LAG(success_rate) OVER(ORDER BY minutes)
        THEN ''COOLING DOWN''

        ELSE ''OBSERVE''
    END AS user_state
FROM final_analysis
ORDER BY minutes;
';

EXEC sp_executesql @DynamicSQL;
