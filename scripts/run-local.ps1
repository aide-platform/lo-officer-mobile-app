# Launch the LO mobile app against a locally-running aide-service on port 8080.
#
# Usage:
#   .\scripts\run-local.ps1                   # Chrome web → http://localhost:8080
#   .\scripts\run-local.ps1 -Device chrome
#   .\scripts\run-local.ps1 -Device android   # Android emulator → http://10.0.2.2:8080
#   .\scripts\run-local.ps1 -Device <serial>  # Physical device (requires adb reverse first)
#   .\scripts\run-local.ps1 -EnableFcm

param(
    [string]$Device = "chrome",
    [switch]$EnableFcm,
    [int]$WebPort = 5555
)

$ErrorActionPreference = "Stop"

# Emulator reaches host via 10.0.2.2; web + physical (adb reverse) hit localhost directly.
$baseUrl = if ($Device -eq "android") { "http://10.0.2.2:8080" } else { "http://localhost:8080" }
$fcm = if ($EnableFcm) { "true" } else { "false" }

$defines = @(
    "--dart-define=USE_MOCK_API=false",
    "--dart-define=API_BASE_URL=$baseUrl",
    "--dart-define=ENABLE_FCM=$fcm"
)

Write-Host "LO app → local aide-service"
Write-Host "  API_BASE_URL = $baseUrl"
Write-Host "  Device       = $Device"
Write-Host "  ENABLE_FCM   = $fcm"
Write-Host ""
Write-Host "Prereqs:"
Write-Host "  * aide-service running on localhost:8080"
Write-Host "  * Physical phone: adb reverse tcp:8080 tcp:8080"
Write-Host ""

if ($Device -eq "chrome") {
    & flutter run -d chrome --web-port=$WebPort @defines
} else {
    & flutter run -d $Device @defines
}
