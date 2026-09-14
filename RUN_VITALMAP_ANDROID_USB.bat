@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_android_usb.ps1"
exit /b %errorlevel%
