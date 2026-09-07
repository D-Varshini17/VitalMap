@echo off
setlocal

set "WEB_URL=https://vital-map.vercel.app"

if "%~1"=="" (
  echo.
  echo Usage:
  echo   open_web_with_local_api.bat https://YOUR-HTTPS-BACKEND-URL
  echo.
  echo For the deployed Vercel web app, browsers require an HTTPS backend URL.
  echo Start the backend with start_vitalmap.bat, expose port 8000 through an HTTPS tunnel,
  echo then pass that tunnel URL here.
  echo.
  echo Example:
  echo   open_web_with_local_api.bat https://your-tunnel.example.com
  echo.
  pause
  exit /b 1
)

set "BACKEND_URL=%~1"
start "" "%WEB_URL%/?backendUrl=%BACKEND_URL%"
endlocal
