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

## Docs

- [`docs/api-lo-endpoints.md`](docs/api-lo-endpoints.md) — CAP LO endpoints
- [`docs/store-launch-and-notifications-guide.md`](docs/store-launch-and-notifications-guide.md) — store + FCM later
- Portal: http://35.244.48.209/
- Swagger: http://35.244.48.209:8080/swagger-ui/index.html

LO: liaison@test.com · OTP 123456
Org: org@test.com · OTP 123456
Nodal: admin@aeroindia.gov.in · OTP 123456