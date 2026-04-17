-- DIM BY DATE: ROBUST CUMULATIVE & BASS ANALYSIS
-- Summary: Daily conversion, Market Share, and Diffusion Factors (p & q).
-- Market Share (F): How much of the potential we have captured_?                                                                                  │
--Efficiency (f(t)/[1-F(t)]): The rate of capture of the remaining potential?                                                                      │
--Hay viralidad?                                                                                                                                   │
--Hay esfuerzo de marketing?                                                                                                                       │
 --Estamo mejorando? Hay factor X que molesta?                                                                                                      │
 --ALTER   VIEW gold.dim_by_date AS  
WITH daily_stats AS (
    SELECT 
        date,
        COUNT(DISTINCT user_id) AS users,
        COUNT(DISTINCT CASE WHEN max_level_reached >= 2 THEN user_id END) AS reached_level_2,
        COUNT(DISTINCT CASE WHEN max_level_reached >= 3 THEN user_id END) AS reached_level_3,
        COUNT(DISTINCT CASE WHEN max_level_reached >= 4 THEN user_id END) AS reached_level_4,
        COUNT(DISTINCT CASE WHEN max_level_reached >= 5 THEN user_id END) AS reached_level_5,
        COUNT(DISTINCT CASE WHEN z_segmentation = 'outlier Extreme' THEN user_id END) AS extreme_outliers_count,
        AVG(CAST(max_level_reached AS FLOAT)) AS avg_max_level,
        AVG(duration_seconds) AS avg_duration_seconds
    FROM Datawarehouse.gold.user_zscore_segmentation
    WHERE funnel_type = 'general' 
    GROUP BY date
),

calculated_metrics AS (
    SELECT 
        date,
        users,
        reached_level_5 AS conversions,
        ROUND(CAST(reached_level_2 AS FLOAT) / NULLIF(users, 0) * 100.0, 2) AS success_rate_level_2,
        ROUND(CAST(reached_level_3 AS FLOAT) / NULLIF(users, 0) * 100.0, 2) AS success_rate_level_3,
        ROUND(CAST(reached_level_4 AS FLOAT) / NULLIF(users, 0) * 100.0, 2) AS success_rate_level_4,
        ROUND(CAST(reached_level_5 AS FLOAT) / NULLIF(users, 0) * 100.0, 2) AS conversion_rate,
        SUM(reached_level_5) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_success_users,
        avg_max_level,
        avg_duration_seconds
    FROM daily_stats
),

market_metrics AS (
	SELECT 
	    *,
        -- Market Share (F): Cumulative success vs Potential (Assume 100,000)
	    
	    
	    CAST(cumulative_success_users AS FLOAT) / 100000.0 AS market_share,
        -- Efficiency (f(t)/[1-F(t)]): Rate of capture of remaining potential
--Efficiency (f(t)/[1-F(t)]): The rate of capture of the remaining potent
	    CAST(conversions AS FLOAT) / NULLIF(100000 - (cumulative_success_users - conversions), 0) AS efficiency,
	    -- Moving averages and Polya Inertia
	    ROUND(AVG(conversion_rate) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS conversion_rate_7d_avg,
	    (SUM(conversions) OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) + 1.0) / 
	    (SUM(users) OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) + 2.0) AS polya_inertia
	FROM calculated_metrics
)

SELECT 
    date,
    users,
    conversions,
    conversion_rate,
    cumulative_success_users,
    ROUND(market_share, 4) AS market_share,
    ROUND(efficiency, 4) AS efficiency,
    
    -- 1. Q FACTOR (Imitation / Viralidad): Pendiente de la regresión
--Hay viralidad?      
    ROUND(
        (COUNT(*) OVER() * SUM(market_share * efficiency) OVER() - SUM(market_share) OVER() * SUM(efficiency) OVER()) /
        NULLIF((COUNT(*) OVER() * SUM(POWER(market_share, 2)) OVER() - POWER(SUM(market_share) OVER(), 2)), 0)
    , 4) AS q_factor_contagio,
--Hay esfuerzo de marketing?    
    -- 2. P FACTOR (Innovation / Broadcast): Intercepto
    ROUND(
        AVG(efficiency) OVER() - (
            (COUNT(*) OVER() * SUM(market_share * efficiency) OVER() - SUM(market_share) OVER() * SUM(efficiency) OVER()) /
            NULLIF((COUNT(*) OVER() * SUM(POWER(market_share, 2)) OVER() - POWER(SUM(market_share) OVER(), 2)), 0)
        ) * AVG(market_share) OVER()
    , 4) AS p_factor_broadcast,

    -- 3. INERTIA: Momentum based on Polya process
 --Estamo mejorando? Hay factor X que molesta?   
    ROUND(polya_inertia, 4) AS inertia,
    
    -- Additional stats
    ROUND(avg_max_level, 2) AS avg_max_level,
    ROUND(avg_duration_seconds, 2) AS avg_duration_seconds,
 	success_rate_level_2,
	success_rate_level_3,
	success_rate_level_4,
    conversions
FROM market_metrics
ORDER BY date DESC;
