--Тебе достаточно немного расширить её:
--1. В segmented_users добавь views, add_to_carts, purchases.
--2. Оставь существующий CASE WHEN без изменений.
--3. В финальном SELECT сгруппируй пользователей по activity_segment.
--4. Рассчитай средние показатели и долю покупателей.

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
        views,
        add_to_carts,
        purchases,
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
    COUNT(*) AS total_users,

    ROUND(AVG(views)::numeric, 2) AS avg_views,
    ROUND(AVG(add_to_carts)::numeric, 2) AS avg_add_to_carts,
    ROUND(AVG(purchases)::numeric, 2) AS avg_purchases,

    COUNT(*) FILTER (WHERE purchases > 0) AS purchase_users,

    ROUND(
        COUNT(*) FILTER (WHERE purchases > 0) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS purchase_rate

FROM segmented_users
GROUP BY activity_segment
ORDER BY
    CASE activity_segment
        WHEN 'Low Activity' THEN 1
        WHEN 'Medium Activity' THEN 2
        WHEN 'High Activity' THEN 3
    END;