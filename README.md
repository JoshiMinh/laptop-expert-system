# Prolog Laptop Expert — Streamlit demo

Simple demo combining Prolog rules with a Streamlit UI.

## Prerequisites

- SWI-Prolog (https://www.swi-prolog.org/Download.html)
	- Verify with `swipl --version`.

## Run manuals

### Option 1: One command via `run.bat`

Use this in PowerShell or `cmd.exe` on Windows:

```bat
run.bat
```

Install dependencies only:

```bat
run.bat install-only
```

### Option 2: Manual setup

Create a virtualenv and install dependencies:

```bash
python -m venv .venv
pip install -r requirements.txt
```

Run the app:

```bash
streamlit run main.py
```

Or launch it directly with Python:

```bash
python main.py
```

The app opens a UI on `http://localhost:8501` by default. Use the sidebar to select requirements and run the Prolog consultation.

## Windows notes

- `run.bat` works in both PowerShell and `cmd.exe`.
- `.sh` files are not runnable natively in PowerShell or `cmd.exe`; they need Bash, WSL, or Git Bash.

## Files

- `main.py` — Streamlit UI entrypoint (Python)
- `advisor.pl` — Prolog recommendation rules
- `db.pl` — Laptop facts
- `requirements.txt` — Python dependencies

## Notes

The Streamlit app uses `pyswip` to consult the top-level Prolog files in this repository.