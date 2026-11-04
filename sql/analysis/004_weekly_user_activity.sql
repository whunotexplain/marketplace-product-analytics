--Нам нужна таблица активности пользователей по неделям, содержащая:
--- visitorid
--- activity_week — неделя, в которую пользователь совершал события.
--Условия:
--- Используй DATE_TRUNC('week', event_timestamp).
--- Одна строка на уникальную пару visitorid + activity_week.
--- Не считай количество событий — нас интересует факт активности пользователя.

SELECT DISTINCT
	visitorid,
	DATE_TRUNC('week', event_timestamp) AS activity_week
FROM staging.stg_events
ORDER BY visitorid, activity_week;