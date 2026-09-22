# Liaison Officer — Committee Automation Portal

Flutter client for the **LO Committee** module of Aero India Committee Automation Portal (CAP).

## Roles

| Role | Mock login email | Shell |
|------|------------------|-------|
| Liaison Officer | `liaison@test.com` | Delegates, Tasks, Travel, Alerts, Profile |
| Organisation Representative | `org@test.com` | Nominate LOs, reminders, bulk import |
| LO Committee Nodal Officer | `admin@aeroindia.gov.in` | Org types, orgs, templates, review, assign, tasks |

OTP (mock & CAP demo): **`123456`**

## Run

```bash
# Offline / mock (default)
flutter run --dart-define=USE_MOCK_API=true

# Live CAP API
export NO_PROXY=35.244.48.209   # corporate proxy bypass if needed
flutter run \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=http://35.244.48.209:8080
```

## Architecture

- Clean layers: `domain` contracts → `data` Dio/mock repos → `presentation` Bloc (ViewModel)
- DI: [`lib/core/di/app_dependencies.dart`](lib/core/di/app_dependencies.dart)
- CAP auth: CAPTCHA + Email OTP → JWT
- Design system: light/dark gradients, [`lib/core/widgets/app_ui_kit.dart`](lib/core/widgets/app_ui_kit.dart)
- Live entry: [`RoleHomeRouter`](lib/core/routing/role_home_router.dart) → role shells (not the orphaned SQLite `liaisonOfficerMain`)

## Feature coverage (LO.2–LO.9)

| Area | Shell | Notes |
|------|-------|-------|
| LO.2 masters | Nodal | Org types, DO/email templates, activities — edit/deactivate + PDF |
| LO.3 orgs | Nodal | Full org form; DO download/upload (5-item checklist); nomination send |
| LO.4 nominate | Org Rep | Excel/CSV import via `file_picker`, sub-nodal CRUD, read-only LO detail |
| LO.5 profile | LO Portal | Full CAP form, uploads, experiences, languages, submit status |
| LO.6–8 | Nodal | LO review filters/detail, bulk badges + quota, assign + task filters |
| LO.9 | LO Portal | Vehicles/nominations, connecting flights, alert lead minutes |

CAP OpenAPI has no LO-org DO letter / send-nomination paths — see [`docs/api-lo-endpoints.md`](docs/api-lo-endpoints.md). Mock uses `DoLetterLocalStore`; live calls fail soft on 404.

Packages: `image_picker`, `file_picker`, `path_provider`, `share_plus` for uploads/downloads.

## Docs

- [`docs/api-lo-endpoints.md`](docs/api-lo-endpoints.md) — CAP LO endpoints
- [`docs/store-launch-and-notifications-guide.md`](docs/store-launch-and-notifications-guide.md) — store + FCM later
- Portal: http://35.244.48.209/
- Swagger: http://35.244.48.209:8080/swagger-ui/index.html

LO: liaison@test.com · OTP 123456
Org: org@test.com · OTP 123456
Nodal: admin@aeroindia.gov.in · OTP 123456