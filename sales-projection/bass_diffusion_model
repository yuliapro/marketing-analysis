/*
    BASS DIFFUSION MODEL: UNIVERSAL ADAPTOR (ROBUST VERSION)
    This version includes protection against Floating Point errors (LOG/Division by zero).
*/

-- 1. CONFIGURATION: Define your Table and Column names here
DECLARE @TableName            NVARCHAR(255) = 'Datawarehouse.gold.dim_by_date_no_outliers';
DECLARE @Col_Date             NVARCHAR(255) = 'date';
DECLARE @Col_ConvRate         NVARCHAR(255) = 'conversion_rate';
DECLARE @Col_DailyReach       NVARCHAR(255) = 'users';
DECLARE @Col_TotalAccumulated NVARCHAR(255) = 'cumulative_success_users';

-- 2. PARAMETERS: Define your Target Market
DECLARE @TargetPopulation     FLOAT = 1000000.0; -- M: Total reachable market
DECLARE @SaturationThreshold  FLOAT = 0.95;      -- 95% saturation target

-------------------------------------------------------------------------------
-- DYNAMIC EXECUTION ENGINE
-------------------------------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
WITH model_data AS (
    SELECT 
        ' + @Col_Date + ' AS date_col,
        -- Protect against NULLs and ensure values are FLOAT
        CAST(ISNULL(' + @Col_ConvRate + ', 0) AS FLOAT) AS rate,
        CAST(ISNULL(' + @Col_DailyReach + ', 0) AS FLOAT) AS reach,
        CAST(ISNULL(' + @Col_TotalAccumulated + ', 0) AS FLOAT) AS cum_success,
        @M AS M
    FROM ' + @TableName + '
    WHERE ' + @Col_TotalAccumulated + ' < @M -- Exclude data where market is already full
),
metrics AS (
    SELECT 
        date_col,
        cum_success / NULLIF(M, 0) AS F_t,                          -- Market Share
        ((rate * reach) / 100.0) / NULLIF(M - cum_success, 0) AS f_t_adj -- Prob. of adoption
    FROM model_data
),
regression_raw AS (
    SELECT 
        COUNT(*) AS n,
        SUM(F_t) AS sum_x,
        SUM(f_t_adj) AS sum_y,
        SUM(F_t * f_t_adj) AS sum_xy,
        SUM(POWER(F_t, 2)) AS sum_xx,
        AVG(f_t_adj) AS avg_y,
        AVG(F_t) AS avg_x
    FROM metrics
    WHERE f_t_adj IS NOT NULL
),
factors AS (
    SELECT 
        n AS observed_days,
        -- Calculate q (Slope)
        (n * sum_xy - sum_x * sum_y) / NULLIF((n * sum_xx - POWER(sum_x, 2)), 0) AS raw_q,
        -- Calculate p (Intercept)
        avg_y - (( (n * sum_xy - sum_x * sum_y) / NULLIF((n * sum_xx - POWER(sum_x, 2)), 0) ) * avg_x) AS raw_p
    FROM regression_raw
),
final_model AS (
    SELECT 
        observed_days,
        -- Force factors to be slightly positive to avoid LOG(0) or negative errors
        CASE WHEN raw_p <= 0 THEN 0.000001 ELSE raw_p END AS p,
        CASE WHEN raw_q < 0 THEN 0.000001 ELSE raw_q END AS q
    FROM factors
)
SELECT 
    observed_days,
    ROUND(p, 6) AS p_factor_innovation,
    ROUND(q, 6) AS q_factor_imitation,
    
    -- Analytical Saturation Prediction (Days from Start)
    -- Added guard: only calculate LOG if the argument is positive
    CASE 
        WHEN (1 + @S * (q / p)) > 0 AND (p + q) > 0 THEN
            ROUND(-LOG((1 - @S) / (1 + @S * (q / p))) / (p + q), 0)
        ELSE NULL 
    END AS estimated_saturation_day_95pct,
    
    @M AS target_market_size
FROM final_model;
';

EXEC sp_executesql @SQL, 
     N'@M FLOAT, @S FLOAT', 
     @M = @TargetPopulation, 
     @S = @SaturationThreshold;
