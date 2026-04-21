-- GROWTH SIGNALS MASTER TEMPLATE (THE "TRUSTOMETER-MAJORITY" ENGINE)
-- -------------------------------------------------------------------------------------
-- Goal: A unified framework for Success Probability, Statistical Trust, and Cluster Analysis.
-- -------------------------------------------------------------------------------------
-- INSTRUCTIONS: 
-- 1. In the 'mapping' CTE, type your actual column names and source table.
-- 2. Define your potential market size in the 'config' CTE.
-- 3. Execute to get a 360-degree view of your growth segments.
     --user_id, is_success, funnel_category, experiment_name, z_segmentation, [date], z_avg_lift_val, fun_avg_lift_val, exp_avg_lift_val, success_score, success_score_norm, success_probability, divergence  

WITH mapping AS (
    SELECT 
        /* ---------------------------------------------------------
           STEP 1: TYPE YOUR COLUMN NAMES AND SOURCE TABLE HERE
        --------------------------------------------------------- */
       'Decile ' + CAST(NTILE(10) OVER (ORDER BY duration_seconds) AS VARCHAR) AS dim,
        u.duration_seconds     AS metric,        -- <--- Key Metric (Duration, Revenue, etc.)
        u.user_id              AS uid,           -- <--- User ID column
        CAST(u.is_success AS FLOAT) AS is_success, -- <--- Success flag (1 or 0)
        u.success_score        AS raw_score      -- <--- Your Success Score column
        
    FROM Datawarehouse.gold.user_success_score u 
  --  WHERE (u.z_score BETWEEN -5 AND 5) OR u.z_score IS NULL -- <--- Optional Filter
),

cluster_base AS (
    -- Step 2: Calculate Local Majority (Consensus) and Volume
    SELECT 
        dim, uid, metric, is_success, raw_score,
        -- Consensus: The local majority behavior (0 to 1)
        AVG(is_success) OVER (PARTITION BY dim) AS cluster_consensus,
        -- Social Dissonance: High stdev means the group is divided
        STDEV(is_success) OVER (PARTITION BY dim) AS social_dissonance,
        -- Volume
        COUNT(uid) OVER (PARTITION BY dim) AS cluster_users,
        SUM(is_success) OVER (PARTITION BY dim) AS cluster_conversions,
        -- Window Metrics for Distribution
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY metric) OVER (PARTITION BY dim) AS median_metric,
        STDEV(metric) OVER (PARTITION BY dim) AS metric_stdev,
        ROW_NUMBER() OVER (PARTITION BY dim ORDER BY metric) AS row_num
    FROM mapping
),

normalization AS (
    -- Step 3: Z-Score Normalization for Global Probabilities
    SELECT 
        *,
        (raw_score - AVG(raw_score) OVER()) 
        / NULLIF(STDEV(raw_score) OVER(), 0) AS score_z_norm,
        -- Normalized consensus for absolute cluster probability
        (cluster_consensus - AVG(cluster_consensus) OVER())
        / NULLIF(STDEV(cluster_consensus) OVER(), 0) AS consensus_z_norm
    FROM cluster_base
),

probability_layer AS (
    -- Step 4: Apply Sigmoid to get Probabilities
    SELECT 
        *,
        1.0 / (1.0 + EXP(-ISNULL(score_z_norm, 0))) AS prob_individual,
        1.0 / (1.0 + EXP(-ISNULL(consensus_z_norm, 0))) AS prob_cluster_abs
    FROM normalization
),

master_metrics AS (
    -- Step 5: Aggregate everything by Segment
    SELECT 
        dim,
        MAX(cluster_users) AS users,
        MAX(cluster_conversions) AS conversions,
        AVG(is_success) AS actual_cr,
        AVG(prob_cluster_abs) AS prob_cluster,
        
        -- 1. BERNOULLI (Trust): sqrt(p*(1-p)/n)
        SQRT((AVG(prob_cluster_abs) * (1.0 - AVG(prob_cluster_abs))) / NULLIF(MAX(cluster_users), 0)) AS uncertainty_risk,
        
        -- 2. SHANNON (Entropy): Chaos level
        ROUND( - (
            (AVG(prob_cluster_abs) * LOG(NULLIF(ABS(AVG(prob_cluster_abs)), 0)) / LOG(2)) +
            ((1.0 - AVG(prob_cluster_abs)) * LOG(NULLIF(ABS(1.0 - AVG(prob_cluster_abs)), 0)) / LOG(2))
        ), 4) AS shannon_entropy,
        
        -- 3. KL DIVERGENCE (Model Fit): Error/Surprise
        AVG(
            CASE 
                WHEN is_success = 1 THEN LOG(1.0 / NULLIF(prob_individual, 0)) / LOG(2)
                WHEN is_success = 0 THEN LOG(1.0 / NULLIF(1.0 - prob_individual, 0)) / LOG(2)
                ELSE 0 
            END
        ) AS model_fit_kl,

        -- 4. GINI COEFFICIENT (Inequality in metric)
        ((2.0 * SUM(CAST(row_num AS BIGINT) * metric)) 
      	  / NULLIF(COUNT(*)* SUM(CAST(metric AS BIGINT)), 0)) 
         - ((COUNT(*) + 1.0) / NULLIF(COUNT(*), 0)) AS gini_coef,

        MAX(social_dissonance) AS social_dissonance
    FROM probability_layer
    GROUP BY dim
)

-- FINAL OUTPUT: Predictive Growth Signals
SELECT 
    dim AS segment,
    users,
    conversions,
    ROUND(actual_cr * 100, 2) AS cr_perc,
    
    -- Local Majority Signals
    ROUND(actual_cr, 4) AS consensus_strength, 
    ROUND(social_dissonance, 4) AS dissonance_index,
    
    -- Trustometer & Model Fit
    ROUND(prob_cluster, 4) AS predictive_probability,
    ROUND(uncertainty_risk, 4) AS uncertainty_risk,
    ROUND(shannon_entropy, 4) AS chaos_level,
    ROUND(model_fit_kl, 4) AS surprise_kl,
    
    -- Inequality & Growth
    ROUND(gini_coef, 4) AS behavioral_gini,
    
    -- CLUSTER HEALTH CLASSIFICATION
    CASE 
        WHEN uncertainty_risk > 0.05 OR shannon_entropy > 0.85 THEN 'Class 3: Chaotic / Unstable'
        WHEN actual_cr > 0.60 AND uncertainty_risk <= 0.02 THEN 'Class 1: Gold Predictive'
        WHEN model_fit_kl < 0.30 AND actual_cr BETWEEN 0.20 AND 0.60 THEN 'Class 4: Complex / Growth'
        ELSE 'Class 2: Periodic / Standard'
    END AS growth_signal_class

FROM master_metrics
WHERE users > 50
ORDER BY actual_cr DESC;
