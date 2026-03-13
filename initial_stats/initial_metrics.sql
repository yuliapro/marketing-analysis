    -- WORKING DATA TABLE SHOULD HAVE AT LEAST user_id, dimention, metric COLUMNS.
    -- CHOOSE KEY METRIC AND DIMENTION YOU WOULD LIKE TO SEE DATA 
    -- EXAMPLE Table:funnel_category, user_id, duration_seconds
    -- key_metric = duration_seconds
  	-- dimention = funnel_category
WITH base_data AS (
    -- Step 1: Calculate metrics (Mediana, STDEV, VAR..) no grouping 
    SELECT 
        funnel_category, 
        duration_seconds,
        user_id,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY duration_seconds) OVER (PARTITION BY funnel_category ) AS median_dur,
        STDEV(duration_seconds) OVER (PARTITION BY funnel_category ) AS st_dev_win,
        VAR(duration_seconds) OVER (PARTITION BY funnel_category) AS var_win,
        ROW_NUMBER() OVER (PARTITION BY funnel_category ORDER BY duration_seconds) AS row_num
    FROM Datawarehouse.gold.dim_user_id
    WHERE funnel_type='general'
),
grouped_metrics AS (
    -- Step 2: Group and calculate Gini y cubed and square differences
   SELECT 
        funnel_category,
        COUNT(user_id) AS total_users,
        AVG(CAST(duration_seconds AS FLOAT)) AS avg_dur,
        MAX(median_dur) AS median_dur,
        MAX(st_dev_win) AS st_dev,
        MAX(var_win) AS variance,
        
        ((2.0 * SUM(CAST(row_num AS BIGINT) * duration_seconds)) 
      	  / NULLIF(COUNT(*)* SUM(CAST(duration_seconds AS BIGINT)), 0)) 
         - ((COUNT(*) + 1.0)
         / NULLIF(COUNT(*), 0)) AS gini_coef,

		SUM(POWER(CAST(duration_seconds AS FLOAT),3)) AS sum_x3,
		SUM(POWER(CAST(duration_seconds AS FLOAT),2)) AS sum_x2,
		SUM(CAST(duration_seconds AS FLOAT)) AS sum_x

    FROM base_data
    GROUP BY funnel_category
)
-- Step 3: final result + Pearson, Fisher coef. and CV
SELECT TOP 10
    funnel_category,
    total_users AS count,
    ROUND(avg_dur, 2) AS avg,
    ROUND(median_dur, 2) AS median,
    ROUND(st_dev, 2) AS st_dev,
    ROUND(variance, 2) AS var,
    ROUND((3 * (avg_dur - median_dur)) / NULLIF(st_dev, 0), 2) AS dist_pearson,
    ROUND(sum_x3 / NULLIF((total_users - 1) * POWER(st_dev, 3), 0), 2) AS dist_fisher,
    ROUND(gini_coef, 2) AS gini_coef,
    ROUND(st_dev * 100.0 / NULLIF(avg_dur, 0), 2) AS CV
  -- ,ROUND(LEAD(total_users) OVER (ORDER BY max_level_reached) / NULLIF(POWER(avg_dur, 0.5), 0) * POWER(total_users, 0.5), 2) AS intelligence
FROM grouped_metrics
ORDER BY total_users DESC;
