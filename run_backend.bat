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

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":8000 .*LISTENING"') do set "PORT_PID=%%P"
if defined PORT_PID (
  echo [ERROR] Port 8000 is already in use by PID %PORT_PID%.
  echo.
  tasklist /FI "PID eq %PORT_PID%"
  echo.
  echo Stop the old backend first with:
  echo taskkill /PID %PORT_PID% /F
  echo Then run this file again.
  pause
  exit /b 2
)

call ".venv\Scripts\activate.bat"
python --version
if errorlevel 1 goto fail

python -c "import fastapi, uvicorn, pypdf, pymupdf; print('Backend dependencies OK')"
if errorlevel 1 (
  echo [ERROR] Backend dependencies are missing.
  echo Run: pip install -r backend\requirements.txt
  goto fail
)

if not exist "backend\.env" copy "backend\.env.example" "backend\.env" >nul

echo.
echo Starting FastAPI on http://127.0.0.1:8000
echo Health:     http://127.0.0.1:8000/health
echo Tools:      http://127.0.0.1:8000/tools/status
echo AI Status:  http://127.0.0.1:8000/ai/status
echo Docs:       http://127.0.0.1:8000/docs
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
