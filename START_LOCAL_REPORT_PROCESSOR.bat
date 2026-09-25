@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start_local_report_processor.ps1" -ConnectUsb
if errorlevel 1 (
  echo Report processor setup failed. See the message above.
  pause
  exit /b 1
)
echo Ready. Return to VitalMap and select Extract report values again.
echo Keep this laptop running and the phone connected by USB.
pause
