@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start_local_report_processor.ps1" -ConnectUsb
if errorlevel 1 (
  pause
  exit /b 1
)
start "" "https://vital-map-rose.vercel.app/?backendUrl=http://127.0.0.1:8000"
