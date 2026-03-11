,calc_stats AS 
(SELECT
   user_metrics.user_id
   ,user_metrics.labor_minutes
   ,general_stats.total_users
   ,general_stats.avg_labor_minutes
   ,general_stats.user_level_max
   ,POWER(user_metrics.labor_minutes - general_stats.avg_labor_minutes, 2) AS diff_sq
   ,POWER(user_metrics.labor_minutes - general_stats.avg_labor_minutes, 3) AS diff_cb
   ,ROW_NUMBER() OVER(PARTITION BY general_stats.user_level_max ORDER BY user_metrics.labor_minutes) AS row_num
FROM user_metrics LEFT JOIN general_stats ON general_stats.user_level_max=user_metrics.user_level_max)


   ,descr_stats AS
   (SELECT
       user_level_max
       ,avg_labor_minutes
       ,total_users
       ,SUM(diff_sq)
           / total_users AS variance
       ,POWER(SUM(diff_sq)
           /(total_users-1),0.5) AS desv_est
       ,diff_cb
   FROM calc_stats
   GROUP BY user_level_max)

  
   ,median_stats AS   
   (
       SELECT
           user_level_max,
           labor_minutes AS median_labor
       FROM calc_stats
       WHERE row_num = CAST((total_users + 1) / 2 AS INT) -- Selecciona el usuario central
   )
SELECT
   descr_stats.user_level_max
   ,total_users
   ,LEAD(total_users) OVER (ORDER BY descr_stats.user_level_max ) AS lead
   ,avg_labor_minutes
   ,median_labor
   ,variance
   ,desv_est
   ,LEAD(total_users) OVER (ORDER BY descr_stats.user_level_max )
       / POWER(avg_labor_minutes,0.5)*POWER(total_users,0.5)
       AS eficiencia
   ,(3 * (avg_labor_minutes - median_labor)) / desv_est AS distr
   ,(SUM(diff_cb) OVER(PARTITION BY descr_stats.user_level_max )  / (total_users-1) * POWER(desv_est, 3)) AS dist_fisher  


FROM descr_stats LEFT JOIN median_stats ON median_stats.user_level_max =descr_stats.user_level_max


;
