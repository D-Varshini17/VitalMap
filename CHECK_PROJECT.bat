@echo off
setlocal
cd /d "%~dp0"
title VitalMap Project Check

echo === Backend syntax/tests ===
if exist ".venv\Scripts\python.exe" (
  call ".venv\Scripts\activate.bat"
  python -m compileall -q backend\app
  if errorlevel 1 goto fail
  python backend\test_unit.py
  if errorlevel 1 goto fail
  python backend\test_analyze.py
  if errorlevel 1 goto fail
) else (
  echo [WARN] .venv not found; skipping backend runtime test. Run setup_windows.bat.
)

echo.
echo === Flutter checks ===
where flutter >nul 2>nul
if errorlevel 1 (
  echo [WARN] Flutter not found on PATH; skipping Flutter checks.
  goto done
)
cd frontend
flutter pub get
if errorlevel 1 goto fail
flutter analyze
if errorlevel 1 goto fail
flutter test
if errorlevel 1 goto fail
cd ..

:done
echo.
echo VitalMap project checks completed.
pause
exit /b 0

:fail
echo.
echo [ERROR] A project check failed. Review the output above.
pause
exit /b 1
