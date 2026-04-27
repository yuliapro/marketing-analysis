/*
  Summary of Strategic Insights:
   1. Spotting "Gold Mines": When momentum_verdict is ACCELERATING, you have found a micro-segment where conversion is becoming the new norm.
   2. Efficiency in Retargeting: Users labeled as UNDER PRESSURE are your highest-ROI leads. They were in a winning environment but didn't convert; a small nudge will likely win them
      over.
   3. Detecting "Lone Wolves": Users who succeed in low-consensus areas are your "Innovators." Studying them helps you find new use cases or underserved niches.
   4. Early Warning System: If local_consensus drops below historical_inertia, the script warns you that a segment is COOLING before it impacts your monthly reports.
*/
-- -------------------------------------------------------------------------------------
-- MICRO-MOMENT DETECTOR TEMPLATE (GAME OF LIFE + POLYA)
-- -------------------------------------------------------------------------------------
-- Goal: Detect winning streaks, missing links, and historical reinforcement.
-- -------------------------------------------------------------------------------------

WITH mapping AS (
    SELECT 
        /* ---------------------------------------------------------
           STEP 1: TYPE YOUR CORE COLUMN NAMES HERE
        --------------------------------------------------------- */
        u.user_id              AS uid,           -- <--- User ID column
        u.[date]               AS time_col,      -- <--- Timestamp
        CAST(u.is_success AS FLOAT) AS is_success, -- <--- Success flag (1 or 0)
        
        /* ---------------------------------------------------------
           STEP 2: TYPE YOUR SEGMENTATION DIMENSIONS HERE
        --------------------------------------------------------- */
        u.funnel_category      AS dim_1,         
        u.experiment_name      AS dim_2,         
        u.z_segmentation       AS dim_3          
        
    FROM Datawarehouse.gold.user_success_score_table u 
   WHERE funnel_category='fasting' AND experiment_name='exp_0' AND z_segmentation='avg'
),

cellular_neighborhood AS (
    -- Step 3: Local Context (Game of Life Neighborhood)
    SELECT 
        *,
        -- Local Average (30 users)
        ROUND(AVG(is_success) OVER(
            PARTITION BY dim_1, dim_2, dim_3 
            ORDER BY time_col, uid 
            ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING
        ), 4) AS neighborhood_avg,
        
        -- LOCAL DISSONANCE: Stability of the local signal 
        --  STABILITY: How similar are users in this group? (Low stdev = high stability)     WHEN zone_stdev < 0.25 THEN 'Predictive' WHEN zone_stdev < 0.45 THEN 'Moderate'
        ROUND(STDEV(is_success) OVER(
            PARTITION BY dim_1, dim_2, dim_3 
            ORDER BY time_col, uid 
            ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING
        ), 4) AS local_dissonance,

        -- POLYA MOMENTUM: Historical reinforcement in this segment
        ROUND(
            (SUM(is_success) OVER(
                PARTITION BY dim_1, dim_2, dim_3 
                ORDER BY time_col, uid 
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) + 1.0) 
            / (ROW_NUMBER() OVER(
                PARTITION BY dim_1, dim_2, dim_3 
                ORDER BY time_col, uid) + 1.0)
        , 4) AS polya_momentum
    FROM mapping
),

pressure_layer AS (
    -- Step 4: Calculate Cellular Pressure
    SELECT 
        *,
        ROUND(neighborhood_avg - is_success, 4) AS cellular_pressure
        -- 3. DISSONANCE: How much did THIS user defy their group's norm?
        ,ABS(is_success - neighborhood_avg) / NULLIF(local_dissonance, 0) AS individual_dissonance
    FROM cellular_neighborhood
),

normalization AS (
    -- Step 5: Global Z-Scores
    SELECT 
        *,
        (neighborhood_avg - AVG(neighborhood_avg) OVER()) / NULLIF(STDEV(neighborhood_avg) OVER(), 0) AS z_consensus,
        (polya_momentum - AVG(polya_momentum) OVER()) / NULLIF(STDEV(polya_momentum) OVER(), 0) AS z_polya
    FROM pressure_layer
)

-- FINAL OUTPUT: The Full Micro-Moment Diagnostic
SELECT 
    uid AS user_id,
    time_col AS [date],
    dim_1, dim_2, dim_3,
    is_success,
    
    -- Real-time Signals
    --is there a sinning steak right now? 30 users success rate
    ROUND(neighborhood_avg, 4) AS consensus,
   -- How much did THIS user defy their group's norm?
    ROUND(individual_dissonance, 4) AS individual_dissonance,
    --norm or luck? low - uniform, high - random,
    ROUND(local_dissonance, 4) AS instability,
    --what other succeded?
    ROUND(cellular_pressure, 4) AS pressure,
    --improoving or fading trend?
    ROUND(polya_momentum, 4) AS inertia,
    
    -- Sigmoid Probabilities
    ROUND(1.0 / (1.0 + EXP(-ISNULL(z_consensus, 0))), 4) AS p_winning_streak,
    ROUND(1.0 / (1.0 + EXP(-ISNULL(z_polya, 0))), 4) AS p_momentum_trust,

    -- LYAPUNOV DELTA (dV/dt)
    ROUND(
        POWER(neighborhood_avg - polya_momentum, 2) - 
        LAG(POWER(neighborhood_avg - polya_momentum, 2)) OVER (
            PARTITION BY dim_1, dim_2, dim_3 
            ORDER BY time_col, uid
        )
    , 4) AS lyapunov_delta,

    -- SYSTEM CLASSIFICATION
    CASE 
        WHEN neighborhood_avg > polya_momentum AND neighborhood_avg > 0.6 THEN 'ACCELERATING: New High'
        WHEN neighborhood_avg < polya_momentum AND polya_momentum > 0.5 THEN 'COOLING: Fading Streak'
        WHEN cellular_pressure >= 0.7 THEN 'UNDER PRESSURE: Retarget Opportunity'
        WHEN cellular_pressure <= -0.7 THEN 'LONE WOLF: Resilient Success'
        ELSE 'STABLE'
    END AS momentum_verdict,

    -- STRATEGIC ACTION
    CASE 
        WHEN neighborhood_avg > polya_momentum AND neighborhood_avg > 0.5 THEN 'SCALE: Double budget'
        WHEN cellular_pressure >= 0.5 THEN 'RETARGET: Re-engage'
        WHEN polya_momentum < 0.15 AND neighborhood_avg < 0.15 THEN 'PIVOT: Low trust segment'
        ELSE 'OBSERVE'
    END AS action_plan,
           CASE 
            WHEN individual_dissonance < 0.8 THEN 'Follower'
            WHEN individual_dissonance > 1.2 THEN 'Outlier'
            ELSE 'Caos'
        END AS social_role

FROM normalization
ORDER BY time_col DESC;

