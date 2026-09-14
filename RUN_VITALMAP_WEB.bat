@echo off
setlocal
cd /d "%~dp0"
title VitalMap Flutter Web

echo.
echo === VitalMap Web ===
echo.

powershell -NoProfile -Command "try { Invoke-RestMethod -Uri 'http://127.0.0.1:8000/health' -TimeoutSec 3 | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 (
  echo [ERROR] VitalMap backend is not running.
  echo Open another terminal and run: run_backend.bat
  pause
  exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter was not found on PATH.
  pause
  exit /b 1
)

cd frontend
flutter pub get
if errorlevel 1 goto fail

echo.
echo Starting at http://127.0.0.1:8080
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8080 --dart-define=VITALMAP_BACKEND_URL=http://127.0.0.1:8000
goto end

:fail
echo.
echo Flutter startup failed. Run CHECK_PROJECT.bat for diagnostics.
pause
exit /b 1

:end
endlocal
