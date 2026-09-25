# Liaison Officer — CAP mobile client

Flutter client for **Liaison Officers** in the Aero India Committee Automation Portal (CAP).

**Branch focus:** `feature/lo-mobile-production` — LO-only path (`LoPortalShell` + `/app/my-lo/me/**`). Accommodation is out of scope.

## Role

| Role | Mock login email | Shell |
|------|------------------|-------|
| Liaison Officer | `liaison@test.com` | Delegates · Tasks · Alerts (+ profile, issues, notifications, Help, Theme) |

OTP (mock & CAP demo): **`123456`**

Live LO emails: Admin Login → Users page at http://35.244.48.209/

## Run

```bash
# Live CAP (recommended)
# Windows PowerShell:
$env:NO_PROXY='35.244.48.209'
flutter run `
  --dart-define=USE_MOCK_API=false `
  --dart-define=API_BASE_URL=http://35.244.48.209:8080

# Offline / mock UI
flutter run --dart-define=USE_MOCK_API=true
```

Release APK:

```bash
flutter build apk --release `
  --dart-define=USE_MOCK_API=false `
  --dart-define=API_BASE_URL=http://35.244.48.209:8080
```

Compile-time `USE_MOCK_API` defaults to `true` in code for safe offline tests; **docs for this branch default to `false`**.

## Architecture

- Clean layers: `domain` contracts → `data` Dio/mock repos → `presentation` Bloc
- DI: [`lib/core/di/app_dependencies.dart`](lib/core/di/app_dependencies.dart)
- CAP auth: CAPTCHA + Email OTP → JWT
- Live entry: [`RoleHomeRouter`](lib/core/routing/role_home_router.dart) → always `LoPortalShell`

## LO mobile requirements (1–11)

See [`docs/lo-requirements-matrix.md`](docs/lo-requirements-matrix.md).

| # | Functionality | Status |
|---|---------------|--------|
| 1 | Secure OTP login | DONE |
| 2–3 | Delegates + profile | DONE |
| 4 | Itinerary (travel + nominations timeline) | DONE (composed; no dedicated API) |
| 5 | Transport | DONE |
| 6 | Accommodation | SKIP |
| 7–8 | Tasks + status | DONE (offline queue) |
| 9 | Movement update | DONE (travel / arrival-flight wrappers) |
| 10 | Issue reporting | DONE (local durable + soft-fail CAP POST) |
| 11 | Notifications | DONE |

Supporting UX: My Profile, Help & Support, Theme toggle.

## Docs & portals

- [`docs/api-lo-endpoints.md`](docs/api-lo-endpoints.md) — CAP LO endpoints
- [`docs/store-launch-and-notifications-guide.md`](docs/store-launch-and-notifications-guide.md)
- Portal UI: http://35.244.48.209/
- Swagger: http://35.244.48.209:8080/swagger-ui/index.html

Mock: `liaison@test.com` · OTP `123456`
