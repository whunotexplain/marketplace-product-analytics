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
)




-- Calculate the number of full weeks since the user's acquisition cohort.
-- Week 0 represents the user's initial cohort week.

SELECT
    cohort_week,
    activity_week,
	COUNT(DISTINCT uc.visitorid) AS active_users,
	((wa.activity_week::date - uc.cohort_week::date) / 7) AS week_number
FROM user_cohorts uc
JOIN weekly_activity wa
    ON uc.visitorid = wa.visitorid
GROUP BY cohort_week, activity_week, week_number
ORDER BY cohort_week, week_number;

--Что тебе осталось реализовать
--1. Добавить cohort_week и activity_week в SELECT.
--2. Рассчитать week_number — разницу между неделей активности и неделей когорты.
--3. Посчитать active_users через COUNT(DISTINCT uc.visitorid).
--4. Сгруппировать результат по cohort_week, activity_week и week_number.
--5. Отсортировать по cohort_week и week_number.
--Подсказка для PostgreSQL: поскольку обе даты уже округлены до начала недели, разницу можно получить так: