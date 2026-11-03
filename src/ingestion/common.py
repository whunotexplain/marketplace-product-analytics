import hashlib
import logging
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.engine import Connection


logger = logging.getLogger(__name__)


def calculate_sha256(file_path: Path) -> str:
    """
    Calculate SHA256 checksum of a file.
    """
    sha256 = hashlib.sha256()

    with file_path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            sha256.update(chunk)

    return sha256.hexdigest()


def register_batch(
    connection: Connection,
    dataset_name: str,
    source_file: str,
    checksum: str,
) -> int | None:
    """
    Register a new ingestion batch.

    Return batch ID if the file has not been loaded.
    Return None if the same file was already loaded.
    """
    query = text("""
        INSERT INTO staging.ingestion_batches (
            dataset_name,
            source_file,
            file_checksum
        )
        VALUES (
            :dataset_name,
            :source_file,
            :file_checksum
        )
        ON CONFLICT (dataset_name, file_checksum)
        DO NOTHING
        RETURNING batch_id;
    """)

    result = connection.execute(
        query,
        {
            "dataset_name": dataset_name,
            "source_file": source_file,
            "file_checksum": checksum,
        },
    )

    return result.scalar_one_or_none()


def finish_batch(
    connection: Connection,
    batch_id: int,
    rows_loaded: int,
) -> None:
    """
    Update ingestion batch statistics.
    """
    query = text("""
        UPDATE staging.ingestion_batches
        SET rows_loaded = :rows_loaded
        WHERE batch_id = :batch_id;
    """)

    connection.execute(
        query,
        {
            "batch_id": batch_id,
            "rows_loaded": rows_loaded,
        },
    )

    logger.info(
        "Batch %s completed. Rows loaded: %s",
        batch_id,
        rows_loaded,
    )