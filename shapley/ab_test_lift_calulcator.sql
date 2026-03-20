-- ===========================================================================
-- UNIVERSAL A/B TESTING & LIFT CALCULATOR (Dynamic T-SQL)
-- ===========================================================================
--
-- HOW TO USE THIS SCRIPT:
-- ---------------------------------------------------------------------------
-- 1. TABLE: Set @TableName to your source table.
-- 2. DIMENSIONS: Set @GroupByDimensions to the columns for segments.
-- 3. EXP COLUMN: Set @ExperimentColumn to the column identifying the test group.
-- 4. INCLUSION: Set @ExperimentsToInclude to 'exp_1, exp_4' or 'ALL'.
-- 5. EXCLUSION / CUSTOM: Set @CustomFilter for logic like 'experiment_name <> ''exp_6'''.
-- 6. TOTAL USERS: Set @TotalUsersCol to the column for reach (or '1' for raw count).
-- 7. CONVERSIONS: Set @ConvertedUsersCol to the column for success.
-- 8. BASELINE: Set @BaselineValue to the value representing the control.
-- ---------------------------------------------------------------------------

-- [USER INPUT SECTION]
DECLARE @TableName             NVARCHAR(256) = 'Datawarehouse.gold.user_zscore_segmentation';
DECLARE @GroupByDimensions     NVARCHAR(MAX) = 'z_segmentation'; 
DECLARE @ExperimentColumn      NVARCHAR(128) = 'experiment_name';
DECLARE @ExperimentsToInclude  NVARCHAR(MAX) = 'ALL'; 
DECLARE @CustomFilter          NVARCHAR(MAX) = 'experiment_name <> ''exp_6'''; 
DECLARE @TotalUsersCol         NVARCHAR(128) = '1'; 
DECLARE @ConvertedUsersCol     NVARCHAR(128) = 'CASE WHEN max_level_reached = 5 THEN 1 ELSE 0 END'; 
DECLARE @BaselineValue         NVARCHAR(128) = 'NULL'; 

-------------------------------------------------------------------------------
-- [CORE ENGINE] - Do not modify below this line
-------------------------------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX);
DECLARE @FinalGroupBy NVARCHAR(MAX) = @ExperimentColumn;
DECLARE @JoinCondition NVARCHAR(MAX) = '1=1';
DECLARE @AliasedDimensions NVARCHAR(MAX) = '';

-- Handle grouping logic
IF ISNULL(@GroupByDimensions, '') <> ''
BEGIN
    SET @FinalGroupBy = @GroupByDimensions + ', ' + @ExperimentColumn;
    SELECT @JoinCondition = '';
    SELECT @AliasedDimensions = '';
    SELECT 
        @JoinCondition = @JoinCondition + 'v.[' + TRIM(value) + '] = b.[' + TRIM(value) + '] AND ',
        @AliasedDimensions = @AliasedDimensions + 'v.[' + TRIM(value) + '], '
    FROM STRING_SPLIT(@GroupByDimensions, ',');
    SET @JoinCondition = LEFT(@JoinCondition, LEN(@JoinCondition) - 4);
END

-- Handle experiment inclusion filter
DECLARE @ExpInclusionFilter NVARCHAR(MAX) = '1=1';
IF @ExperimentsToInclude <> 'ALL'
BEGIN
    SET @ExpInclusionFilter = @ExperimentColumn + ' IN (SELECT TRIM(value) FROM STRING_SPLIT(''' + @ExperimentsToInclude + ''', '',''))';
END

-- Build the Baseline string logic
DECLARE @IsBaselineSQL NVARCHAR(MAX);
SET @IsBaselineSQL = CASE WHEN @BaselineValue = 'NULL' 
                          THEN @ExperimentColumn + ' IS NULL' 
                          ELSE @ExperimentColumn + ' = ''' + @BaselineValue + '''' 
                     END;

SET @SQL = N'
WITH raw_stats AS (
    SELECT 
        ' + CASE WHEN @GroupByDimensions = '' THEN '' ELSE @GroupByDimensions + ',' END + '
        ' + @ExperimentColumn + ' AS exp_variant,
        SUM(CAST(' + @TotalUsersCol + ' AS FLOAT)) AS reach,
        SUM(CAST(' + @ConvertedUsersCol + ' AS FLOAT)) AS conversions
    FROM ' + @TableName + '
    WHERE (
        (' + ISNULL(@CustomFilter, '1=1') + ')
        AND (' + @ExpInclusionFilter + ')
    )
    OR ' + @IsBaselineSQL + '
    GROUP BY ' + @FinalGroupBy + '
),
cr_calculation AS (
    SELECT 
        *,
        (conversions / NULLIF(reach, 0)) * 100.0 AS conversion_rate
    FROM raw_stats
),
baseline_stats AS (
    SELECT 
        ' + CASE WHEN @GroupByDimensions = '' THEN '' ELSE @GroupByDimensions + ',' END + '
        conversion_rate AS cr_baseline,
        reach AS reach_baseline
    FROM cr_calculation
    WHERE exp_variant ' + CASE WHEN @BaselineValue = 'NULL' THEN 'IS NULL' ELSE '= ''' + @BaselineValue + '''' END + '
),
variant_stats AS (
    SELECT 
        ' + CASE WHEN @GroupByDimensions = '' THEN '' ELSE @GroupByDimensions + ',' END + '
        exp_variant,
        conversion_rate AS cr_variant,
        reach AS reach_variant
    FROM cr_calculation
    WHERE exp_variant ' + CASE WHEN @BaselineValue = 'NULL' THEN 'IS NOT NULL' ELSE '<> ''' + @BaselineValue + '''' END + '
)
SELECT 
    v.exp_variant,
    ' + @AliasedDimensions + '
    CAST(v.reach_variant AS INT) AS users_variant,
    CAST(b.reach_baseline AS INT) AS users_baseline,
    ROUND(v.cr_variant, 2) AS cr_variant_perc,
    ROUND(b.cr_baseline, 2) AS cr_baseline_perc,
    ROUND(v.cr_variant - b.cr_baseline, 2) AS absolute_lift,
    ROUND(((v.cr_variant - b.cr_baseline) / NULLIF(b.cr_baseline, 0)) * 100.0, 2) AS relative_lift_perc
FROM variant_stats v
INNER JOIN baseline_stats b ON ' + @JoinCondition + '
ORDER BY ' + CASE WHEN @GroupByDimensions = '' THEN 'absolute_lift' ELSE @GroupByDimensions END + ' DESC;
';

EXEC sp_executesql @SQL;
