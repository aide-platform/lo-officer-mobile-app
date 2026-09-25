# LO Committee Module — Requirements Matrix

Maps the Aero India LO Committee specification to the Flutter `liaison_officer` app and CAP APIs (`http://35.244.48.209:8080`).

**Branch:** `feature/lo-mobile-production` — LO CAP path first. Accommodation out of scope.

## Mobile information architecture

| Role | Bottom nav | Notes |
|------|------------|-------|
| **Nodal** | Home · Orgs · LOs · Ops · More | Catering / E-Coupons / Quota / Templates / Help under More |
| **Sub Nodal** | Same shell minus Catering + Sub Nodals roster | `AppRole.subNodalOfficer` |
| **Org Rep** | Overview · Nominations | Import / Remind / Sub Nodals / Help via overflow |
| **Liaison Officer** | Delegates · Tasks · Alerts | Profile + Help off avatar; issue report from detail/alerts; Travel/Movement sheets; CAP inbox + local alerts |

AppBar **bell** opens CAP `NotificationsInboxScreen` (`/app/notifications/mine`).

## LO mobile requirements (production branch)

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
| 10 | Issue reporting | **GAP** | `lo_issue_report_screen` + Hive | *none for LO create* | Conservancy `/app/cons-issues` is GET-only; issues saved locally pending CAP endpoint |
| 11 | Notifications | **DONE** | Alerts tab + CAP inbox | `/app/notifications/mine*` | Unify local alerts + CAP unread badge |

## Coverage matrix (committee LO.1–LO.9)

| ID | Requirement | Flutter | Live Dio | Notes |
|----|-------------|---------|----------|-------|
| LO.1 | OTP access | Login Step 1–2 | `/api/auth/*` | Aero branding |
| LO.2.1 | Org types | Orgs → Types sheet | `/app/lo-org-types` | Nodal |
| LO.2.2–2.3 | DO / email templates | More → Templates | template APIs | Nodal |
| LO.2.4 | Activity master | Ops → Tasks | `/app/lo-activities` | Nodal |
| LO.3 | Organisations + DO + nomination | Orgs hub | org + speculative DO | Soft-fail → local PDF |
| LO.4 | Org Rep nominate / import / team | Bottom nav | org-rep paths | — |
| LO.5 | LO profile | Profile | `/app/my-lo/me` | — |
| LO.6 | Review LOs | LOs → Profiles | `/app/liaison-officers` | Nodal |
| LO.7 | Badges + quota | LOs / More → Quota | `/app/committee/bv-quota/*` | — |
| LO.8 | Assign + tasks | Ops hub | assignments + tasks | Nodal |
| LO.9.1–9.2 | Delegates + travel | Delegate detail | delegates / travel | Accommodation SKIP |
| LO.9.3 | Task status + remarks | Tasks | task status PUT | — |
| LO.9.4 | Notifications | Alerts + inbox | `/app/notifications/mine*` | FCM follow-up |
| §15–16 | Catering + E-Coupons | More | catering / ecoupons | Nodal only — no redesign this branch |
| §17 | Sub Nodals | More | sub-nodal APIs | — |
| §18 | Dashboard | Home | aggregates | — |

## Live CAP seed / run

```bash
dart run scripts/seed_cap_lo.dart --email=<nodal-cap-email>

flutter run \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=http://35.244.48.209:8080
```

Mock: `USE_MOCK_API=true` · OTP `123456` · `liaison@test.com` / `org@test.com` / `admin@aeroindia.gov.in`

### UAT checklist (LO mobile)

1. OTP login (admin + LO from Users)
2. Delegates list → detail (profile / itinerary / transport / movement)
3. Tasks status update (online + offline queue)
4. Issue report saves locally with pending-sync banner
5. Alerts + CAP inbox unread badge
6. Theme toggle light/dark on LO shell
