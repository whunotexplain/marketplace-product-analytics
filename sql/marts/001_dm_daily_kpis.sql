-- Grain: one row per UTC calendar date.
-- Conversion columns are same-day user reach ratios, not sequential funnel rates.

CREATE MATERIALIZED VIEW analytics.dm_daily_kpis AS
SELECT
    DATE(event_timestamp) AS event_date,
    COUNT(event_id) AS total_events,
    COUNT(DISTINCT visitorid) AS dau,
    COUNT(*) FILTER (WHERE event = 'view') AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart') AS cart_events,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchase_events,
    COUNT(DISTINCT visitorid) FILTER (WHERE event = 'view') AS view_users,
    COUNT(DISTINCT visitorid) FILTER (WHERE event = 'addtocart') AS cart_users,
    COUNT(DISTINCT visitorid) FILTER (WHERE event = 'transaction') AS purchase_users,
    ROUND(
        COUNT(DISTINCT visitorid) FILTER (WHERE event = 'addtocart') * 100.0
        / NULLIF(COUNT(DISTINCT visitorid) FILTER (WHERE event = 'view'), 0),
        2
    ) AS view_to_cart_cr,
    ROUND(
        COUNT(DISTINCT visitorid) FILTER (WHERE event = 'transaction') * 100.0
        / NULLIF(COUNT(DISTINCT visitorid) FILTER (WHERE event = 'view'), 0),
        2
    ) AS view_to_purchase_cr
FROM staging.stg_events
GROUP BY DATE(event_timestamp);

CREATE UNIQUE INDEX idx_dm_daily_kpis_event_date
    ON analytics.dm_daily_kpis (event_date);

COMMENT ON MATERIALIZED VIEW analytics.dm_daily_kpis IS
'Daily product KPIs. Timestamp is UTC-naive; conversion rates are same-day user reach ratios.';
