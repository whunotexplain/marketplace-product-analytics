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
    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY total_events) AS p50,

    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY total_events) AS p75,

    PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY total_events) AS p90,

    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY total_events) AS p95,

    PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY total_events) AS p99

FROM cte;