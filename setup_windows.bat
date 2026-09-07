@echo off
setlocal
cd /d "%~dp0"
title VitalMap Windows Setup

echo.
echo === VitalMap Windows Setup ===
echo.

where python >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Python was not found.
  echo Install Python 3.11 or newer, then run this script again.
  pause
  exit /b 1
)

python -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)"
if errorlevel 1 (
  echo [ERROR] Python 3.11 or newer is required.
  python --version
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  echo Creating .venv ...
  python -m venv .venv
  if errorlevel 1 goto fail
) else (
  echo Virtual environment OK
)

call ".venv\Scripts\activate.bat"
python -m pip install --upgrade pip
if errorlevel 1 goto fail
python -m pip install -r backend\requirements.txt
if errorlevel 1 goto fail

python -c "import fastapi, uvicorn; print('FastAPI OK'); print('Uvicorn OK')"
if errorlevel 1 goto fail

if not exist "backend\.env" (
  copy "backend\.env.example" "backend\.env" >nul
  echo Created backend\.env
)

where ollama >nul 2>nul
if errorlevel 1 (
  echo [WARN] Ollama was not found.
  echo Install Ollama, then run:
  echo ollama pull qwen3:1.7b
) else (
  echo Ollama OK
  ollama list | findstr /i "qwen3:1.7b" >nul
  if errorlevel 1 (
    echo [WARN] qwen3:1.7b is not installed.
    echo Run:
    echo ollama pull qwen3:1.7b
  ) else (
    echo Qwen3 1.7B OK
  )
)

echo.
echo Setup complete. Next run:
echo start_vitalmap.bat
pause
exit /b 0

:fail
echo.
echo Setup failed. Check the error above.
pause
exit /b 1
