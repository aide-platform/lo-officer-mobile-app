# Launch the LO mobile app in mock mode (no backend required).
# Repositories return in-memory data; good for UI work and offline demos.
#
# Usage:
#   .\scripts\run-mock.ps1                 # Chrome web
#   .\scripts\run-mock.ps1 -Device android

param(
    [string]$Device = "chrome",
    [int]$WebPort = 5555
)

$ErrorActionPreference = "Stop"

Write-Host "LO app → MOCK mode (no live backend)"
Write-Host "  Device = $Device"
Write-Host ""

if ($Device -eq "chrome") {
    & flutter run -d chrome --web-port=$WebPort --dart-define=USE_MOCK_API=true
} else {
    & flutter run -d $Device --dart-define=USE_MOCK_API=true
}
