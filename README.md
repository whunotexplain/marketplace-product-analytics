# Marketplace Intelligence — Product Analytics & Experimentation

End-to-end product analytics portfolio project based on the Retailrocket e-commerce event dataset.

## Objective

Build a reproducible workflow from raw event data to PostgreSQL Data Marts, Python analysis and a BI dashboard. The focus is Product Data Analytics: KPIs, conversion, retention, behavioral segmentation, temporal patterns and experimentation.

## Dataset

Retailrocket E-commerce Dataset: https://www.kaggle.com/datasets/retailrocket/ecommerce-dataset

The event log contains approximately 2.76M rows, 1.41M visitor IDs, 235K item IDs and 17.7K distinct transaction IDs.

**Data limitations**
- Reliable price/currency fields are absent: GMV, Revenue and AOV are not calculated.
- A transaction event row is not necessarily a unique transaction; use transactionid.
- Repeated visitor-item events are not automatically duplicates.
- The current funnel is a whole-period user-reach funnel, not a sequential/session-level funnel.
- Activity segments measure event frequency, not customer value.
- Timestamps are stored as UTC-naive and interpreted as UTC.
- Item-to-category mapping is not confirmed; category performance is not reported.

## Implemented architecture

```text
Retailrocket CSV
      |
      v
Python ingestion
      |
      v
PostgreSQL staging
      |
      v
PostgreSQL analytics Data Marts
      |
      +------> Python / Pandas notebook
      |
      +------> Yandex DataLens dashboard
```

The current MVP intentionally keeps the architecture lean and product-analytics-oriented. A separate CORE/star-schema and session model are potential future extensions, not prerequisites for this version.

## Data Marts

| Data Mart | Grain | Purpose |
|---|---|---|
| analytics.dm_daily_kpis | One row per date | DAU, event counts and same-day user reach ratios |
| analytics.dm_conversion_funnel | One row for full period | Whole-period user reach by event type |
| analytics.dm_weekly_retention | Cohort week × elapsed week | Weekly cohort retention |
| analytics.dm_user_segments | One row per visitor | Event-frequency segments and user behavior |
| analytics.dm_temporal_activity | Weekday × hour (UTC) | Temporal activity distribution |

Execute SQL scripts in `sql/marts/` in numeric order.

## Python analysis

Notebook: [02_product_analytics.ipynb](notebooks/02_product_analytics.ipynb)

The notebook loads the SQL marts from PostgreSQL, validates their grain and reconciliation rules, and explores:
- KPI overview and daily activity
- Baseline conversion funnel
- Weekly cohort retention
- User activity segments
- Weekday/hour activity normalized by calendar exposure
- Descriptive findings and data limitations

## Repository structure

- `src/ingestion/` — CSV ingestion scripts
- `src/config.py`, `src/database.py` — database configuration and SQLAlchemy engine
- `sql/ddl/` — staging DDL
- `sql/analysis/` — exploratory SQL analyses
- `sql/marts/` — analytical materialized views
- `notebooks/` — profiling and product analytics
- `docs/` — architecture, data dictionary and metric definitions
- `data/raw/`, `data/processed/` — local data; excluded from Git

## Setup

1. Create a local `.env` file in the repository root:

```env
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_DB=marketplace
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password
```

2. Install dependencies:

```bash
uv pip install -r requirements.txt
```

3. Create staging tables using `sql/ddl/001_create_staging.sql` and the ingestion batch table using `sql/ddl/002_create_ingestion_batches.sql`.

4. Put the source CSV files in `data/raw/` and run:

```bash
uv run python -m src.ingestion.load_categories
uv run python -m src.ingestion.load_events
```

5. Execute SQL files in `sql/marts/` in numeric order.

6. Launch Jupyter from the repository root:

```bash
uv run jupyter lab
```

Open `notebooks/02_product_analytics.ipynb` and run all cells.

## Refresh materialized views

After reloading or changing staging data, refresh the marts:

```sql
REFRESH MATERIALIZED VIEW analytics.dm_daily_kpis;
REFRESH MATERIALIZED VIEW analytics.dm_conversion_funnel;
REFRESH MATERIALIZED VIEW analytics.dm_weekly_retention;
REFRESH MATERIALIZED VIEW analytics.dm_user_segments;
REFRESH MATERIALIZED VIEW analytics.dm_temporal_activity;
```

The dataset is distributed under CC BY-NC-SA 4.0. Review the source page for license terms before redistributing derived data.
