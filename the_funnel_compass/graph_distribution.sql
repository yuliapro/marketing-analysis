-- ===========================================================================
-- DISTRIBUTION ANALYSIS FOR GRAPHING (Dynamic T-SQL)
-- ===========================================================================
--
-- HOW TO USE THIS SCRIPT:
-- ---------------------------------------------------------------------------
-- 1. KEY METRIC: Set @KeyMetric to the column name for the X-axis.
-- 2. CAP: Set @UserCap to the maximum number of users per data point.
-- 3. FILTERS: Add your conditions (use doubled-up single quotes for strings).
-- 4. TABLE: Ensure @TableName points to your data source.
-- ---------------------------------------------------------------------------

-- [USER INPUT SECTION]
DECLARE @KeyMetric  NVARCHAR(128) = 'duration_seconds'; -- X-Axis Metric
DECLARE @UserCap    INT           = 8000;               -- Y-Axis Cap (for outliers)
DECLARE @TableName  NVARCHAR(256) = 'Datawarehouse.gold.user_zscore_segmentation';

-- [FILTER CONFIGURATION] - Combined with AND logic
DECLARE @Filter1    NVARCHAR(MAX) = 'funnel_category = ''activity'''; -- Example filter
DECLARE @Filter2    NVARCHAR(MAX) = 'funnel_type = ''general''';  -- Example filter
DECLARE @Filter3    NVARCHAR(MAX) = '1=1';                        -- Default: No filter

-------------------------------------------------------------------------------
-- [CORE ENGINE] - Do not modify below this line
-------------------------------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
SELECT 
    ' + @KeyMetric + ' AS metric_value,
    CASE 
        WHEN COUNT(user_id) > @Cap THEN @Cap 
        ELSE COUNT(user_id) 
    END AS user_count
FROM ' + @TableName + '
WHERE (' + ISNULL(@Filter1, '1=1') + ')
  AND (' + ISNULL(@Filter2, '1=1') + ')
  AND (' + ISNULL(@Filter3, '1=1') + ')
GROUP BY ' + @KeyMetric + '
ORDER BY ' + @KeyMetric + ' ASC;
';

EXEC sp_executesql @SQL, N'@Cap INT', @Cap = @UserCap;
