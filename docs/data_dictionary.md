# Data Dictionary — Marketplace Intelligence

> Source: Retailrocket E-commerce Dataset
> Implemented database: PostgreSQL
> Time convention: UTC

## 1. Source data

| Source | Description | Current use |
|---|---|---|
| `events.csv` | Visitor event log | Loaded to `staging.stg_events` |
| `category_tree.csv` | Category hierarchy | Loaded to `staging.stg_categories` |
| `item_properties_part1.csv`, `item_properties_part2.csv` | Item attributes | Not currently used by the implemented marts |

Observed profile from the initial dataset inspection:

| Metric | Value |
|---|---:|
| Event rows | 2,756,101 |
| Unique visitors | 1,407,580 |
| Unique items | 235,061 |
| Unique transaction IDs | 17,672 |
| View event rows | 2,664,312 |
| Add-to-cart event rows | 69,332 |
| Transaction event rows | 22,457 |
| Categories | 1,669 |
| Fully duplicated event rows | 460 |

## 2. Staging tables

### `staging.stg_events`

**Grain:** one row per ingested event record.

| Column | Type | Meaning |
|---|---|---|
| event_id | BIGINT identity PK | Technical surrogate key generated at ingestion |
| visitorid | BIGINT | Source visitor identifier |
| itemid | BIGINT | Source item identifier |
| transactionid | BIGINT, nullable | Source transaction identifier |
| event | VARCHAR(20) | Event type: view, addtocart, transaction |
| event_timestamp | TIMESTAMP | Event timestamp converted from Unix milliseconds and stored as UTC-naive |
| source_file | TEXT | Source file name |
| loaded_at | TIMESTAMPTZ | Database ingestion timestamp |

The source file has no guaranteed unique event identifier. The generated `event_id` is a staging surrogate key, not a source business key.

### `staging.stg_categories`

**Grain:** one row per ingested category hierarchy row.

| Column | Type | Meaning |
|---|---|---|
| category_row_id | BIGINT identity PK | Technical surrogate key |
| categoryid | BIGINT | Source category identifier |
| parentid | BIGINT, nullable | Parent category identifier; NULL for root |
| source_file | TEXT | Source file name |
| loaded_at | TIMESTAMPTZ | Database ingestion timestamp |

### `staging.ingestion_batches`

Tracks ingestion metadata, including dataset name, source file, checksum and loaded row count. The checksum is used to avoid reloading an identical source file.

## 3. Source semantics and limitations

1. `visitorid` is an observed identifier, not a verified real-world customer identity.
2. `transactionid` is expected to be NULL for view and add-to-cart events.
3. The 22,457 transaction event rows correspond to 17,672 distinct transaction IDs. One transaction may have multiple item-level event rows.
4. Repeated events by the same visitor for the same item are not automatically duplicates.
5. Full duplicate source rows were observed during profiling. The current staging ingestion preserves source rows; the implemented marts do not silently deduplicate them.
6. Reliable price/currency attributes are not available in the currently implemented analytical model. Do not report GMV, Revenue, AOV or monetary LTV.
7. `category_tree.csv` defines a hierarchy but does not prove which category belongs to a given item. Do not join items to categories without a validated mapping.
8. Current timestamps are interpreted as UTC. No visitor-local timezone is available.

## 4. Implemented Data Marts

See [metric_dictionary.md](metric_dictionary.md) for formulas and interpretation caveats.

| Mart | Grain | Main columns |
|---|---|---|
| `analytics.dm_daily_kpis` | One row per UTC date | event_date, total_events, dau, views, cart_events, purchase_events, view_users, cart_users, purchase_users, view_to_cart_cr, view_to_purchase_cr |
| `analytics.dm_conversion_funnel` | One row for full period | view_users, cart_users, purchase_users, view_to_cart_cr, cart_to_purchase_cr, view_to_purchase_cr |
| `analytics.dm_weekly_retention` | Cohort week × elapsed week | cohort_week, week_number, cohort_size, active_users, retention_rate |
| `analytics.dm_user_segments` | One row per visitor | visitorid, total_events, views, add_to_carts, purchases, first_activity, last_activity, activity_segment |
| `analytics.dm_temporal_activity` | UTC weekday × hour | day_of_week, hour_of_day, total_events, unique_users, views, add_to_carts, purchases |

## 5. Future model — not currently implemented

A CORE/star-schema layer, session dimension, event fact and transaction fact were considered during design but are not part of the current implementation. Do not assume those tables exist in the database.

Potential future work:
- Sessionization using an agreed inactivity threshold.
- Strict sequential and session-level conversion.
- Verified item/category mapping.
- A transaction fact at the unique `transactionid` grain after validating visitor and timestamp consistency.
