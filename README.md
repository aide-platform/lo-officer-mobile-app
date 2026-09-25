# Liaison Officer — Committee Automation Portal

Flutter client for the **LO Committee** module of Aero India Committee Automation Portal (CAP).

**Branch focus:** `feature/lo-mobile-production` — LO-first hardening of the CAP path (`LoPortalShell` + `/app/my-lo/me/**`). Accommodation is out of scope. Multi-role routing (LO / Org Rep / Nodal) remains.

## Roles

| Role | Mock login email | Shell |
|------|------------------|-------|
| Liaison Officer | `liaison@test.com` | Delegates · Tasks · Alerts (+ profile, issues, notifications) |
| Organisation Representative | `org@test.com` | Nominate LOs, reminders, bulk import |
| LO Committee Nodal Officer | `admin@aeroindia.gov.in` | Org types, orgs, templates, review, assign, tasks |

OTP (mock & CAP demo): **`123456`**

Live LO emails: Admin Login → Users page at http://35.244.48.209/

## Run (live CAP is the default for this branch)

```bash
# Production / UAT against live CAP (recommended)
# Windows PowerShell:
$env:NO_PROXY='35.244.48.209'
flutter run `
  --dart-define=USE_MOCK_API=false `
  --dart-define=API_BASE_URL=http://35.244.48.209:8080

# Offline unit tests / mock UI
flutter run --dart-define=USE_MOCK_API=true
```

Release APK:

```bash
flutter build apk --release `
  --dart-define=USE_MOCK_API=false `
  --dart-define=API_BASE_URL=http://35.244.48.209:8080
# Output copied to releases/liaison-officer-release.apk
```

Compile-time `USE_MOCK_API` defaults to `true` in code for safe offline tests; **docs and scripts for this branch default to `false`**.

## Architecture

- Clean layers: `domain` contracts → `data` Dio/mock repos → `presentation` Bloc (ViewModel)
- MVVM-style: Screens = View; Bloc state = ViewModel; repositories = Model
- DI: [`lib/core/di/app_dependencies.dart`](lib/core/di/app_dependencies.dart)
- CAP auth: CAPTCHA + Email OTP → JWT
- UX kit: [`mobile_ux_kit.dart`](lib/core/widgets/mobile_ux_kit.dart), [`app_motion.dart`](lib/core/widgets/app_motion.dart), [`app_ui_kit.dart`](lib/core/widgets/app_ui_kit.dart)
- Themes: [`ThemeCubit`](lib/core/themes/presentation/bloc/theme_cubit.dart) light/dark + palettes
- Live entry: [`RoleHomeRouter`](lib/core/routing/role_home_router.dart) → role shells (not orphaned SQLite `liaisonOfficerMain`)

## LO mobile requirements (1–11)

See [`docs/lo-committee-requirements-matrix.md`](docs/lo-committee-requirements-matrix.md).

| # | Functionality | Status |
|---|---------------|--------|
| 1 | Secure OTP login | DONE |
| 2–3 | Delegates + profile | DONE |
| 4 | Itinerary (travel + nominations timeline) | DONE (composed; no dedicated API) |
| 5 | Transport | DONE |
| 6 | Accommodation | SKIP |
| 7–8 | Tasks + status | DONE (offline queue) |
| 9 | Movement update | DONE (travel / arrival-flight wrappers) |
| 10 | Issue reporting | GAP (local Hive; no LO CAP write) |
| 11 | Notifications | DONE |

## Docs & portals

- [`docs/api-lo-endpoints.md`](docs/api-lo-endpoints.md) — CAP LO endpoints
- [`docs/store-launch-and-notifications-guide.md`](docs/store-launch-and-notifications-guide.md)
- Portal UI: http://35.244.48.209/
- Swagger: http://35.244.48.209:8080/swagger-ui/index.html

Mock: `liaison@test.com` / `org@test.com` / `admin@aeroindia.gov.in` · OTP `123456`
