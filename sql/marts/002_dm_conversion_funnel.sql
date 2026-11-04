DROP MATERIALIZED VIEW IF EXISTS analytics.dm_conversion_funnel;

-- Grain: one row for the full observation period.
-- This is a baseline user-reach funnel, not a sequential or session-level funnel.
-- A user may appear at one stage without being observed at the preceding stage.

CREATE MATERIALIZED VIEW analytics.dm_conversion_funnel AS
SELECT
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
        / NULLIF(COUNT(DISTINCT visitorid) FILTER (WHERE event = 'addtocart'), 0),
        2
    ) AS cart_to_purchase_cr,
    ROUND(
        COUNT(DISTINCT visitorid) FILTER (WHERE event = 'transaction') * 100.0
        / NULLIF(COUNT(DISTINCT visitorid) FILTER (WHERE event = 'view'), 0),
        2
    ) AS view_to_purchase_cr
FROM staging.stg_events;

COMMENT ON MATERIALIZED VIEW analytics.dm_conversion_funnel IS
'Whole-period user reach funnel. Stage membership is not sequence-validated.';
