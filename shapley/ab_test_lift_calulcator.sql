/* PASO 0: Define expriments to compare */
DECLARE @Exp_A VARCHAR(50) = 'exp_5';
DECLARE @Exp_B VARCHAR(50) = 'exp_4';
DECLARE @Exp_C VARCHAR(50) = 'exp_0';

WITH base_rates AS (
   SELECT
       funnel_category,
       -- BASELINE: Usuarios que NO vieron ninguno de los dos experimentos
       AVG(CASE WHEN experiment_name NOT IN (@Exp_A, @Exp_B) OR experiment_name IS NULL
                THEN (CASE WHEN max_level_reached = 5 THEN 1.0 ELSE 0.0 END) END) * 100.0 AS cr_control,
      
       -- IMPACTO EXP A: Usuarios que vieron el primer experimento
       AVG(CASE WHEN experiment_name = @Exp_A
                THEN (CASE WHEN max_level_reached = 5 THEN 1.0 ELSE 0.0 END) END) * 100.0 AS cr_exp_a
       -- IMPACTO EXP B: Usuarios que vieron el segundo experimento
       ,AVG(CASE WHEN experiment_name = @Exp_B
                THEN (CASE WHEN max_level_reached = 5 THEN 1.0 ELSE 0.0 END) END) * 100.0 AS cr_exp_b
               
       -- IMPACTO EXP C: Usuarios que vieron el segundo experimento
       ,AVG(CASE WHEN experiment_name = @Exp_C
                THEN (CASE WHEN max_level_reached = 5 THEN 1.0 ELSE 0.0 END) END) * 100.0 AS cr_exp_c               
               
   FROM Datawarehouse.gold.user_zscore_segmentation
   GROUP BY funnel_category
)
SELECT
   funnel_category,
   ROUND(cr_control, 2) AS cr_baseline
  
   -- Métricas para Experimento A (exp_5)
 --  @Exp_A AS experiment_a,
 --  ROUND(cr_exp_a, 2) AS cr_a,
--   ROUND(cr_exp_a - cr_control, 2) AS a
 --  ,ROUND((cr_exp_a - cr_control)/cr_control,2) AS a_perc
   ,ROUND(AVG((cr_exp_a - cr_control)/cr_control)  OVER () ,2) AS a_perc_avg
  
   -- Métricas para Experimento B (exp_4)
 --  ,@Exp_B AS experiment_b,
--   ROUND(cr_exp_b, 2) AS cr_b,
--   ROUND(cr_exp_b - cr_control, 2) AS b
--	,ROUND((cr_exp_b - cr_control)/cr_control,2) AS b_perc
   ,ROUND(AVG((cr_exp_b - cr_control)/cr_control)  OVER () ,2) AS b_perc_avg
   
   -- Métricas para Experimento C (exp_0)
 --  ,@Exp_C AS experiment_c,
 --  ROUND(cr_exp_c, 2) AS cr_c,
 --  ROUND(cr_exp_c - cr_control, 2) AS c
 --  ,ROUND((cr_exp_c - cr_control)/cr_control, 2) AS c_perc
   ,ROUND(AVG((cr_exp_c - cr_control)/cr_control) OVER (), 2) AS c_perc_avg 
 
FROM base_rates
WHERE cr_control IS NOT NULL;



