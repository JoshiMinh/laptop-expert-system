PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS laptops (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  brand TEXT NOT NULL,
  price INTEGER NOT NULL,
  cpu TEXT NOT NULL,
  ram INTEGER NOT NULL,
  gpu TEXT NOT NULL,
  category TEXT NOT NULL,
  weight_kg REAL,
  battery_hours REAL,
  has_dedicated_gpu INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS rules (
  id TEXT PRIMARY KEY,
  conditions TEXT NOT NULL,
  conclusions TEXT NOT NULL,
  priority INTEGER NOT NULL
);
