# Metric Dictionary — Marketplace Intelligence

This document describes metrics implemented in the current SQL Data Marts. SQL definitions are the source of truth.

## Conventions

- Timestamp: UTC-naive in PostgreSQL staging; interpreted as UTC.
- Visitor: distinct `visitorid`; an observed identifier, not necessarily a real-world person.
- Event types: `view`, `addtocart`, `transaction`.
- Monetary metrics are unavailable because reliable price/currency attributes are absent.

## Daily KPIs — `analytics.dm_daily_kpis`

**Grain:** one row per UTC calendar date.

| Metric | Definition |
|---|---|
| total_events | Count of event rows on the date |
| dau | Distinct visitors with any event on the date |
| views | Count of view event rows |
| cart_events | Count of addtocart event rows |
| purchase_events | Count of transaction event rows; not unique transactions |
| view_users | Distinct visitors with a view on the date |
| cart_users | Distinct visitors with an addtocart on the date |
| purchase_users | Distinct visitors with a transaction event on the date |
| view_to_cart_cr | cart_users / view_users × 100 for the same date |
| view_to_purchase_cr | purchase_users / view_users × 100 for the same date |

Same-day ratios do not enforce event order and are not session-level conversion metrics. Daily distinct users cannot be summed to obtain period-unique visitors.

## Conversion funnel — `analytics.dm_conversion_funnel`

**Grain:** one row for the full observation period.

- `view_users`: distinct visitors with at least one view event.
- `cart_users`: distinct visitors with at least one addtocart event.
- `purchase_users`: distinct visitors with at least one transaction event.
- Conversion ratios use the corresponding stage reach counts.

This is a baseline user-reach funnel. It does not require view before addtocart or addtocart before transaction. Counts are not guaranteed to be nested. Do not interpret differences between stage counts as sequential drop-off.

## Weekly retention — `analytics.dm_weekly_retention`

**Grain:** cohort week × elapsed calendar week.

- Cohort week: `DATE_TRUNC('week', MIN(event_timestamp))` per visitor.
- Activity week: calendar week with at least one event.
- week_number: integer calendar-week difference from cohort week.
- cohort_size: visitors whose first observed event belongs to the cohort.
- active_users: cohort visitors with at least one event in the elapsed week.
- retention_rate: active_users / cohort_size × 100.

W0 is 100% by cohort construction. Missing cohort/week rows are not materialized as zero. Recent cohorts have incomplete follow-up time (right-censoring).

## User segments — `analytics.dm_user_segments`

**Grain:** one row per visitor.

| Segment | Rule |
|---|---|
| Low Activity | Exactly 1 event |
| Medium Activity | 2–3 events |
| High Activity | 4 or more events |

Segments are based on total observed event count, including transaction event rows. They measure event frequency, not customer value. Differences in purchase rate are descriptive and partly mechanically coupled to the segment definition.

## Temporal activity — `analytics.dm_temporal_activity`

**Grain:** UTC day of week × UTC hour.

- PostgreSQL DOW: Sunday = 0, Monday = 1, …, Saturday = 6.
- Hour: 0–23.
- total_events/views/add_to_carts/purchases: event-row counts in the bucket over the observation period.
- unique_users: distinct visitors in that weekday/hour bucket over the full period; not additive across buckets.

For weekday/hour intensity comparisons, normalize event counts by the number of calendar occurrences of that weekday in the observation window. The Python notebook performs this exposure normalization.
