--Твоя задача

--Напиши SQL-запрос, который для каждого visitorid определит:
--1. visitorid — идентификатор пользователя.
--2. first_event_timestamp — время его первого события.
--3. cohort_week — неделя первого события.
--Используй:
-- - MIN(event_timestamp)
-- - GROUP BY visitorid
-- - DATE_TRUNC('week', ...)

SELECT 
	visitorid,
	MIN(event_timestamp) AS first_event_timestamp,
	DATE_TRUNC(
		'week',
		MIN(event_timestamp)
	) AS cohort_week
FROM staging.stg_events
GROUP BY visitorid;


--Твоя задача:
--
--На основе предыдущей логики напиши SQL-запрос, который вернёт:
--- cohort_week
--- cohort_size — количество уникальных пользователей в когорте.
--Условия:
--1. Сначала определи неделю первого события каждого пользователя.
--2. Затем посчитай количество пользователей в каждой неделе.
--3. Отсортируй результат по cohort_week.

WITH last_cohort_analys AS (
	SELECT
		visitorid,
		MIN(event_timestamp) AS first_event_timestamp,
		DATE_TRUNC(
			'week',
			MIN(event_timestamp)
		) AS cohort_week
	FROM staging.stg_events
	GROUP BY visitorid
)

SELECT 
	cohort_week,
	COUNT(visitorid) AS users_in_cohort
FROM last_cohort_analys
GROUP BY cohort_week 
ORDER BY cohort_week;

