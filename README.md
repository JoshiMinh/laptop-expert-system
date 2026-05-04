# Laptop Expert System

A fully local **monorepo** for explainable laptop recommendations using AI and expert system techniques. This project combines three integrated components:

- **Backend**: FastAPI service with a custom forward-chaining inference engine
- **Frontend**: Vite React app for user interface  
- **Prolog Logic**: Academic Prolog implementations for expert system reasoning

## 📋 Project Overview

The Laptop Expert System is an intelligent recommendation engine that helps users find the perfect laptop based on their budget and usage needs. It provides complete explainability by showing the reasoning trace of how recommendations were generated.

### Key Features

- **Local-First Design**: No external APIs or cloud databases required
- **Complete Explainability**: All recommendations include reasoning traces showing which rules fired
- **SQLite Persistence**: Local database for instant availability
- **Forward Chaining Inference**: Automatic rule-based reasoning
- **Fuzzy Logic**: Handles vague concepts like "expensive," "lightweight," "gaming laptop"
- **Certainty Factor**: Quantifies confidence in recommendations
- **Meta-Rules**: Resolves conflicts between competing requirements
- **Multiple Interfaces**: API-first backend with React frontend and Prolog logic system

## 🚀 Quick Start

### Installation

```bash
# Install all dependencies (backend + frontend)
pnpm i
```

### Running the Application

```bash
# Start both backend and frontend simultaneously
pnpm dev
```

- **Frontend**: http://127.0.0.1:5173
- **Backend API**: http://127.0.0.1:8000

### Alternative: Run Components Separately

```bash
# Backend only
pnpm run dev:backend
# API Docs: http://127.0.0.1:8000/docs

# Frontend only  
pnpm run dev:frontend
```

### Production Build

```bash
pnpm run build
```

## 🧠 How It Works

### Backend Inference Engine

The backend uses **forward chaining**:

1. Build working memory from user input (budget, usage needs, preferences)
2. Load rule set from SQLite database
3. Find all rules whose conditions match current facts
4. Resolve conflicts using rule complexity, priority, and ID ordering
5. Fire selected rule and update working memory
6. Repeat until no new rules apply

### API Endpoints

#### `POST /recommend`

Get personalized recommendations based on user needs.

**Request:**
```json
{
  "budget": "medium",
  "usage": ["coding", "portable"],
  "preferences": {
    "brands": ["Dell", "ASUS"],
    "max_weight": 1.5
  }
}
```

**Response:**
```json
{
  "recommendations": [
    {
      "id": 1,
      "name": "Dell XPS 13",
      "price": 1299,
      "reasoning": ["Rule 1 fired", "Rule 3 fired"]
    }
  ]
}
```

#### `GET /laptops`

Returns the complete laptop catalog from the database.

## 🔬 Prolog Expert System

The Prolog implementation provides academic expert system techniques: Fuzzy Logic, Heuristics, Certainty Factor, Meta-Rules, and Backward Chaining.

### Running Prolog Advisor

The Prolog system runs independently via SWI-Prolog. First, install SWI-Prolog:
- **Windows**: [Download from swi-prolog.org](https://www.swi-prolog.org/Download.html)
- **macOS**: `brew install swi-prolog`
- **Linux (Ubuntu)**: `sudo apt-get install swi-prolog`
- **Linux (Fedora)**: `sudo dnf install swi-prolog`

Then run manually:

```bash
cd prolog
swipl
```

In SWI-Prolog:
```prolog
?- consult('advisor.pl').
```

### Example Queries

```prolog
% Find best laptop for gaming with 35M budget, lightweight
?- tu_van_top_k_giai_thich(gaming, 35000000, [mong_nhe], 3, TopK, CanhBao).

% Find office laptops under 20M
?- tu_van_laptop(van_phong, 20000000, [], Ten, Gia, CF).

% Find graphics design laptop, top budget
?- tu_van_top_k_giai_thich(do_hoa, 50000000, [cao_cap], 5, TopK, CanhBao).
```

### Prolog Parameters

**Usage (NhuCau):**
- `van_phong` - Office work
- `lap_trinh` - General programming  
- `lap_trinh_ios` - iOS development
- `do_hoa` - Graphics design
- `gaming` - Gaming
- `ai_data_science` - AI/Machine Learning

**Budget (NganSach):** Vietnamese Dong (VND)
- Examples: `10000000`, `35000000`, `100000000`

**Constraints (YeuCauThem):**
- `[]` - No requirements
- `[gia_rat_re, mong_nhe]` - Very cheap, lightweight
- `[cao_cap, uu_tien_hieu_nang]` - Premium, performance priority
- `[thich_thuong_hieu('Dell'), gpu_roi]` - Prefer Dell with dedicated GPU

## 💾 Database

The application uses a local SQLite database at `database/laptop.db` which is tracked in git for immediate availability.

### Regenerating Database

To restore or regenerate from seed data:

```bash
cd backend
python -m database.seed
```

## 🧪 Testing

Run backend tests:

```bash
cd backend
pytest
```

## 🛠️ Development

### Backend Development

Technologies:
- **FastAPI** for REST API
- **SQLAlchemy** for ORM
- **Pydantic** for data validation
- **pytest** for testing

### Frontend Development

Technologies:
- **React 18** with TypeScript
- **Vite** for build tooling
- **CSS modules** for styling

## 📚 Documentation

- **[REQUIREMENTS.md](REQUIREMENTS.md)** - Detailed system requirements and setup
- **prolog/advisor.pl** - Prolog expert system logic
- **prolog/db.pl** - Prolog laptop database

## 🔍 Troubleshooting

### "Cannot find module" Error
```bash
pnpm i
```

### "ModuleNotFoundError: No module named 'fastapi'"
```bash
cd backend
pip install -e .[dev]
```

### SWI-Prolog Not Found

For Prolog setup issues, see [REQUIREMENTS.md](REQUIREMENTS.md#prolog-logic-system).

## 📁 Project Structure

- **backend/** - Python FastAPI service with inference engine
- **frontend/** - Vite React application
- **prolog/** - SWI-Prolog expert system implementation
- **database/** - SQLite database and schemas
- **shared/** - Shared TypeScript interfaces

## 🤝 Contributing

Contributions welcome! Please ensure:
1. Backend tests pass: `pytest`
2. Frontend builds: `pnpm run build`
3. Code follows existing patterns
4. New features include tests and documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Last Updated**: 2026 | **Status**: Production Ready
