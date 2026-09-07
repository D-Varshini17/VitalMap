@echo off
setlocal
cd /d "%~dp0"
title VitalMap Launcher

echo.
echo === Starting VitalMap Backend + Local AI ===
echo.

where ollama >nul 2>nul
if errorlevel 1 (
  echo [WARN] Ollama command not found. Backend will use fallback recommendations.
) else (
  powershell -NoProfile -Command "try { Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3 | Out-Null; exit 0 } catch { exit 1 }"
  if errorlevel 1 (
    echo [WARN] Ollama API is not responding at http://127.0.0.1:11434/api/tags
    echo Start Ollama, then verify: ollama list
  ) else (
    ollama list | findstr /i "qwen3:1.7b" >nul
    if errorlevel 1 (
      echo [WARN] qwen3:1.7b is missing. Run: ollama pull qwen3:1.7b
    ) else (
      echo Ollama and qwen3:1.7b OK
    )
  )
)

if not exist ".venv\Scripts\python.exe" (
  echo [ERROR] .venv missing. Run setup_windows.bat first.
  pause
  exit /b 1
)

start "VitalMap Backend" cmd /k "%~dp0run_backend.bat"

echo Waiting for backend health endpoint ...
powershell -NoProfile -Command "$ok=$false; for($i=0;$i -lt 30;$i++){ try { Invoke-RestMethod -Uri 'http://127.0.0.1:8000/health' -TimeoutSec 2 | Out-Null; $ok=$true; break } catch { Start-Sleep -Seconds 1 } }; if(-not $ok){ exit 1 }"
if errorlevel 1 (
  echo [ERROR] Backend health check did not pass.
  echo Check the VitalMap Backend window for details.
  pause
  exit /b 1
)

echo.
echo VitalMap backend running
echo FastAPI Docs:
echo http://127.0.0.1:8000/docs
echo.
echo AI Status:
echo http://127.0.0.1:8000/ai/status
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter was not found on PATH. Start Flutter manually after installing it.
) else (
  echo To launch Flutter Web, run:
  echo cd frontend
  echo flutter run -d chrome --dart-define=VITALMAP_BACKEND_URL=http://127.0.0.1:8000
)

pause
endlocal
