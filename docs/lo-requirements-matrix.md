# Liaison Officer — Requirements Matrix

Maps Aero India Liaison Officer mobile requirements to the Flutter app and CAP APIs (`http://35.244.48.209:8080`).

**Branch:** `feature/lo-mobile-production` — Liaison Officer–only client (`LoPortalShell` + `/app/my-lo/me/**`). Accommodation out of scope.

## Mobile information architecture

| Role | Bottom nav | Notes |
|------|------------|-------|
| **Liaison Officer** | Delegates · Tasks · Alerts | Profile + Help + Theme off avatar; issue report from detail/alerts; Travel/Movement sheets; CAP inbox + local alerts |

AppBar **bell** opens CAP `NotificationsInboxScreen` (`/app/notifications/mine`).

## LO mobile requirements

| # | Functionality | Status | Flutter | CAP | Notes |
|---|---------------|--------|---------|-----|-------|
| 1 | Secure OTP login | **DONE** | `login_screen` + `AuthBloc` | `/api/auth/*` | CAPTCHA + email OTP → JWT |
| 2 | Assigned delegate list | **DONE** | `lo_delegates_screen` / shell tab | `GET /app/my-lo/me/delegates` | Pull-to-refresh, empty/skeleton |
| 3 | Delegate profile | **DONE** | `lo_delegate_detail_screen` | assignment payload | name, designation, org, country + CAP fields |
| 4 | Delegate itinerary | **DONE** | Itinerary timeline on detail | travel fields + `…/nominations` (+ vehicle pickup) | No dedicated itinerary API — composed read model |
| 5 | Transport assignment | **DONE** | Transport card on detail | `GET …/assignments/{id}/vehicles` | number, driver, pickup |
| 6 | Accommodation | **SKIP** | — | — | Struck through in LO requirements |
| 7 | Task list | **DONE** | `lo_tasks_screen` | `GET /app/my-lo/me/tasks` | Grouped by delegate |
| 8 | Task status update | **DONE** | status sheet + offline queue | `PUT …/tasks/{id}/status` | `LoOfflineStore` flush on load |
| 9 | Delegate movement | **DONE** | Movement sheet on detail | `PUT …/travel`, `PUT …/arrival-flight` | kinds: arrival / transfer / venue_entry / departure |
| 10 | Issue reporting | **DONE** | `lo_issue_report_screen` + Hive + Share | Speculative `POST /app/my-lo/me/issues` | Soft-fail → on-device; Share to escalate |
| 11 | Notifications | **DONE** | Alerts tab + CAP inbox | `/app/notifications/mine*` | Local alerts + CAP unread badge |

## Coverage (this app)

| ID | Requirement | Flutter | Live Dio | Notes |
|----|-------------|---------|----------|-------|
| LO.1 | OTP access | Login | `/api/auth/*` | Aero branding |
| LO.5 | LO profile | Profile | `/app/my-lo/me` | — |
| LO.9.1–9.2 | Delegates + travel | Delegate detail | delegates / travel | Accommodation SKIP |
| LO.9.3 | Task status + remarks | Tasks | task status PUT | — |
| LO.9.4 | Notifications | Alerts + inbox | `/app/notifications/mine*` | FCM follow-up |

## Run

```bash
flutter run \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=http://35.244.48.209:8080
```

Mock: `USE_MOCK_API=true` · OTP `123456` · `liaison@test.com`

### UAT checklist

1. OTP login
2. Delegates list → detail (profile / itinerary / transport / movement)
3. Tasks status update (online + offline queue)
4. Issue report → On device or Submitted; Share escalates
5. Alerts + CAP inbox unread badge
6. Theme toggle light/dark
7. My Profile + Help & Support from avatar menu
