from sqlalchemy import URL, create_engine
from src.config import DATABASE_CONFIG

_REQUIRED_FIELDS = ("host", "port", "database", "user", "password")
_missing = [field for field in _REQUIRED_FIELDS if not DATABASE_CONFIG.get(field)]

if _missing:
    raise RuntimeError(
        "Missing database configuration values: "
        + ", ".join(_missing)
        + ". Check the project .env file."
    )

DATABASE_URL = URL.create(
    drivername="postgresql+psycopg2",
    username=DATABASE_CONFIG["user"],
    password=DATABASE_CONFIG["password"],
    host=DATABASE_CONFIG["host"],
    port=int(DATABASE_CONFIG["port"]),
    database=DATABASE_CONFIG["database"],
)

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    future=True,
)
