# 💼 Prolog Laptop Expert System

A lightweight Streamlit app that leverages Prolog logic rules to provide intelligent laptop recommendations based on budget, workload, and user preferences.

---

## ✨ Features

- 🎯 **Interactive Consultation Form** – Define your needs, budget, and preferences through an intuitive sidebar interface
- 🔗 **Prolog Integration** – Harnesses powerful logical reasoning via `pyswip` for intelligent recommendations
- 📊 **Smart Ranking** – Returns a ranked Top-K list with confidence scores for each recommendation
- ⚙️ **Rule-Based Logic** – Applies sophisticated rules for budget fit, workload compatibility, brand preference, and conflict resolution
- 🔍 **Transparent Queries** – View the raw Prolog query for debugging and rule verification

---

## 🛠️ Requirements

| Component | Specification |
|-----------|---------------|
| **Python** | 3.11 or newer |
| **Prolog** | SWI-Prolog (installed and available on `PATH`) |
| **Environment** | Virtual environment recommended |

> **Tip:** Verify SWI-Prolog installation with `swipl --version`

---

## 🚀 Quick Start

### Step 1: Set Up Python Environment
```bash
python -m venv venv
.\venv\Scripts\Activate.ps1  # Windows PowerShell
# or: source venv/bin/activate  # macOS/Linux
```

### Step 2: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 3: Launch the App
```bash
streamlit run main.py
```

Open the local Streamlit URL displayed in your terminal (typically `http://localhost:8501`).

---

## 🎮 Alternative Launch Method

```bash
python main.py
```

The entrypoint automatically delegates to Streamlit if not already running inside the Streamlit runtime. This approach ensures predictable behavior on Windows and in terminal environments.

---

## 📋 How to Use

1. **Select a Workload** – Choose from Office, Programming, iOS Development, Graphics, Gaming, or AI/Data Science
2. **Set Your Budget** – Enter your budget in Vietnamese Dong (VND)
3. **Add Preferences** – Optionally select traits like lightweight design, battery life, or discrete GPU
4. **Choose a Brand** – Optional brand preference (Acer, Asus, Dell, Gigabyte, HP, Apple)
5. **Run Consultation** – Click the "Chạy tư vấn" button to fetch recommendations
6. **Review Results** – Browse the ranked laptop list and expand individual entries for details

---

## 📁 Project Structure

| File | Purpose |
|------|---------|
| `main.py` | Streamlit entrypoint and Prolog bridge |
| `laptop_advisor.pl` | Rule engine for recommendations |
| `laptop_database.pl` | Laptop fact database |
| `requirements.txt` | Python package dependencies |
| `.gitignore` | Git ignore rules |

### How the Components Interact

```
main.py (Streamlit UI)
    ↓
pyswip (Python-Prolog bridge)
    ↓
laptop_advisor.pl (applies rules)
    ↓
laptop_database.pl (queries facts)
```

---

## 📝 Notes

- **Language:** UI is in Vietnamese; the decision rules and sample data prioritize Vietnamese context
- **Local Execution:** The app runs entirely locally with no external API calls required
- **Confidence Scoring:** Scores combine budget fit and requirement satisfaction metrics
- **File Paths:** The app expects Prolog files in the repository root; update `main.py` if you relocate them
- **Rule Debugging:** Use the raw Prolog query viewer to understand how inputs are translated and applied

---

## 💡 Tips & Troubleshooting

- Ensure SWI-Prolog is installed and accessible from your terminal
- For Windows users: Run PowerShell as Administrator if you encounter execution policy issues
- Run the app from the repository root directory
- Check the raw query output if recommendations seem unexpected
