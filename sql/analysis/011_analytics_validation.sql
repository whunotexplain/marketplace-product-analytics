WITH total_users AS (
    SELECT
        COUNT(DISTINCT visitorid) AS total_users
    FROM staging.stg_events
),

segmented_users AS (
    SELECT
        COUNT(*) AS users_count
    FROM (
        SELECT
            visitorid,
            CASE
                WHEN COUNT(*) = 1 THEN 'Low Activity'
                WHEN COUNT(*) BETWEEN 2 AND 3 THEN 'Medium Activity'
                WHEN COUNT(*) >= 4 THEN 'High Activity'
            END AS activity_segment
        FROM staging.stg_events
        GROUP BY visitorid
    ) AS users
    GROUP BY activity_segment
),

segment_total AS (
    SELECT
        SUM(users_count) AS segmented_users_count
    FROM segmented_users
)

SELECT
    tu.total_users,
    st.segmented_users_count,
    tu.total_users - st.segmented_users_count AS difference,
    CASE
        WHEN tu.total_users = st.segmented_users_count THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM total_users tu
CROSS JOIN segment_total st;