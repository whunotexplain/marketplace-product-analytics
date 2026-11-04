WITH data_preprocessor_ct AS (
    SELECT
        COUNT(DISTINCT visitorid) FILTER (
            WHERE event = 'view'
        ) AS view_users,
        COUNT(DISTINCT visitorid) FILTER (
            WHERE event = 'addtocart'
        ) AS cart_users,
        COUNT(DISTINCT visitorid) FILTER (
            WHERE event = 'transaction'
        ) AS purchase_users
    FROM staging.stg_events
)

SELECT
    ROUND(
        cart_users::DECIMAL / NULLIF(view_users, 0) * 100,
        2
    ) AS view_to_cart_cr,
    ROUND(
        purchase_users::DECIMAL / NULLIF(cart_users, 0) * 100,
        2
    ) AS cart_to_purchase_cr,
    ROUND(
        purchase_users::DECIMAL / NULLIF(view_users, 0) * 100,
        2
    ) AS view_to_purchase_cr
FROM data_preprocessor_ct;