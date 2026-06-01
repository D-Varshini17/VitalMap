$ErrorActionPreference = 'Stop'

$frontendRoot = $PSScriptRoot
$buildDirectory = Join-Path $frontendRoot 'build\web'
$deployDirectory = Join-Path $frontendRoot 'vercel-dist'

Push-Location $frontendRoot
try {
    flutter build web --release

    New-Item -ItemType Directory -Path $deployDirectory -Force | Out-Null
    & robocopy $buildDirectory $deployDirectory /MIR
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy failed with exit code $LASTEXITCODE"
    }

    $buildMarker = Join-Path $deployDirectory '.last_build_id'
    if (Test-Path $buildMarker) {
        Remove-Item -LiteralPath $buildMarker
    }
} finally {
    Pop-Location
}

Write-Host "Vercel export refreshed at $deployDirectory"
