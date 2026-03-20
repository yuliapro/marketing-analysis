/*
    VARIABLE DISTRIBUTION ANALYSIS (Dynamic T-SQL) - 3 FILTER VERSION
    This script calculates statistical distribution metrics for a chosen Dimension and Metric.
    
    INSTRUCTIONS:
    Set your variables once at the top. 
    Filters are combined with AND. Use '1=1' if you want to skip a filter.
*/

DECLARE @Dimension     NVARCHAR(128) = 'funnel_category';  -- Column to group by
DECLARE @Metric        NVARCHAR(128) = 'duration_seconds'; -- Metric to analyze
DECLARE @TableName     NVARCHAR(256) = 'Datawarehouse.gold.user_zscore_segmentation';

-- FILTER VARIABLES
DECLARE @Filter1       NVARCHAR(MAX) = 'funnel_category = ''activity''';
DECLARE @Filter2       NVARCHAR(MAX) = 'funnel_type = ''general''';
DECLARE @Filter3       NVARCHAR(MAX) = '1=1'; -- Add third condition here

-------------------------------------------------------------------------------
-- DYNAMIC EXECUTION ENGINE
-------------------------------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
WITH base_data AS (
    -- Step 1: Calculate metrics (Mediana, STDEV, VAR, ROW_NUM) per user
    SELECT 
        ' + @Dimension + ' AS dim_col, 
        CAST(' + @Metric + ' AS FLOAT) AS metric_col,
        user_id,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ' + @Metric + ') OVER (PARTITION BY ' + @Dimension + ') AS median_val,
        STDEV(' + @Metric + ' ) OVER (PARTITION BY ' + @Dimension + ') AS st_dev_win,
        VAR(' + @Metric + ' ) OVER (PARTITION BY ' + @Dimension + ') AS var_win,
        ROW_NUMBER() OVER (PARTITION BY ' + @Dimension + ' ORDER BY ' + @Metric + ') AS row_num
    FROM ' + @TableName + '
    -- Combining filters with AND
    WHERE (' + ISNULL(@Filter1, '1=1') + ') 
      AND (' + ISNULL(@Filter2, '1=1') + ')
      AND (' + ISNULL(@Filter3, '1=1') + ')
),
grouped_metrics AS (
    -- Step 2: Group and calculate AVG, Gini, cubed and square differences
   SELECT 
        dim_col,
        COUNT(user_id) AS total_users,
        AVG(metric_col) AS avg_val,
        MAX(median_val) AS median_val,
        MAX(st_dev_win) AS st_dev,
        MAX(var_win) AS variance,
        
        -- Gini Coefficient calculation
        ((2.0 * SUM(CAST(row_num AS BIGINT) * metric_col)) 
          / NULLIF(COUNT(*) * SUM(CAST(metric_col AS BIGINT)), 0)) 
         - ((COUNT(*) + 1.0)
         / NULLIF(COUNT(*), 0)) AS gini_coef,

        SUM(POWER(metric_col, 3)) AS sum_x3,
        SUM(POWER(metric_col, 2)) AS sum_x2,
        SUM(metric_col) AS sum_x

    FROM base_data
    GROUP BY dim_col
)
-- Step 3: Final result + Pearson, Fisher coef. and CV
SELECT TOP 10
    dim_col AS [' + @Dimension + '],
    total_users AS [count],
    ROUND(avg_val, 2) AS [avg],
    ROUND(median_val, 2) AS [median],
    ROUND(st_dev, 2) AS [st_dev],
    ROUND(variance, 2) AS [var],
    -- Pearson Skewness: (3 * (Mean - Median)) / StdDev
    ROUND((3 * (avg_val - median_val)) / NULLIF(st_dev, 0), 2) AS dist_pearson,
    -- Fisher Kurtosis (simplified): sum(x^3) / ((n-1) * s^3)
    ROUND(sum_x3 / NULLIF((total_users - 1) * POWER(st_dev, 3), 0), 2) AS dist_fisher,
    ROUND(gini_coef, 2) AS gini_coef,
    ROUND(st_dev * 100.0 / NULLIF(avg_val, 0), 2) AS CV_percent
FROM grouped_metrics
ORDER BY total_users DESC;
';

-- Execute the constructed SQL
EXEC sp_executesql @SQL;
