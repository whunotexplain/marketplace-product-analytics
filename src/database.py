from sqlalchemy import create_engine
from src.config import DATABASE_CONFIG

DATABASE_URL = (
    f"postgresql+psycopg2://"
    f"{DATABASE_CONFIG['user']}:"
    f"{DATABASE_CONFIG['password']}@"
    f"{DATABASE_CONFIG['host']}:"
    f"{DATABASE_CONFIG['port']}/"
    f"{DATABASE_CONFIG['database']}"
)

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True
)