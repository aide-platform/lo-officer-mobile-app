# Liaison Officer release APK (1.0.1)

## Artifact

| File | Description |
|------|-------------|
| `liaison-officer-1.0.1.apk` | Signed release build targeting live CAP (`USE_MOCK_API=false`) |

Build command (from repo root, PowerShell):

```powershell
$env:NO_PROXY='35.244.48.209'
$env:GRADLE_USER_HOME='C:\Users\BSTC\.gradle'
flutter build apk --release `
  --dart-define=USE_MOCK_API=false `
  --dart-define=API_BASE_URL=http://35.244.48.209:8080

Copy-Item -Force `
  build\app\outputs\flutter-apk\app-release.apk `
  releases\liaison-officer-1.0.1.apk
```

Signing uses `android/key.properties` and `android/upload-keystore.jks` (gitignored, not in this repo).

### CI (when local Gradle is blocked by corporate proxy)

1. Open [Build release APK](https://github.com/aide-platform/lo-officer-mobile-app/actions/workflows/build-release-apk.yml) → **Run workflow** → branch `feature/lo-mobile-production`.
2. Download the `liaison-officer-1.0.1-apk` artifact when the run finishes.
3. Optionally commit it under `releases/liaison-officer-1.0.1.apk` for the testing team.

Local builds fail with **HTTP 407** if `%USERPROFILE%\.gradle\gradle.properties` proxy credentials are expired — update them or use a hotspot / CI.

## Install on Android

1. Copy `liaison-officer-1.0.1.apk` to the device (USB, email, MDM, etc.).
2. Open the file and allow **Install unknown apps** for your file manager or browser if prompted.
3. Complete installation and open **Liaison Officer**.

## Sign in (OTP)

1. Enter the **email** your Organisation Representative nominated for LO access.
2. Complete **CAPTCHA** on the login screen.
3. Request **OTP** — a one-time code is sent to that email.
4. Enter the OTP to sign in. There is no password flow for LO users.

**Mock / demo only:** OTP `123456` when running with `USE_MOCK_API=true`. This release is built for **live CAP**; use the OTP from your email.

Live LO account emails can be checked in CAP Admin → Users: http://35.244.48.209/

## Backend & network

| Setting | Value |
|---------|--------|
| CAP API base URL | `http://35.244.48.209:8080` |
| CAP web portal | http://35.244.48.209/ |
| Swagger | http://35.244.48.209:8080/swagger-ui/index.html |

**Corporate proxy:** On Windows, set `NO_PROXY=35.244.48.209` (or include that IP in your bypass list) so the app and Gradle can reach CAP without proxy authentication failures.

**HTTP cleartext:** CAP is currently HTTP-only. The Android app allowlists cleartext for `35.244.48.209` in `network_security_config.xml`. When CAP moves to HTTPS/TLS, ship a new APK with an updated base URL and network config.

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| Login / API errors | Device can reach `http://35.244.48.209:8080`; try portal in mobile browser |
| OTP not received | Spam folder; email matches CAP LO nomination |
| Install blocked | Enable unknown sources for the app used to open the APK |
| Gradle build fails with 407 | Update proxy credentials in `%USERPROFILE%\.gradle\gradle.properties` or build on an unrestricted network |
