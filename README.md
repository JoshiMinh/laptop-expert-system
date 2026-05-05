# Laptop Expert System

A local, explainable recommendation system for selecting laptops. This repository
contains three cooperating components that together provide explainable, rule-based
recommendations with a modern web UI and an academic Prolog advisor for research
and reproducibility.

Contents in brief:
- Backend: Python FastAPI service with a forward-chaining inference engine
- Frontend: Vite + React TypeScript user interface
- Prolog: SWI-Prolog expert system (advisor) for alternate reasoning and research
- Database: SQLite files and JSON seed data for reproducible datasets

Table of contents
- Purpose
- Quick start (install & run)
- Database and seeding
- Backend API (endpoints & examples)
- Prolog advisor (usage)
- Development & testing
- Troubleshooting

Purpose
-------
The Laptop Expert System helps users find laptops matching budget, usage, and
preference constraints while preserving full explainability: every recommendation
includes the reasoning trace (which rules fired and why).

Quick start
-----------
Prerequisites:
- Node.js and pnpm (for frontend)
- Python 3.10+ and pip (for backend)
- Optional: SWI-Prolog (for the Prolog advisor)

Install project dependencies:

```bash
pnpm install
```

Run frontend and backend concurrently (development):

```bash
pnpm dev
```

Individual components:

```bash
# Start backend only (runs on :8000)
pnpm run dev:backend

# Start frontend only (default Vite port)
pnpm run dev:frontend
```

Database
--------
The project uses a tracked SQLite database file at database/laptop.db. The
database file is included in the repository to provide immediate, deterministic
data for demos and tests. There is no active seeding workflow in primary
development — the repository uses the checked-in `database/laptop.db`.

If you need to regenerate or migrate the database, do so intentionally and
coordinate with maintainers; removing or changing the tracked DB will affect
everyone cloning the repo.

Backend API
-----------
The backend exposes REST endpoints for recommendations and catalog access.

Main endpoints:
- `POST /recommend` — request personalized recommendations
- `GET /laptops` — return catalog entries

Example request for `/recommend`:

```json
{
  "budget": "medium",
  "usage": ["coding", "portable"],
  "preferences": { "brands": ["Dell"], "max_weight": 1.6 }
}
```

Responses include a `reasoning` field showing which rules fired and the
confidence for each recommendation.

Prolog advisor (optional)
-------------------------
The Prolog advisor is an independent component for experimentation and teaching.
Install SWI-Prolog and run the advisor like this:

```bash
cd prolog
swipl -s advisor.pl
```

Use the provided queries in `prolog/advisor.pl` for example consultations.

Development & testing
---------------------
Backend:
- Project uses FastAPI, Pydantic, and simple SQLite persistence.
- Run backend tests from the backend folder:

```bash
cd backend
pytest
```

Frontend:
- Built with React + TypeScript and Vite. Start the dev server with
  `pnpm run dev:frontend` and build for production with `pnpm run build`.

Recreating or migrating the database in CI or locally
- Coordinate DB changes with maintainers. If you prefer regenerating from
  scratch, create a reproducible migration or dataset script and open a PR so
  it can be reviewed and versioned.

Troubleshooting
---------------
- Missing Python dependencies: ensure you have a virtualenv and run
  `pip install -r backend/requirements.txt` (or equivalent project setup).
- If SWI-Prolog is not found, install it from https://www.swi-prolog.org/

Where to look next
------------------
- Backend inference logic: `backend/inference/` (engine and reasoning code)
- API definitions: `backend/app/main.py` and `backend/schemas.py`
- Prolog advisor: `prolog/advisor.pl` and `prolog/db.pl`

Contributing
------------
- Run backend tests and ensure frontend builds before opening a PR.
- Add tests for new inference rules and update seed data if needed.

License
-------
MIT — see the LICENSE file for details.

Files changed in this update:
- Updated repository README to summarize purpose, usage, and manuals.

Last updated: 2026
