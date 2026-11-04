DROP MATERIALIZED VIEW IF EXISTS analytics.dm_temporal_activity;

-- Grain: one row per UTC weekday and hour (up to 7 * 24 = 168 rows).
-- unique_users is distinct across the full observation period within each weekday/hour bucket;
-- it is not additive across buckets.

CREATE MATERIALIZED VIEW analytics.dm_temporal_activity AS
SELECT
    EXTRACT(DOW FROM event_timestamp)::INT AS day_of_week,
    EXTRACT(HOUR FROM event_timestamp)::INT AS hour_of_day,
    COUNT(event_id) AS total_events,
    COUNT(DISTINCT visitorid) AS unique_users,
    COUNT(*) FILTER (WHERE event = 'view') AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart') AS add_to_carts,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases
FROM staging.stg_events
GROUP BY
    EXTRACT(DOW FROM event_timestamp),
    EXTRACT(HOUR FROM event_timestamp);

CREATE UNIQUE INDEX idx_dm_temporal_activity_day_hour
    ON analytics.dm_temporal_activity (day_of_week, hour_of_day);

COMMENT ON MATERIALIZED VIEW analytics.dm_temporal_activity IS
'UTC weekday/hour activity. Distinct users are calculated within each bucket over the full observation period.';
