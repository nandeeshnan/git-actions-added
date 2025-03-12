from dotenv import load_dotenv
import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()
# DATABASE_URL = os.getenv("DATABASE_URL")
DATABASE_URL = "postgresql+asyncpg://nandeesh:nandeesh123@database-1.cxm2omoga4r6.us-east-1.rds.amazonaws.com:5432/recipefind"
engine = create_async_engine(DATABASE_URL, echo=True)
async_session = sessionmaker(
    engine, expire_on_commit=False, class_=AsyncSession
)
Base = declarative_base()
