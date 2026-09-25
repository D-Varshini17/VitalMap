$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
$adbPath = if ($adbCommand) { $adbCommand.Source } else { $null }
if (-not $adbPath) {
    foreach ($candidate in @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\Downloads\platform-tools\adb.exe",
        "$env:USERPROFILE\Downloads\platform-tools\platform-tools\adb.exe"
    )) {
        if (Test-Path -LiteralPath $candidate) { $adbPath = $candidate; break }
    }
}
if (-not $adbPath) { Write-Host 'ADB was not found. Install Android SDK platform-tools.'; exit 1 }
$devices = & $adbPath devices
$devices | Write-Host
$authorized = @($devices | Where-Object { $_ -match '^\S+\s+device$' })
if (-not $authorized.Count) {
    if ($devices -match '\sunauthorized$') {
        Write-Host 'Unlock phone and accept the USB debugging authorization popup.'
    } else {
        Write-Host 'No ready phone found. Connect USB, enable USB debugging, and check the cable.'
    }
    exit 1
}
if ($authorized.Count -gt 1) { Write-Host 'Connect only the phone you want to run VitalMap on.'; exit 1 }
$deviceId = ($authorized[0] -split '\s+')[0]
& (Join-Path $PSScriptRoot 'start_local_report_processor.ps1')
& $adbPath -s $deviceId reverse tcp:8000 tcp:8000
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not $env:JAVA_HOME -and (Test-Path 'C:\Program Files\Android\Android Studio\jbr\bin\java.exe')) {
    $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
}
Push-Location (Join-Path $projectRoot 'frontend')
try {
    & flutter run -d $deviceId --dart-define=VITALMAP_BACKEND_URL=http://127.0.0.1:8000
    $runExit = $LASTEXITCODE
} finally { Pop-Location }
exit $runExit
