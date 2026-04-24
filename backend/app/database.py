from __future__ import annotations

import os
from pathlib import Path

from sqlalchemy import create_engine, select, func
from sqlalchemy.orm import Session, sessionmaker

from .models import Base, Laptop, Rule
from .seed_data import LAPTOP_SEEDS, RULE_SEEDS


ROOT_DIR = Path(__file__).resolve().parents[2]
DATABASE_DIR = ROOT_DIR / "database"
DATABASE_DIR.mkdir(exist_ok=True)
DEFAULT_DATABASE_PATH = DATABASE_DIR / "laptop_expert_system.sqlite3"

DATABASE_URL = os.getenv("DATABASE_URL", f"sqlite:///{DEFAULT_DATABASE_PATH.as_posix()}")

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
)

SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


def get_db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def init_db() -> None:
    Base.metadata.create_all(bind=engine)
    with Session(engine) as session:
        laptop_count = session.scalar(select(func.count()).select_from(Laptop))
        rule_count = session.scalar(select(func.count()).select_from(Rule))
        if laptop_count and rule_count:
            return

        if not laptop_count:
            session.add_all([Laptop(**item) for item in LAPTOP_SEEDS])
        if not rule_count:
            session.add_all([Rule(**item) for item in RULE_SEEDS])
        session.commit()
