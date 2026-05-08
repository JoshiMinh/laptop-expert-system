# Prolog Streamlit Demo

This folder is a standalone Python + Prolog demo project.

## Prerequisites

You must have SWI-Prolog installed. Download from https://www.swi-prolog.org/Download.html.

To verify installation:
```bash
swipl --version
```

## Install

From inside `prolog/`:

```bash
pip install -r requirements.txt
```

## Run

```bash
streamlit run streamlit_app.py
```

The app will start a web UI on `http://localhost:8501`. From there, select your laptop requirements and run a consultation. The app calls the Prolog rules through `pyswip`.

## What it uses

- `advisor.pl` for the recommendation logic
- `db.pl` for the laptop facts
- `streamlit` for the UI (from pip)
- `pyswip` as the Python-to-Prolog bridge