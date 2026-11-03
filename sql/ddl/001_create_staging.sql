CREATE SCHEMA IF NOT EXISTS staging;


CREATE TABLE IF NOT EXISTS staging.stg_events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    visitorid BIGINT NOT NULL,
    itemid BIGINT NOT NULL,
    transactionid BIGINT,

    event VARCHAR(20) NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,

    source_file TEXT NOT NULL,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS staging.stg_categories (
    category_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    categoryid BIGINT NOT NULL,
    parentid BIGINT,

    source_file TEXT NOT NULL,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


COMMENT ON TABLE staging.stg_events IS
'Raw event records loaded from the Retailrocket events.csv dataset.';

COMMENT ON TABLE staging.stg_categories IS
'Raw category hierarchy records loaded from the Retailrocket category_tree.csv dataset.';


COMMENT ON COLUMN staging.stg_events.event_id IS
'Technical surrogate key generated during data ingestion.';

COMMENT ON COLUMN staging.stg_events.visitorid IS
'Source identifier of the visitor.';

COMMENT ON COLUMN staging.stg_events.itemid IS
'Source identifier of the product item.';

COMMENT ON COLUMN staging.stg_events.transactionid IS
'Source transaction identifier. NULL for non-transaction events.';

COMMENT ON COLUMN staging.stg_events.event IS
'Event type: view, addtocart or transaction.';

COMMENT ON COLUMN staging.stg_events.event_timestamp IS
'Timestamp of the original event, interpreted as UTC.';

COMMENT ON COLUMN staging.stg_events.source_file IS
'Name of the source file used during ingestion.';

COMMENT ON COLUMN staging.stg_events.loaded_at IS
'Timestamp when the record was loaded into staging.';

COMMENT ON COLUMN staging.stg_categories.category_row_id IS
'Technical surrogate key generated during data ingestion.';

COMMENT ON COLUMN staging.stg_categories.categoryid IS
'Source identifier of the category.';

COMMENT ON COLUMN staging.stg_categories.parentid IS
'Source identifier of the parent category. NULL indicates a root category.';

COMMENT ON COLUMN staging.stg_categories.source_file IS
'Name of the source file used during ingestion.';

COMMENT ON COLUMN staging.stg_categories.loaded_at IS
'Timestamp when the record was loaded into staging.';