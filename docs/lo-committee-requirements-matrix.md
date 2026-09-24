# LO Committee Module — Requirements Matrix (LO.1–LO.9 + manual §1–§18)

Maps the Aero India LO Committee specification to the Flutter `liaison_officer` app and CAP APIs (`http://35.244.48.209:8080`).

## Mobile information architecture (2026 redesign)

| Role | Bottom nav | Notes |
|------|------------|-------|
| **Nodal** | Home · Orgs · LOs · Ops · More | Org Types + Activity Master as pushed screens from More/Ops; Catering / E-Coupons / Quota / Templates / Help under More. Tablet: NavigationRail ≥600dp |
| **Sub Nodal** | Same shell minus Catering + Sub Nodals roster | Routed via `AppRole.subNodalOfficer` |
| **Org Rep** | Overview · Nominations | Import / Remind / Sub Nodals / Help via AppBar overflow; FAB nominate → sheet |
| **Liaison Officer** | Delegates · Tasks · Alerts | Profile + Help off avatar; first-login wizard; Travel/Task status = sheets; unread badge + deep-link |

AppBar **bell** opens `NotificationsInboxScreen` (`/app/notifications/mine`).

## Access Setup

| Spec | App / CAP | Notes |
|------|-----------|-------|
| Hospitality adds LO Committee Nodal | Outside app — CAP Users | Email OTP only |
| Nodal Sub Nodals | More → Sub Nodals | Two-level hierarchy |
| Org Rep / LO accounts | CAP Users required for OTP | Nomination creates LO records only |

## Coverage matrix

| ID | Requirement | Flutter | Live Dio | Notes |
|----|-------------|---------|----------|-------|
| LO.1 | OTP access | Login Step 1–2 | `/api/auth/*` | Aero branding |
| LO.2.1 | Org types | Orgs → Types sheet | `/app/lo-org-types` | Inline with Orgs |
| LO.2.2–2.3 | DO / email templates | More → Templates | template APIs | Plain-text body |
| LO.2.4 | Activity master | Ops → Tasks → Activity Master | `/app/lo-activities` | — |
| LO.3 | Organisations + DO + nomination | Orgs hub | org + speculative DO | Soft-fail → local PDF |
| LO.4 | Org Rep nominate / import / team | Bottom nav | org-rep paths | — |
| LO.5 | LO profile | Profile tab | `/app/my-lo/me` | — |
| LO.6 | Review LOs | LOs → Profiles | `/app/liaison-officers` | CRUD + remind/active + file preview |
| LO.7 | Badges + quota | LOs → Badges; More → Quota | `/app/committee/bv-quota/*` | `badgeLines` KPIs + parking when returned |
| LO.8 | Assign + tasks | Ops hub | assignments + tasks | — |
| LO.9.1–9.2 | Delegates + travel | Delegate detail | delegates / travel | Accommodation when CAP fields exist |
| LO.9.3 | Task status + remarks | Tasks dialog | task status PUT | — |
| LO.9.4 | Notifications | Alerts + inbox | `/app/notifications/mine*` | FCM killed-state follow-up |
| §15–16 | Catering + E-Coupons | More | catering / ecoupons APIs | QR uses `qrCodeData` |
| §17 | Sub Nodals | More | sub-nodal APIs | — |
| §18 | Dashboard | Home | aggregates + shortcuts | — |
| Help | Help & Support | More → Help | static | — |

## Follow-ups

- Production FCM (`ENABLE_FCM` + `google-services.json` / `GoogleService-Info.plist` + firebase packages)
- Optional client-side CSV share of filtered LO list (no CAP export endpoint)
- Auto-hide Catering / Sub Nodals for Sub Nodal JWT when role string is reliable

## Web ↔ mobile inventory

Full live-portal mapping: [`web-mobile-feature-inventory.md`](web-mobile-feature-inventory.md).

## Live CAP seed / run

```bash
dart run scripts/seed_cap_lo.dart --email=<nodal-cap-email>

flutter run \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=http://35.244.48.209:8080
```

Mock: `USE_MOCK_API=true` · OTP `123456` · `liaison@test.com` / `org@test.com` / `admin@aeroindia.gov.in`

### UAT checklist (manual §1–§18)

1. Nodal Home KPIs and shortcuts open Orgs / LOs / Ops / Quota  
2. Orgs: add org; open Organisation Types  
3. LOs: filter/review; Badges assign/download  
4. Ops: Assign LO↔delegate; Tasks + Activity Master  
5. More: Sub Nodals, Quota, Catering submit/distribute, E-Coupons PDF, Templates, Help, Notifications  
6. Org Rep: nominate, remind, import, team  
7. LO: Delegate detail (travel update), Tasks status+remarks, Alerts + inbox, Profile submit  
