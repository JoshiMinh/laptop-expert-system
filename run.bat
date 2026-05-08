@echo off
setlocal enabledelayedexpansion

rem Creates (if needed) and activates a virtualenv, installs deps, and runs the app.
rem Usage:
rem   run.bat
rem   run.bat install-only

set "SCRIPT_DIR=%~dp0"
set "VENV=%SCRIPT_DIR%.venv"

if not exist "%VENV%" (
    echo Creating virtual environment at "%VENV%"
    python -m venv "%VENV%"
    if errorlevel 1 exit /b 1
)

set "PYTHON_EXE=%VENV%\Scripts\python.exe"

if not exist "%PYTHON_EXE%" (
    echo Python executable not found in virtual environment.
    exit /b 1
)

echo Upgrading pip and installing requirements...
"%PYTHON_EXE%" -m pip install --upgrade pip
if errorlevel 1 exit /b 1

"%PYTHON_EXE%" -m pip install -r "%SCRIPT_DIR%requirements.txt"
if errorlevel 1 exit /b 1

if /i "%~1"=="install-only" (
    echo Installed dependencies. Exiting.
    exit /b 0
)

echo Starting Streamlit app (main.py)...
"%PYTHON_EXE%" -m streamlit run "%SCRIPT_DIR%main.py"
