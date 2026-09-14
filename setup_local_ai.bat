@echo off
setlocal
cd /d "%~dp0"
title VitalMap Local AI Setup

echo.
echo === VitalMap Local AI Setup ===
echo Uses Ollama only. No cloud AI API is configured.
echo.

where ollama >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Ollama was not found on PATH.
  echo Install Ollama first, then run this file again.
  pause
  exit /b 1
)

echo Pulling text guidance model...
ollama pull qwen3:1.7b
if errorlevel 1 goto fail

echo.
echo Pulling lab-report vision model...
ollama pull qwen2.5vl:3b
if errorlevel 1 goto fail

echo.
echo Installed models:
ollama list

echo.
echo Local AI setup complete.
echo Keep Ollama running while using report scanning or Local AI Guidance.
pause
exit /b 0

:fail
echo.
echo [ERROR] Model setup failed. Check the Ollama output above.
pause
exit /b 1
