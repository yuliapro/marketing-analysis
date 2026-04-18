-- GROWTH & DIFFUSION MOMENTUM TEMPLATE (BASS & POLYA) + VaR RISK
-- INSTRUCTIONS: 
-- Type your actual column names and source table in the 'mapping' CTE below.
-- The rest of the script (Bass Factors, Polya Inertia, Market Share, VaR) will update automatically.

WITH mapping AS (
    SELECT 
        /* ---------------------------------------------------------
           STEP 1: TYPE YOUR COLUMN NAMES AND SOURCE TABLE HERE
        --------------------------------------------------------- */
        u.date                 AS date_col,      -- <--- Date column
        u.user_id              AS uid,           -- <--- User ID column (for unique counts)
        CAST(u.is_success AS FLOAT) AS is_success -- <--- Success flag (1 or 0)
        
    FROM Datawarehouse.gold.user_zscore_segmentation u -- <--- Your Source Table
    WHERE (u.z_score BETWEEN -5 AND 5) OR u.z_score IS NULL -- <--- Your Filter
),

config AS (
    SELECT 
        /* ---------------------------------------------------------
           STEP 2: DEFINE YOUR MARKET SIZE
        --------------------------------------------------------- */
        100000 AS market_potential_size -- <--- Total potential users for the model
    FROM (SELECT 1 as dummy) d
),

daily_stats AS (
    -- Step 3: Daily aggregation
    SELECT 
        date_col,
        COUNT(DISTINCT uid) AS users,
        SUM(is_success) AS conversions,
        CAST(SUM(is_success) AS FLOAT) / NULLIF(COUNT(DISTINCT uid), 0) AS daily_cr
    FROM mapping
    GROUP BY date_col
),

calculated_metrics AS (
    -- Step 4: Cumulative, Market Share and Risk Window
    SELECT 
        *,
        SUM(conversions) OVER (ORDER BY date_col ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_conversions,
        -- Market Share (F)
        CAST(SUM(conversions) OVER (ORDER BY date_col ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS FLOAT) 
            / (SELECT market_potential_size FROM config) AS market_share,
        -- Efficiency (f(t)/[1-F(t)])
        CAST(conversions AS FLOAT) 
            / NULLIF((SELECT market_potential_size FROM config) - (SUM(conversions) OVER (ORDER BY date_col ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) - conversions), 0) AS efficiency,
        
        -- Statistical windows for VaR
        AVG(daily_cr) OVER (ORDER BY date_col ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS mu_cr,
        STDEV(daily_cr) OVER (ORDER BY date_col ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS sigma_cr
    FROM daily_stats
),

diffusion_factors AS (
    -- Step 5: Bass Model Regression (Global p & q)
    SELECT 
        *,
        -- Q FACTOR (Imitation / Viral)
        (COUNT(*) OVER() * SUM(market_share * efficiency) OVER() - SUM(market_share) OVER() * SUM(efficiency) OVER()) /
        NULLIF((COUNT(*) OVER() * SUM(POWER(market_share, 2)) OVER() - POWER(SUM(market_share) OVER(), 2)), 0) AS q_viral,
        -- P FACTOR (Innovation / Broadcast)
        AVG(efficiency) OVER() - (
            (COUNT(*) OVER() * SUM(market_share * efficiency) OVER() - SUM(market_share) OVER() * SUM(efficiency) OVER()) /
            NULLIF((COUNT(*) OVER() * SUM(POWER(market_share, 2)) OVER() - POWER(SUM(market_share) OVER(), 2)), 0)
        ) * AVG(market_share) OVER() AS p_broadcast
    FROM calculated_metrics
)

-- FINAL REPORT: Growth Dynamics & Risk Analysis
SELECT 
    date_col AS date,
    users,
    conversions,
    ROUND(daily_cr * 100, 2) AS cr_perc,
    
    -- VALUE AT RISK (VaR): Minimum expected conversions at 95% confidence
    ROUND(users * (mu_cr - (1.645 * sigma_cr)), 2) AS var_conversions_95,
    
    cumulative_conversions,
    ROUND(market_share, 4) AS market_share,
    ROUND(efficiency, 4) AS capture_efficiency,
    
    -- Structural Dynamics
    ROUND(q_viral, 4) AS q_viral_factor,
    ROUND(p_broadcast, 4) AS p_broadcast_factor,
    
    -- Momentum (Polya Inertia 7d)
    ROUND((SUM(conversions) OVER (ORDER BY date_col ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) + 1.0) / 
          (SUM(users) OVER (ORDER BY date_col ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) + 2.0), 4) AS polya_inertia,

    -- System Health (Entropy of conversion)
    ROUND( - (
        (daily_cr * (LOG(NULLIF(daily_cr, 0)) / LOG(2))) 
        + 
        ((1 - daily_cr) * (LOG(NULLIF(1 - daily_cr, 0)) / LOG(2)))
    ), 4) AS shannon_entropy

FROM diffusion_factors
ORDER BY date DESC;
