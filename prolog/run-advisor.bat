@echo off
REM Run Prolog Advisor
REM This script starts SWI-Prolog and loads the advisor.pl file
REM You will be in interactive mode and can run queries like:
REM   ?- tu_van_top_k_giai_thich(gaming, 35000000, [mong_nhe], 3, TopK, CanhBao).

cd /d "%~dp0"

REM Check if swipl is in PATH
where swipl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: SWI-Prolog is not installed or not in PATH
    echo.
    echo Please install SWI-Prolog from: https://www.swi-prolog.org/Download.html
    echo.
    echo After installation:
    echo 1. Make sure 'swipl' is in your system PATH
    echo 2. Restart your terminal
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

swipl -l advisor.pl
pause
