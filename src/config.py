import os
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(PROJECT_ROOT / ".env")

# Support both the documented POSTGRES_* names and the legacy DB_* names.
DATABASE_CONFIG = {
    "host": os.getenv("POSTGRES_HOST") or os.getenv("DB_HOST"),
    "port": os.getenv("POSTGRES_PORT") or os.getenv("DB_PORT"),
    "database": os.getenv("POSTGRES_DB") or os.getenv("DB_NAME"),
    "user": os.getenv("POSTGRES_USER") or os.getenv("DB_USER"),
    "password": os.getenv("POSTGRES_PASSWORD") or os.getenv("DB_PASSWORD"),
}
