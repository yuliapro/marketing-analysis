-- MICRO MOMENT DETECTOR v2 + LYAPUNOV STABILITY ANALYSIS
-- Optimized version: Local Context (Cellular) + Historical Reinforcement (Polya) + Stability (Lyapunov).
/* Summary of Strategic Insights:
   1. Spotting "Gold Mines": When momentum_verdict is ACCELERATING, you have found a micro-segment where conversion is becoming the new norm.
   2. Efficiency in Retargeting: Users labeled as UNDER PRESSURE are your highest-ROI leads. They were in a winning environment but didn't convert; a small nudge will likely win them
      over.
   3. Detecting "Lone Wolves": Users who succeed in low-consensus areas are your "Innovators." Studying them helps you find new use cases or underserved niches.
   4. Early Warning System: If local_consensus drops below historical_inertia, the script warns you that a segment is COOLING before it impacts your monthly reports.
*/

WITH cluster_base AS (
    SELECT 
        user_id,
        [date],
        is_success, 
        funnel_category, 
        duration_seconds, 
        experiment_name, 
        z_segmentation,
        
        -- 1. LOCAL CONSENSUS (Immediate Neighborhood - 30 users)
        ROUND(AVG(CAST(is_success AS FLOAT)) OVER(
            PARTITION BY funnel_category, experiment_name, z_segmentation 
            ORDER BY [date], user_id 
            ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING
        ), 4) AS consensus_local,
        
        -- 2. CELLULAR PRESSURE (Local Average - Individual Result)
        ROUND(
            AVG(CAST(is_success AS FLOAT)) OVER(
                PARTITION BY funnel_category, experiment_name, z_segmentation 
                ORDER BY [date], user_id 
                ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING
            ) - CAST(is_success AS FLOAT)
        , 4) AS cellular_pressure,

        -- 3. POLYA MOMENTUM (Historical Reinforcement)
        ROUND(
            (SUM(CAST(is_success AS FLOAT)) OVER(
                PARTITION BY funnel_category, experiment_name, z_segmentation 
                ORDER BY [date], user_id 
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) + 1.0) 
            / (ROW_NUMBER() OVER(
                PARTITION BY funnel_category, experiment_name, z_segmentation 
                ORDER BY [date], user_id) + 1.0)
        , 4) AS polya_rate
        
    FROM Datawarehouse.gold.user_success_score_table
   WHERE funnel_category='fasting' AND experiment_name='exp_0' AND z_segmentation='avg'
),

normalization AS ( 
    SELECT 
        *,
        -- Z-Scores for the local consensus and historical momentum
        ROUND((consensus_local - AVG(consensus_local) OVER()) / NULLIF(STDEV(consensus_local) OVER(), 0), 4) AS z_consensus,
        ROUND((polya_rate - AVG(polya_rate) OVER()) / NULLIF(STDEV(polya_rate) OVER(), 0), 4) AS z_polya 
    FROM cluster_base
),

lyapunov_calc AS (
    SELECT 
        *,
        -- Sigmoid Probabilities
        ROUND(1.0 / (1.0 + EXP(-ISNULL(z_consensus, 0))), 4) AS prob_consensus,
        ROUND(1.0 / (1.0 + EXP(-ISNULL(z_polya, 0))), 4) AS prob_momentum,
        
        -- LYAPUNOV ENERGY V(t) = (Current - History)^2
        POWER(consensus_local - polya_rate, 2) AS lyapunov_energy,
        
        -- LYAPUNOV DELTA (dV/dt)
        POWER(consensus_local - polya_rate, 2) - 
        LAG(POWER(consensus_local - polya_rate, 2)) OVER (
            PARTITION BY funnel_category, experiment_name, z_segmentation 
            ORDER BY [date], user_id
        ) AS lyapunov_delta
    FROM normalization
)

SELECT 
    *,
    -- ADVANCED SYSTEM CLASSIFICATION (Momentum + Stability)
    CASE 
        WHEN lyapunov_delta > 0 AND consensus_local > polya_rate THEN 'BIFURCATION: Positive Micro-moment'
        WHEN lyapunov_delta > 0 AND consensus_local < polya_rate THEN 'TURBULENT: Negative Slip'
        WHEN lyapunov_delta < 0 THEN 'CONVERGENT: Stable Trend'
        ELSE 'STATIONARY'
    END AS stability_status,

    -- STRATEGIC ACTION
    CASE 
        WHEN lyapunov_delta > 0.2 AND consensus_local > 0.5 THEN 'ACT NOW: High Energy Peak'
        WHEN lyapunov_delta < -0.2 THEN 'COOL DOWN: Stability returning'
        ELSE 'OBSERVE'
    END AS lyapunov_action

FROM lyapunov_calc;
