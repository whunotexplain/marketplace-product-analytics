--Для каждого visitorid рассчитать:
--- total_events
--- views
--- add_to_carts
--- purchases
--- first_activity
--- last_activity
--Одна строка — один пользователь.

SELECT 
	visitorid,
	COUNT("event") AS total_events,
	COUNT(*) FILTER(WHERE event = 'view') AS views,
	COUNT(*) FILTER(WHERE event = 'addtocart') AS add_to_carts,
	COUNT(*) FILTER(WHERE event = 'transaction') AS purchases,
	MIN(event_timestamp) AS first_activity,
	MAX(event_timestamp) AS last_activity
FROM staging.stg_events 
GROUP BY staging.stg_events.visitorid;