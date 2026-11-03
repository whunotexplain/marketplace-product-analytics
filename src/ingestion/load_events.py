import logging
from pathlib import Path

import pandas as pd
from sqlalchemy.engine import Engine

from src.ingestion.common import (
    calculate_sha256,
    finish_batch,
    register_batch,
)
from src.ingestion.connection import get_engine


logger = logging.getLogger(__name__)

PROJECT_ROOT = Path(__file__).resolve().parents[2]

EVENTS_FILE = PROJECT_ROOT / "data" / "raw" / "events.csv"

CHUNK_SIZE = 50_000


def load_events(
    file_path: Path = EVENTS_FILE,
    engine: Engine | None = None,
) -> int:
    """
    Load events.csv into staging.stg_events.

    Data is processed in chunks within one database transaction.
    Repeated ingestion of the same file is skipped using SHA256.
    """
    if not file_path.exists():
        raise FileNotFoundError(
            f"Events file not found: {file_path}"
        )

    engine = engine or get_engine()

    checksum = calculate_sha256(file_path)
    rows_loaded = 0

    logger.info("Starting events ingestion: %s", file_path.name)

    try:
        with engine.begin() as connection:

            batch_id = register_batch(
                connection=connection,
                dataset_name="events",
                source_file=file_path.name,
                checksum=checksum,
            )

            if batch_id is None:
                logger.info(
                    "File %s has already been loaded. Skipping.",
                    file_path.name,
                )
                return 0

            chunks = pd.read_csv(
                file_path,
                chunksize=CHUNK_SIZE,
                dtype={
                    "timestamp": "int64",
                    "visitorid": "int64",
                    "itemid": "int64",
                    "transactionid": "Int64",
                    "event": "string",
                },
            )

            for chunk_number, chunk in enumerate(chunks, start=1):

                # Convert Unix milliseconds to UTC.
                # PostgreSQL column is TIMESTAMP WITHOUT TIME ZONE,
                # so UTC is stored as a timezone-naive timestamp.
                chunk["event_timestamp"] = (
                    pd.to_datetime(
                        chunk["timestamp"],
                        unit="ms",
                        utc=True,
                    )
                    .dt.tz_localize(None)
                )

                # Convert nullable transaction IDs to Python None.
                chunk["transactionid"] = (
                    chunk["transactionid"]
                    .astype(object)
                    .where(chunk["transactionid"].notna(), None)
                )

                chunk["source_file"] = file_path.name

                chunk = chunk[
                    [
                        "visitorid",
                        "itemid",
                        "transactionid",
                        "event",
                        "event_timestamp",
                        "source_file",
                    ]
                ]

                chunk.to_sql(
                    name="stg_events",
                    con=connection,
                    schema="staging",
                    if_exists="append",
                    index=False,
                    chunksize=1_000,
                )

                rows_loaded += len(chunk)

                logger.info(
                    "Events chunk %s loaded: %s rows. Total: %s",
                    chunk_number,
                    len(chunk),
                    rows_loaded,
                )

            finish_batch(
                connection=connection,
                batch_id=batch_id,
                rows_loaded=rows_loaded,
            )

        logger.info(
            "Events ingestion completed. Total rows: %s",
            rows_loaded,
        )

        return rows_loaded

    except Exception:
        logger.exception("Events ingestion failed.")
        raise


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s",
    )

    load_events()