$ErrorActionPreference = 'Stop'

$frontendRoot = $PSScriptRoot
$projectRoot = Split-Path $frontendRoot -Parent
$releaseDirectory = Join-Path $projectRoot 'releases'
$apiBaseUrl = 'https://vitalmap-backend.onrender.com'
$apkSource = Join-Path $frontendRoot 'build\app\outputs\flutter-apk\app-release.apk'
$apkDestination = Join-Path $releaseDirectory 'VitalMap-release-arm64.apk'

Push-Location $frontendRoot
try {
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter clean failed'
    }

    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter pub get failed'
    }

    dart run tools/pad_icon.dart
    if ($LASTEXITCODE -ne 0) {
        throw 'launcher icon padding failed'
    }

    dart run flutter_launcher_icons
    if ($LASTEXITCODE -ne 0) {
        throw 'launcher icon generation failed'
    }

    flutter clean
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter clean after icon generation failed'
    }

    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter pub get after icon generation failed'
    }

    flutter build apk --release --target-platform android-arm64 `
        --dart-define="API_BASE_URL=$apiBaseUrl"
    if ($LASTEXITCODE -ne 0) {
        throw 'Android release APK build failed'
    }

    New-Item -ItemType Directory -Path $releaseDirectory -Force | Out-Null
    Copy-Item -LiteralPath $apkSource -Destination $apkDestination -Force
} finally {
    Pop-Location
}

$apk = Get-Item -LiteralPath $apkDestination
$hash = Get-FileHash -LiteralPath $apkDestination -Algorithm SHA256
Write-Host "APK: $($apk.FullName)"
Write-Host "Size: $([math]::Round($apk.Length / 1MB, 2)) MB"
Write-Host "SHA256: $($hash.Hash)"
