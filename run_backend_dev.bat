@echo off
setlocal
cd /d "%~dp0"
title VitalMap Backend Dev

echo.
echo === VitalMap Backend Dev Reload ===
echo.

if not exist ".venv\Scripts\python.exe" (
  echo [ERROR] Virtual environment not found: .venv
  echo Run setup_windows.bat first.
  pause
  exit /b 1
)

call ".venv\Scripts\activate.bat"
python -c "import fastapi, uvicorn; print('FastAPI and Uvicorn OK')"
if errorlevel 1 (
  echo [ERROR] Backend dependencies are missing.
  echo Run: pip install -r backend\requirements.txt
  pause
  exit /b 1
)

if not exist "backend\.env" if exist "backend\.env.example" copy "backend\.env.example" "backend\.env" >nul

echo Starting FastAPI dev server with reload.
python -m uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
if errorlevel 1 pause
endlocal
