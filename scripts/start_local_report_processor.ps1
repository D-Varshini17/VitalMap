param([switch]$ConnectUsb)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$logs = Join-Path $projectRoot 'artifacts'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
function Test-Processor {
    try {
        $health = Invoke-RestMethod 'http://127.0.0.1:8000/health' -TimeoutSec 3
        return ($health.status -eq 'ok' -and $health.service -eq 'VitalMap Backend')
    } catch { return $false }
}
if (-not (Test-Processor)) {
    $python = Join-Path $projectRoot '.venv\Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $python)) { throw 'Run setup_windows.bat first to install the local backend.' }
    $backend = Start-Process -FilePath $python -ArgumentList '-m','uvicorn','backend.app.main:app','--host','127.0.0.1','--port','8000' `
        -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $logs 'backend-runtime.log') `
        -RedirectStandardError (Join-Path $logs 'backend-runtime-error.log')
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        if (Test-Processor) { break }
        if ($backend.HasExited) { throw 'Backend could not start. See artifacts/backend-runtime-error.log.' }
        Start-Sleep -Seconds 1
    }
    if (-not (Test-Processor)) { throw 'Backend startup timed out. See artifacts/backend-runtime-error.log.' }
}
$status = Invoke-RestMethod 'http://127.0.0.1:8000/tools/report-status' -TimeoutSec 15
if (-not $status.image_ocr_available) { throw 'Restart the updated Windows backend to enable offline OCR.' }
Write-Host 'Report processor ready: offline OCR and PDF text reading. Ollama is not required.'
if ($ConnectUsb) {
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    $adbPath = if ($adb) { $adb.Source } else { Join-Path $env:LOCALAPPDATA 'Android\sdk\platform-tools\adb.exe' }
    if (Test-Path -LiteralPath $adbPath) {
        $devices = @(& $adbPath devices)
        $ready = @($devices | Where-Object { $_ -match '^\S+\s+device$' })
        foreach ($device in $ready) {
            $deviceId = ($device -split '\s+')[0]
            & $adbPath -s $deviceId reverse tcp:8000 tcp:8000
            if ($LASTEXITCODE -ne 0) { throw "USB forwarding failed for $deviceId." }
            Write-Host "USB report processor connected: $deviceId"
        }
        if (-not $ready.Count) { Write-Host 'Web is ready. For Android, connect/unlock the phone, allow USB debugging, then run this launcher again.' }
    } else { Write-Host 'Web is ready. Install Android SDK platform-tools to connect a phone over USB.' }
}
