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

CATEGORIES_FILE = (
    PROJECT_ROOT / "data" / "raw" / "category_tree.csv"
)


def load_categories(
    file_path: Path = CATEGORIES_FILE,
    engine: Engine | None = None,
) -> int:
    """
    Load category_tree.csv into staging.stg_categories.

    Data is processed in chunks within one database transaction.
    Repeated ingestion of the same file is skipped using SHA256.
    """
    if not file_path.exists():
        raise FileNotFoundError(
            f"Categories file not found: {file_path}"
        )

    engine = engine or get_engine()

    checksum = calculate_sha256(file_path)
    rows_loaded = 0

    logger.info(
        "Starting categories ingestion: %s",
        file_path.name,
    )

    try:
        with engine.begin() as connection:

            batch_id = register_batch(
                connection=connection,
                dataset_name="categories",
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
                chunksize=1_000,
                dtype={
                    "categoryid": "int64",
                    "parentid": "Int64",
                },
            )

            for chunk_number, chunk in enumerate(chunks, start=1):

                chunk["parentid"] = (
                    chunk["parentid"]
                    .astype(object)
                    .where(chunk["parentid"].notna(), None)
                )

                chunk["source_file"] = file_path.name

                chunk = chunk[
                    [
                        "categoryid",
                        "parentid",
                        "source_file",
                    ]
                ]

                chunk.to_sql(
                    name="stg_categories",
                    con=connection,
                    schema="staging",
                    if_exists="append",
                    index=False,
                    chunksize=1_000,
                )

                rows_loaded += len(chunk)

                logger.info(
                    "Categories chunk %s loaded: %s rows.",
                    chunk_number,
                    len(chunk),
                )

            finish_batch(
                connection=connection,
                batch_id=batch_id,
                rows_loaded=rows_loaded,
            )

        logger.info(
            "Categories ingestion completed. Total rows: %s",
            rows_loaded,
        )

        return rows_loaded

    except Exception:
        logger.exception("Categories ingestion failed.")
        raise


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s",
    )

    load_categories()