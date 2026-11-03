select 
	event,
	COUNT(se.event_id ) as events_count,
	ROUND(
        COUNT(se.event_id) * 100.0 /
        SUM(COUNT(se.event_id)) OVER (),
        2
    ) AS percentage
from staging.stg_events se 
group by event;

/*Задание C — Активность по дням

Получить:
- дату;
- количество событий;
- количество уникальных пользователей;
- количество просмотров;
- количество добавлений в корзину;
- количество событий покупки.
Отсортировать по дате.*/

SELECT
	DATE(event_timestamp) AS date,
	COUNT(event_id) AS count_events,
	COUNT(DISTINCT visitorid) AS count_unique_visitors,
	SUM(CASE WHEN EVENT = 'view' THEN 1 ELSE 0 END) AS views_amount,
	SUM(CASE WHEN EVENT = 'addtocart' THEN 1 ELSE 0 END) AS count_add_to_cart,
	SUM(CASE WHEN EVENT = 'transaction' THEN 1 ELSE 0 END) AS count_events_buy
FROM staging.stg_events
GROUP BY DATE(event_timestamp)
ORDER BY DATE(event_timestamp) ASC;


--Тебе нужно получить три числа:
--- view_users
--- cart_users
--- purchase_users
--Подсказка: используй COUNT(DISTINCT visitorid) и условную агрегацию через FILTER.
--view_to_cart_cr = cart_users / view_users * 100
--cart_to_purchase_cr = purchase_users / cart_users * 100
--view_to_purchase_cr = purchase_users / view_users * 100


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