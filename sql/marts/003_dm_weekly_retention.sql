DROP MATERIALIZED VIEW IF EXISTS analytics.dm_weekly_retention;

-- Grain: one row per first-observed cohort week and elapsed calendar week.
-- Missing cohort/week combinations mean no observed activity row; they are not materialized as zero.

CREATE MATERIALIZED VIEW analytics.dm_weekly_retention AS
WITH user_cohorts AS (
    SELECT
        visitorid,
        DATE_TRUNC('week', MIN(event_timestamp)) AS cohort_week
    FROM staging.stg_events
    GROUP BY visitorid
),
weekly_activity AS (
    SELECT DISTINCT
        visitorid,
        DATE_TRUNC('week', event_timestamp) AS activity_week
    FROM staging.stg_events
),
cohort_sizes AS (
    SELECT cohort_week, COUNT(*) AS cohort_size
    FROM user_cohorts
    GROUP BY cohort_week
),
cohort_activity AS (
    SELECT
        uc.cohort_week,
        wa.activity_week,
        COUNT(DISTINCT uc.visitorid) AS active_users,
        ((wa.activity_week::DATE - uc.cohort_week::DATE) / 7) AS week_number
    FROM user_cohorts uc
    JOIN weekly_activity wa
        ON uc.visitorid = wa.visitorid
    GROUP BY uc.cohort_week, wa.activity_week
)
SELECT
    ca.cohort_week,
    ca.week_number,
    cs.cohort_size,
    ca.active_users,
    ROUND(
        ca.active_users::DECIMAL / NULLIF(cs.cohort_size, 0) * 100,
        2
    ) AS retention_rate
FROM cohort_activity ca
JOIN cohort_sizes cs
    ON ca.cohort_week = cs.cohort_week;

CREATE UNIQUE INDEX idx_dm_weekly_retention_cohort_week
    ON analytics.dm_weekly_retention (cohort_week, week_number);

COMMENT ON MATERIALIZED VIEW analytics.dm_weekly_retention IS
'Weekly cohort retention. Cohorts are based on first observed event; recent cohorts are right-censored.';
