from __future__ import annotations

import json
import sqlite3
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
DATABASE_PATH = ROOT_DIR / "database" / "laptop.db"
SCHEMA_PATH = ROOT_DIR / "database" / "schema.sql"
LAPTOPS_JSON_PATH = ROOT_DIR / "database" / "seed_laptops.json"
RULES_JSON_PATH = ROOT_DIR / "database" / "seed_rules.json"


def seed_database() -> None:
    DATABASE_PATH.parent.mkdir(exist_ok=True)
    connection = sqlite3.connect(DATABASE_PATH)
    try:
        # Initialize schema
        with SCHEMA_PATH.open("r", encoding="utf-8") as schema_file:
            connection.executescript(schema_file.read())

        # Clear existing data
        connection.execute("DELETE FROM laptops")
        connection.execute("DELETE FROM rules")

        # Load seed data from JSON
        with LAPTOPS_JSON_PATH.open("r", encoding="utf-8") as f:
            laptop_seeds = json.load(f)
        with RULES_JSON_PATH.open("r", encoding="utf-8") as f:
            rule_seeds = json.load(f)

        # Insert laptops
        connection.executemany(
            """
            INSERT INTO laptops (id, name, brand, price, cpu, ram, gpu, category, weight_kg, battery_hours, has_dedicated_gpu)
            VALUES (:id, :name, :brand, :price, :cpu, :ram, :gpu, :category, :weight_kg, :battery_hours, :has_dedicated_gpu)
            """,
            laptop_seeds,
        )

        # Insert rules
        connection.executemany(
            """
            INSERT INTO rules (id, conditions, conclusions, priority)
            VALUES (?, ?, ?, ?)
            """,
            [
                (rule["id"], json.dumps(rule["conditions"]), json.dumps(rule["conclusions"]), rule["priority"])
                for rule in rule_seeds
            ],
        )
        connection.commit()
        print(f"Successfully seeded database at {DATABASE_PATH}")
    except Exception as e:
        print(f"Error seeding database: {e}")
    finally:
        connection.close()


if __name__ == "__main__":
    seed_database()
