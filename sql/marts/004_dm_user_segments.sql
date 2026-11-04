DROP MATERIALIZED VIEW IF EXISTS analytics.dm_user_segments;

-- Grain: one row per visitor.
-- Activity segments describe event frequency, not customer value.

CREATE MATERIALIZED VIEW analytics.dm_user_segments AS
WITH user_activity AS (
    SELECT
        visitorid,
        COUNT(event_id) AS total_events,
        COUNT(*) FILTER (WHERE event = 'view') AS views,
        COUNT(*) FILTER (WHERE event = 'addtocart') AS add_to_carts,
        COUNT(*) FILTER (WHERE event = 'transaction') AS purchases,
        MIN(event_timestamp) AS first_activity,
        MAX(event_timestamp) AS last_activity
    FROM staging.stg_events
    GROUP BY visitorid
)
SELECT
    visitorid,
    total_events,
    views,
    add_to_carts,
    purchases,
    first_activity,
    last_activity,
    CASE
        WHEN total_events = 1 THEN 'Low Activity'
        WHEN total_events BETWEEN 2 AND 3 THEN 'Medium Activity'
        WHEN total_events >= 4 THEN 'High Activity'
    END AS activity_segment
FROM user_activity;

CREATE UNIQUE INDEX idx_dm_user_segments_visitorid
    ON analytics.dm_user_segments (visitorid);

COMMENT ON MATERIALIZED VIEW analytics.dm_user_segments IS
'One row per visitor. Segments are based on total observed event count, not monetary or causal value.';
