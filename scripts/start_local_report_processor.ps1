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
try { Invoke-RestMethod 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3 | Out-Null }
catch {
    $ollama = Get-Command ollama -ErrorAction SilentlyContinue
    $ollamaPath = if ($ollama) { $ollama.Source } else { Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe' }
    if (-not (Test-Path -LiteralPath $ollamaPath)) { throw 'Install Ollama, then run setup_local_ai.bat.' }
    Start-Process -FilePath $ollamaPath -ArgumentList 'serve' -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $logs 'ollama-runtime.log') `
        -RedirectStandardError (Join-Path $logs 'ollama-runtime-error.log') | Out-Null
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
$status = Invoke-RestMethod 'http://127.0.0.1:8000/tools/status' -TimeoutSec 15
if (-not $status.text_model_installed -or -not $status.vision_model_installed) {
    throw 'Ollama models are not ready. Run setup_local_ai.bat to install qwen3:1.7b and qwen2.5vl:3b, then retry.'
}
Write-Host 'Local report processor ready: text and image models available.'
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
