# Laptop Expert System

A fully local monorepo for explainable laptop recommendations. The backend is a FastAPI service with a custom forward-chaining inference engine, SQLite persistence, and seed data. The frontend is a Vite React app that collects budget and usage needs and displays ranked results plus a reasoning trace.

## Structure

- `backend/` FastAPI API, inference engine, SQLAlchemy models, tests
- `frontend/` Vite React UI
- `shared/` shared TypeScript interfaces
- `database/` SQLite schema and seed script

## Setup

1. Install the frontend workspace dependencies from the repo root:

```bash
npm install
```

2. Install the Python backend environment:

```bash
cd backend
pip install -e .[dev]
```

3. Start both apps from the repo root:

```bash
npm run dev
```

The frontend runs on `http://127.0.0.1:5173` and the API on `http://127.0.0.1:8000`.

If you only want the API, run this from inside `backend/`:

```bash
uvicorn main:app --reload
```

## How inference works

The engine uses forward chaining:

1. Start with working memory built from the request facts such as budget and usage.
2. Load the rule set from SQLite.
3. Find all rules whose conditions match the current facts.
4. Resolve conflicts by selecting the rule with the most conditions first, then the highest priority, then a deterministic rule id order.
5. Fire the selected rule, update working memory, and repeat until no new rules apply.

The response includes both the fired rules and the final recommendation explanations.

## Rule examples

- `budget = low` and `usage contains office` -> `preferred_category = office`, `max_price = 700`
- `budget = medium` and `usage contains coding` -> `preferred_category = coding`, `min_ram = 16`
- `usage contains gaming` -> `preferred_category = gaming`, `need_gpu = true`
- `usage contains all of coding + gaming` -> `preferred_category = gaming`, `min_ram = 32`

## API

### `POST /recommend`

Input:

```json
{
  "budget": "medium",
  "usage": ["coding", "portable"]
}
```

### `GET /laptops`

Returns the full laptop catalog from SQLite.

## Tests

Run backend tests from the `backend/` directory:

```bash
pytest
```

## Database

The app stores data locally in SQLite at `database/laptop_expert_system.sqlite3`. The backend seeds the database automatically on startup if the tables are empty. You can also regenerate it manually with:

```bash
python database/seed.py
```

## Notes

- No external APIs are used.
- No cloud database is required.
- Brand filtering is supported as an optional input.
