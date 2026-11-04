WITH cte AS (
    SELECT
        visitorid,
        COUNT(*) AS total_events,

        COUNT(*) FILTER (WHERE event = 'view') AS views,
        COUNT(*) FILTER (WHERE event = 'addtocart') AS add_to_carts,
        COUNT(*) FILTER (WHERE event = 'transaction') AS purchases,

        MIN(event_timestamp) AS first_activity,
        MAX(event_timestamp) AS last_activity

    FROM staging.stg_events
    GROUP BY visitorid
),

segmented_users AS (
    SELECT
        visitorid,
        total_events,

        CASE
            WHEN total_events = 1 THEN 'Low Activity'
            WHEN total_events BETWEEN 2 AND 3 THEN 'Medium Activity'
            WHEN total_events >= 4 THEN 'High Activity'
        END AS activity_segment

    FROM cte
)

SELECT
    activity_segment,
    COUNT(*) AS users_count,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS users_percentage

FROM segmented_users
GROUP BY activity_segment
ORDER BY
    CASE activity_segment
        WHEN 'Low Activity' THEN 1
        WHEN 'Medium Activity' THEN 2
        WHEN 'High Activity' THEN 3
    END;