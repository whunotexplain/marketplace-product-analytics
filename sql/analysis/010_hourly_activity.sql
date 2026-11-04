SELECT 
    EXTRACT(HOUR FROM event_timestamp) AS hour_of_day,
    COUNT(event_id) AS total_events,
    COUNT(DISTINCT visitorid) AS unique_users,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases
FROM staging.stg_events
GROUP BY EXTRACT(HOUR FROM event_timestamp)
ORDER BY hour_of_day;