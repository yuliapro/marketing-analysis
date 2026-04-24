-- MAJORITY CONSENSUS CHUNK ANALYSIS + POLYA MOMENTUM
-- Optimized version: Local Context (Cellular) + Historical Reinforcement (Polya).
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

        -- 4. LOCAL DISSONANCE (Signal Stability)
        ROUND(STDEV(CAST(is_success AS FLOAT)) OVER(
            PARTITION BY funnel_category, experiment_name, z_segmentation 
            ORDER BY [date], user_id 
            ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING
        ), 4) AS dissonance_local,

        -- 5. POLYA MOMENTUM (Historical Reinforcement in this cluster)
        -- Cumulative successes / Cumulative users (Laplace smoothed)
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
)

SELECT 
    *,
    -- Sigmoid Probabilities
    ROUND(1.0 / (1.0 + EXP(-ISNULL(z_consensus, 0))), 4) AS prob_consensus,
    ROUND(1.0 / (1.0 + EXP(-ISNULL(z_polya, 0))), 4) AS prob_momentum,
    
    -- ADVANCED SYSTEM CLASSIFICATION
    CASE 
        WHEN consensus_local > polya_rate AND consensus_local > 0.5 THEN 'Under Pressure (Potential Retarget)'
        WHEN consensus_local < polya_rate AND polya_rate > 0.5 THEN 'COOLING DOWN: Momentum is fading'
        WHEN cellular_pressure >= 0.7 THEN 'Winner Flow (Scale)'
        WHEN cellular_pressure <= -0.7 THEN 'Lone Wolf (Investigate Success)'
        ELSE 'STABLE'
    END AS momentum_status,

    -- STRATEGIC ACTION
        CASE 
	      --'Under Pressure (Potential Retarget)'  
	      WHEN cellular_pressure >= 0.5 THEN 'RETARGET: High social proof available' 
	      --'Lone Wolf (Investigate Success)'   
	      WHEN cellular_pressure <= -0.5 THEN 'INVESTIGATE: Anomalous resilience'                                                                                                
          WHEN cellular_pressure BETWEEN -0.49 AND 0.49 AND consensus_local > 0.5 THEN 'SCALE: Stable success zone'    
        ELSE 'OBSERVE'
	END AS momentum_action

FROM normalization;
