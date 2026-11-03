CREATE TABLE IF NOT EXISTS staging.ingestion_batches (
    batch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    dataset_name VARCHAR(100) NOT NULL,
    source_file TEXT NOT NULL,
    file_checksum CHAR(64) NOT NULL,

    rows_loaded BIGINT NOT NULL DEFAULT 0,

    loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_ingestion_batch
        UNIQUE (dataset_name, file_checksum)
);

COMMENT ON TABLE staging.ingestion_batches IS
'Metadata and audit information about ingested source files.';

COMMENT ON COLUMN staging.ingestion_batches.file_checksum IS
'SHA256 checksum used to prevent repeated ingestion of identical files.';

COMMENT ON COLUMN staging.ingestion_batches.rows_loaded IS
'Number of successfully ingested source records.';