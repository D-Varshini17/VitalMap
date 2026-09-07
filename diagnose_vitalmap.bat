@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title VitalMap Diagnostics

echo.
echo VitalMap Diagnostics
echo.

set PY=FAIL
set VENV=FAIL
set PIP=FAIL
set FASTAPI=FAIL
set UVICORN=FAIL
set OLLAMA=FAIL
set QWEN=FAIL
set OLLAMA_API=FAIL
set BACKEND=FAIL
set LOCAL_AI=FAIL
set FLUTTER=FAIL

if exist ".venv\Scripts\python.exe" (
  set "PY=OK"
  set "VENV=OK"
  set "PYTHON_CMD=.venv\Scripts\python.exe"
) else (
  where python >nul 2>nul && set "PY=OK" && set "PYTHON_CMD=python"
)

if "%VENV%"=="OK" (
  call ".venv\Scripts\activate.bat" >nul 2>nul
  python -m pip --version >nul 2>nul && set "PIP=OK"
  python -c "import fastapi" >nul 2>nul && set "FASTAPI=OK"
  python -c "import uvicorn" >nul 2>nul && set "UVICORN=OK"
)

where ollama >nul 2>nul && set "OLLAMA=OK"
if "%OLLAMA%"=="OK" ollama list | findstr /i "qwen3:1.7b" >nul && set "QWEN=OK"

powershell -NoProfile -Command "try { $s=Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3; if($s.models){ exit 0 } else { exit 0 } } catch { exit 1 }" >nul 2>nul && set "OLLAMA_API=OK" && set "OLLAMA=OK"
if "%OLLAMA_API%"=="OK" (
  curl.exe -s http://127.0.0.1:11434/api/tags | findstr /i "qwen3:1.7b" >nul && set "QWEN=OK"
)

powershell -NoProfile -Command "try { Invoke-RestMethod -Uri 'http://127.0.0.1:8000/health' -TimeoutSec 3 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>nul && set "BACKEND=OK"
powershell -NoProfile -Command "try { $s=Invoke-RestMethod -Uri 'http://127.0.0.1:8000/ai/status' -TimeoutSec 3; if($s.available -eq $true){ exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>nul && set "LOCAL_AI=OK"
where flutter >nul 2>nul && set "FLUTTER=OK"

call :print "Python" "%PY%"
call :print "Virtual Environment" "%VENV%"
call :print "pip" "%PIP%"
call :print "FastAPI" "%FASTAPI%"
call :print "Uvicorn" "%UVICORN%"
call :print "Ollama" "%OLLAMA%"
call :print "Qwen3 1.7B" "%QWEN%"
call :print "Ollama API" "%OLLAMA_API%"
call :print "Backend" "%BACKEND%"
call :print "Local AI" "%LOCAL_AI%"
call :print "Flutter" "%FLUTTER%"

echo.
if not "%PY%"=="OK" echo Fix Python: install Python 3.11 or newer.
if not "%VENV%"=="OK" echo Fix virtual environment: setup_windows.bat
if not "%FASTAPI%"=="OK" echo Fix FastAPI: .venv\Scripts\python -m pip install -r backend\requirements.txt
if not "%UVICORN%"=="OK" echo Fix Uvicorn: .venv\Scripts\python -m pip install -r backend\requirements.txt
if not "%OLLAMA%"=="OK" echo Fix Ollama: install Ollama from https://ollama.com/
if not "%QWEN%"=="OK" echo Fix model: ollama pull qwen3:1.7b
if not "%BACKEND%"=="OK" echo Fix backend: run_backend.bat
if not "%LOCAL_AI%"=="OK" echo Fix Local AI: start Ollama and run ollama pull qwen3:1.7b
if not "%FLUTTER%"=="OK" echo Fix Flutter: install Flutter and add it to PATH

echo.
if "%PY%%VENV%%FASTAPI%%UVICORN%%OLLAMA%%QWEN%%OLLAMA_API%%BACKEND%%LOCAL_AI%%FLUTTER%"=="OKOKOKOKOKOKOKOKOKOK" (
  echo VitalMap is ready.
) else (
  echo VitalMap diagnostics completed with items to fix above.
)
pause
exit /b 0

:print
set NAME=%~1
set STATUS=%~2
set PAD=                    
echo %NAME%%PAD:~0,20% %STATUS%
exit /b 0



