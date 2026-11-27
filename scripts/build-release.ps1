# Build a release APK the way VAPT expects: HTTPS gateway only, Dart code
# obfuscated, symbol files kept for crash reports.
#
# Usage:
#   .\scripts\build-release.ps1 -Version 1.0.13             # GCP test gateway
#   .\scripts\build-release.ps1 -Version 1.0.13 -Target nic # NIC gateway
#
# Output:
#   releases\liaison-officer-<Version>[-nic].apk
#   build\symbols\<Version>[-nic]\   (keep it: needed to read crash traces;
#                                     upload with `firebase crashlytics:symbols:upload`)

param(
    [Parameter(Mandatory = $true)][string]$Version,
    [ValidateSet("gcp", "nic")][string]$Target = "gcp"
)

$ErrorActionPreference = "Stop"

$gateway = if ($Target -eq "nic") {
    "https://aeroindia.gov.in/api"
} else {
    "https://aeroindia.evenuefy.com/api"
}
$suffix = if ($Target -eq "nic") { "-nic" } else { "" }
$symbols = "build/symbols/$Version$suffix"

if (-not (Test-Path "android/key.properties")) {
    Write-Error "android/key.properties is missing. Release builds must be signed with the release keystore (VAPT LOA-01); ask the key holder for it."
    exit 1
}

& flutter build apk --release `
    --obfuscate `
    --split-debug-info=$symbols `
    --dart-define=USE_MOCK_API=false `
    --dart-define=API_GATEWAY_URL=$gateway `
    --dart-define=ENABLE_FCM=true
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

New-Item -ItemType Directory -Force releases | Out-Null
$out = "releases/liaison-officer-$Version$suffix.apk"
Copy-Item -Force build/app/outputs/flutter-apk/app-release.apk $out

Write-Host "APK:     $out"
Write-Host "Gateway: $gateway"
Write-Host "Symbols: $symbols"
