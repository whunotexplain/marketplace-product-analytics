SELECT 
    EXTRACT(DOW FROM event_timestamp) AS day_of_week,

    COUNT(event_id) AS total_events,
    COUNT(DISTINCT visitorid) AS unique_users,

    COUNT(*) FILTER (WHERE event = 'view') AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart') AS add_to_carts,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases

FROM staging.stg_events

GROUP BY EXTRACT(DOW FROM event_timestamp)
ORDER BY day_of_week;