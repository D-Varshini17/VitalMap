@echo off
setlocal
cd /d "%~dp0"
title VitalMap Backend

echo.
echo === VitalMap Backend ===
echo Project: %CD%
echo.

if not exist ".venv\Scripts\python.exe" (
  echo [ERROR] Virtual environment not found: .venv
  echo Run setup_windows.bat first.
  pause
  exit /b 1
)

call ".venv\Scripts\activate.bat"
python --version
if errorlevel 1 goto fail

python -c "import fastapi, uvicorn; print('FastAPI and Uvicorn OK')"
if errorlevel 1 (
  echo [ERROR] Backend dependencies are missing.
  echo Run: pip install -r backend\requirements.txt
  goto fail
)

if not exist "backend\.env" (
  if exist "backend\.env.example" (
    copy "backend\.env.example" "backend\.env" >nul
    echo Created backend\.env from backend\.env.example
  )
)

echo.
echo Starting FastAPI on http://127.0.0.1:8000
echo Docs:      http://127.0.0.1:8000/docs
echo AI Status: http://127.0.0.1:8000/ai/status
echo Press CTRL+C to stop.
echo.
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
goto end

:fail
echo.
echo Backend startup failed.
pause
exit /b 1

:end
endlocal
