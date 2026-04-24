from __future__ import annotations

import json
import sqlite3
from pathlib import Path

from backend.app.seed_data import LAPTOP_SEEDS, RULE_SEEDS


ROOT_DIR = Path(__file__).resolve().parents[1]
DATABASE_PATH = ROOT_DIR / "database" / "laptop_expert_system.sqlite3"
SCHEMA_PATH = ROOT_DIR / "database" / "schema.sql"


def seed_database() -> None:
    DATABASE_PATH.parent.mkdir(exist_ok=True)
    connection = sqlite3.connect(DATABASE_PATH)
    try:
        with SCHEMA_PATH.open("r", encoding="utf-8") as schema_file:
            connection.executescript(schema_file.read())

        connection.execute("DELETE FROM laptops")
        connection.execute("DELETE FROM rules")

        connection.executemany(
            """
            INSERT INTO laptops (id, name, brand, price, cpu, ram, gpu, category, weight_kg, battery_hours, has_dedicated_gpu)
            VALUES (:id, :name, :brand, :price, :cpu, :ram, :gpu, :category, :weight_kg, :battery_hours, :has_dedicated_gpu)
            """,
            LAPTOP_SEEDS,
        )
        connection.executemany(
            """
            INSERT INTO rules (id, conditions, conclusions, priority)
            VALUES (?, ?, ?, ?)
            """,
            [
                (rule["id"], json.dumps(rule["conditions"]), json.dumps(rule["conclusions"]), rule["priority"])
                for rule in RULE_SEEDS
            ],
        )
        connection.commit()
    finally:
        connection.close()


if __name__ == "__main__":
    seed_database()
