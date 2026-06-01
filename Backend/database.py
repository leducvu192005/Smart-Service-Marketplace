import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Load environment variables from .env file
load_dotenv()

# Get DB_URL from environment variables
db_url = os.getenv("DB_URL")

# Check if db_url is set and not a placeholder
is_supabase = False
if db_url and "[your-project-ref]" not in db_url and "[your-password]" not in db_url:
    # Supabase connection URLs sometimes start with postgres://, but SQLAlchemy requires postgresql://
    if db_url.startswith("postgres://"):
        db_url = db_url.replace("postgres://", "postgresql://", 1)
    SQLALCHEMY_DATABASE_URL = db_url
    is_supabase = True
else:
    # Fallback to local SQLite database
    SQLALCHEMY_DATABASE_URL = "sqlite:///./smart_service.db"

# Create database engine
if is_supabase:
    # PostgreSQL doesn't require check_same_thread
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
else:
    # SQLite requires check_same_thread=False for multi-threading in FastAPI
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

