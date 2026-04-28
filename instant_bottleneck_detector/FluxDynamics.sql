-- MARKOV FUNNEL INERTIA TEMPLATE
-- Goal: Analyze transition momentum (Success vs Drop) using any transition-based dataset.
-- -------------------------------------------------------------------------------------

WITH mapping AS (
    SELECT 
        /* ---------------------------------------------------------
           STEP 1: TYPE YOUR CORE COLUMN NAMES HERE
        --------------------------------------------------------- */
        user_id         AS uid,         -- <--- User Identifier
        funnel_level_num      AS state_start, -- <--- Current level/state
        COALESCE(LEAD(funnel_level_num) OVER(PARTITION BY user_id ORDER BY step_started_at ASC), 0)        AS state_end,   -- <--- Next level/state (use 0 for drop)
        step_started_at     AS time_col     -- <--- Timestamp of transition
        
    FROM Datawarehouse.gold.user_funnel -- <--- YOUR TABLE NAME HERE
),

success_logic AS (
    -- Step 2: Define Success (Standard: Moving forward/up in states)
    SELECT 
        *,
        CASE WHEN state_end > state_start THEN 1.0 ELSE 0.0 END AS is_success
    FROM mapping
    WHERE state_start IS NOT NULL
),

neighborhood_calculations AS (
    -- Step 3: Collective Consensus & Historical Inertia
    SELECT 
        *,
        -- Local Consensus: Rolling average of 500 neighbors at this specific step
        ROUND(AVG(is_success) OVER(
            PARTITION BY state_start 
            ORDER BY time_col 
            ROWS BETWEEN 250 PRECEDING AND 250 FOLLOWING
        ), 4) AS level_consensus,

        -- Historical Inertia: Polya reinforcement (Historical memory of this step)
        ROUND(
            (SUM(is_success) OVER(
                PARTITION BY state_start 
                ORDER BY time_col 
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) + 1.0) 
            / (ROW_NUMBER() OVER(
                PARTITION BY state_start 
                ORDER BY time_col) + 1.0)
        , 4) AS level_inertia
    FROM success_logic
),

markov_metrics AS (
    -- Step 4: Stability & Friction Diagnostics
    SELECT 
        *,
        ROUND(level_consensus - level_inertia, 4) AS divergence,
        ROUND(1.0 - level_consensus, 4) AS difficulty
    FROM neighborhood_calculations
)

-- FINAL OUTPUT: Integrated Transition Intelligence
SELECT 
    uid AS user_id,
    time_col AS [date],
    CAST(state_start AS VARCHAR) + '->' + CAST(state_end AS VARCHAR) AS transition_path,
    state_start,
    state_end,
    is_success,
    
    -- Momentum Metrics
    level_consensus AS consensus, -- Collective behavior at this step
    level_inertia AS inertia,     -- Historical "memory" of this step
    divergence,                   -- Pos = Heating up, Neg = Cooling down
    difficulty,                   -- Real-time resistance
    
    -- SYSTEM CLASSIFICATION
    CASE 
        WHEN level_consensus > level_inertia AND level_consensus > 0.7 THEN 'HIGH FLOW: Optimized'
        WHEN level_consensus < level_inertia AND level_inertia > 0.5 THEN 'CLOGGED: Drop-off Zone'
        WHEN ABS(divergence) < 0.05 THEN 'STABLE: Predictable'
        ELSE 'TURBULENT: Erratic'
    END AS status_verdict,

    -- STRATEGIC ACTION
    CASE 
        WHEN divergence > 0.1 THEN 'SCALE: Efficiency increasing'
        WHEN divergence < -0.1 THEN 'FIX: Efficiency dropping'
        WHEN difficulty > 0.6 THEN 'RE-DESIGN: High friction bottleneck'
        ELSE 'OBSERVE'
    END AS action_plan

FROM markov_metrics
ORDER BY time_col DESC;
