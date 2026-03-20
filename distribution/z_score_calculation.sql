-- ===========================================================================
-- UNIVERSAL Z-SCORE, MEDIAN & COVARIANCE CALCULATOR (Dynamic T-SQL)
-- ===========================================================================
--
-- HOW TO USE THIS SCRIPT:
-- ---------------------------------------------------------------------------
-- 1. TABLE: Set @TableName to your source table.
-- 2. DIMENSIONS: Set @GroupByDimensions to columns for group comparison.
-- 3. METRIC: Set @Metric to the column you want to analyze.
-- ---------------------------------------------------------------------------

-- [USER INPUT SECTION]
DECLARE @TableName         NVARCHAR(256) = 'Datawarehouse.gold.user_statistics';
DECLARE @GroupByDimensions NVARCHAR(MAX) = 'funnel_type, funnel_category, max_level_reached';
DECLARE @Metric            NVARCHAR(128) = 'duration_seconds';

-------------------------------------------------------------------------------
-- [CORE ENGINE] - Do not modify below this line
-------------------------------------------------------------------------------
DECLARE @JoinCondition NVARCHAR(MAX) = '';
SELECT @JoinCondition = @JoinCondition + 'u.' + TRIM(value) + ' = s.' + TRIM(value) + ' AND '
FROM STRING_SPLIT(@GroupByDimensions, ',');
SET @JoinCondition = LEFT(@JoinCondition, LEN(@JoinCondition) - 4); 

DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
WITH GroupStats AS (
    -- Step 1: Calculate Mean, StDev, and Median per group
    SELECT 
        ' + @GroupByDimensions + ',
        AVG(CAST(' + @Metric + ' AS FLOAT)) AS avg_metric,
        STDEV(CAST(' + @Metric + ' AS FLOAT)) AS stdev_metric,
        -- Median calculation via PERCENTILE_CONT
        MAX(median_calc) AS median_metric
    FROM (
        SELECT 
            *,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(' + @Metric + ' AS FLOAT)) 
                OVER (PARTITION BY ' + @GroupByDimensions + ') AS median_calc
        FROM ' + @TableName + '
    ) t
    GROUP BY ' + @GroupByDimensions + '
),
ZScoreCalculation AS (
    -- Step 2: Calculate Z-Score and Coefficient of Variation
    SELECT 
        u.*,
        s.avg_metric,
        s.median_metric,
        s.stdev_metric,
        -- CV = (Standard Deviation / Mean) * 100
        ROUND((s.stdev_metric / NULLIF(s.avg_metric, 0)) * 100.0, 2) AS CV_percent,
        ROUND((CAST(u.' + @Metric + ' AS FLOAT) - s.avg_metric) / NULLIF(s.stdev_metric, 0), 2) AS z_score
    FROM ' + @TableName + ' u
    INNER JOIN GroupStats s ON ' + @JoinCondition + '
)
-- Step 3: Final Output with Segmentation
SELECT 
    *,
    CASE 
        WHEN ABS(z_score) <= 1 THEN ''avg''
        WHEN ABS(z_score) > 1 AND ABS(z_score) <= 3 THEN ''unusual''
        WHEN ABS(z_score) > 3 AND ABS(z_score) <= 5 THEN ''outlier''
        WHEN ABS(z_score) > 5 THEN ''outlier Extreme''
        ELSE ''not classified'' 
    END AS z_segmentation
FROM ZScoreCalculation;
';

EXEC sp_executesql @SQL;
