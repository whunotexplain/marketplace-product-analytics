from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

from src.config import DATABASE_CONFIG


def get_engine() -> Engine:
    """Create a SQLAlchemy engine for the configured PostgreSQL database."""
    required_fields = ("host", "port", "database", "user", "password")
    missing_fields = [
        field for field in required_fields if not DATABASE_CONFIG.get(field)
    ]

    if missing_fields:
        raise RuntimeError(
            "Missing database configuration values: "
            + ", ".join(missing_fields)
            + ". Check the project .env file."
        )

    database_url = __import__("sqlalchemy").URL.create(
        drivername="postgresql+psycopg2",
        username=DATABASE_CONFIG["user"],
        password=DATABASE_CONFIG["password"],
        host=DATABASE_CONFIG["host"],
        port=int(DATABASE_CONFIG["port"]),
        database=DATABASE_CONFIG["database"],
    )

    return create_engine(
        database_url,
        pool_pre_ping=True,
        pool_size=5,
        max_overflow=2,
        future=True,
    )
