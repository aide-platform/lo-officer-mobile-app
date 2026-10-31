# Launch the LO mobile app against the GCP-deployed aide-service.
# Mirrors aide-ui's `.env` (VITE_AIDE_SERVICE_URL = https://aeroindia.evenuefy.com/api/aideservices).
#
# Usage:
#   .\scripts\run-gcp.ps1                 # defaults to Chrome web
#   .\scripts\run-gcp.ps1 -Device chrome
#   .\scripts\run-gcp.ps1 -Device android # first attached emulator / device
#   .\scripts\run-gcp.ps1 -EnableFcm      # also light up FCM push

param(
    [string]$Device = "chrome",
    [switch]$EnableFcm,
    [int]$WebPort = 5555
)

$ErrorActionPreference = "Stop"

$gateway = "https://aeroindia.evenuefy.com/api"
$fcm = if ($EnableFcm) { "true" } else { "false" }

# Same gateway root aide-ui uses — see docs/app-decisions-log.md.
# aideServiceUrl / eventServiceUrl are derived from this inside ApiConfig.
$defines = @(
    "--dart-define=USE_MOCK_API=false",
    "--dart-define=API_GATEWAY_URL=$gateway",
    "--dart-define=ENABLE_FCM=$fcm"
)

Write-Host "LO app → GCP gateway"
Write-Host "  API_GATEWAY_URL = $gateway"
Write-Host "  Device       = $Device"
Write-Host "  ENABLE_FCM   = $fcm"
Write-Host ""

if ($Device -eq "chrome") {
    & flutter run -d chrome --web-port=$WebPort @defines
} else {
    & flutter run -d $Device @defines
}
