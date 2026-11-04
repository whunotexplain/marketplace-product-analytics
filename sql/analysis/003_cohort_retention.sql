WITH user_cohorts AS (
    -- Определяем неделю первого появления каждого пользователя
    SELECT
        visitorid,
        DATE_TRUNC('week', MIN(event_timestamp)) AS cohort_week
    FROM staging.stg_events
    GROUP BY visitorid
),

weekly_activity AS (
    -- Определяем недели, в которые каждый пользователь был активен
    SELECT DISTINCT
        visitorid,
        DATE_TRUNC('week', event_timestamp) AS activity_week
    FROM staging.stg_events
),

cohort_sizes AS (
    -- Рассчитываем исходный размер каждой когорты
    SELECT
        cohort_week,
        COUNT(*) AS cohort_size
    FROM user_cohorts
    GROUP BY cohort_week
),

cohort_activity AS (
    -- Считаем активных пользователей каждой когорты по неделям
    SELECT
        uc.cohort_week,
        wa.activity_week,
        COUNT(DISTINCT uc.visitorid) AS active_users,
        (
            wa.activity_week::DATE - uc.cohort_week::DATE
        ) / 7 AS week_number
    FROM user_cohorts uc
    JOIN weekly_activity wa
        ON uc.visitorid = wa.visitorid
    GROUP BY
        uc.cohort_week,
        wa.activity_week
)

-- Рассчитываем Retention Rate
SELECT
    ca.cohort_week,
    ca.week_number,
    ca.active_users,
    cs.cohort_size,
    ROUND(
        ca.active_users::DECIMAL
        / NULLIF(cs.cohort_size, 0) * 100,
        2
    ) AS retention_rate
FROM cohort_activity ca
JOIN cohort_sizes cs
    ON ca.cohort_week = cs.cohort_week
ORDER BY
    ca.cohort_week,
    ca.week_number;