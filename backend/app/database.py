from __future__ import annotations

import json
import os
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from .models import Base, Laptop, Rule


ROOT_DIR = Path(__file__).resolve().parents[2]
DATABASE_DIR = ROOT_DIR / "database"
DATABASE_DIR.mkdir(exist_ok=True)
DEFAULT_DATABASE_PATH = DATABASE_DIR / "laptop_expert_system.sqlite3"
LAPTOP_SEED_PATH = DATABASE_DIR / "seed_laptops.json"
RULE_SEED_PATH = DATABASE_DIR / "seed_rules.json"

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
    _seed_if_empty()


def _seed_if_empty() -> None:
    with SessionLocal() as session:
        laptop_count = session.query(Laptop).count()
        rule_count = session.query(Rule).count()
        if laptop_count > 0 and rule_count > 0:
            return

        if not LAPTOP_SEED_PATH.exists() or not RULE_SEED_PATH.exists():
            return

        with LAPTOP_SEED_PATH.open("r", encoding="utf-8") as laptop_file:
            laptop_seeds = json.load(laptop_file)
        with RULE_SEED_PATH.open("r", encoding="utf-8") as rule_file:
            rule_seeds = json.load(rule_file)

        if laptop_count == 0:
            session.bulk_insert_mappings(Laptop, laptop_seeds)
        if rule_count == 0:
            session.bulk_insert_mappings(Rule, rule_seeds)

        session.commit()
