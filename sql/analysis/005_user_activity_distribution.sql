--Твоя задача — на основе предыдущего запроса получить:
--- total_users;
--- AVG(total_events);
--- MIN(total_events);
--- MAX(total_events);
--- PERCENTILE_CONT(0.5) — медиану количества событий.
--Используй CTE с предыдущей пользовательской агрегацией, а затем агрегируй уже полученную таблицу.
WITH cte AS (
	SELECT 
		visitorid,
		COUNT("event") AS total_events,
		COUNT(*) FILTER(WHERE event = 'view') AS views,
		COUNT(*) FILTER(WHERE event = 'addtocart') AS add_to_carts,
		COUNT(*) FILTER(WHERE event = 'transaction') AS purchases,
		MIN(event_timestamp) AS first_activity,
		MAX(event_timestamp) AS last_activity
	FROM staging.stg_events 
	GROUP BY staging.stg_events.visitorid
)

SELECT 
	COUNT(visitorid) AS total_users,
	AVG(total_events),
	MIN(total_events),
	MAX(total_events),
	PERCENTILE_CONT(0.5)
		WITHIN GROUP (ORDER BY total_events)
FROM cte;