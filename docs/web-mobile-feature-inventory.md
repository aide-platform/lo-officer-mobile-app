# CAP Web ↔ Mobile LO App — Feature Inventory

Live portal: `http://35.244.48.209/` · API: `http://35.244.48.209:8080`  
Validated login: `rohit@aeroindia.gov.in` (CAPTCHA + OTP `123456`) → JWT role **NODAL_OFFICER**.

Hospitality & Protocol Nodal account provisioning remains **out of scope**.

## Role shells (web SPA → mobile IA)

| Web route family | Web surface | Mobile shell | Nav |
|------------------|-------------|--------------|-----|
| `/lo-nodal/*` | Sidebar: Dashboard, Orgs, LOs, Assign, Tasks, Masters, Catering, E-Coupons, Quota, Templates, Sub Nodals, Help | `NodalOfficerShell` | Bottom: Home · Orgs · LOs · Ops · More (+ tablet rail) |
| Sub-nodal JWT | Same minus Catering / Sub Nodals roster | `NodalOfficerShell(isSubNodal: true)` | Same reduced set |
| `/org-rep/*` | Nominate / Import / Team | `OrgRepShell` | Overview · Nominations; overflow Import / Remind / Sub Nodals / Help; FAB nominate |
| `/lo-portal/*` | Delegates, Tasks, Profile, Alerts | `LoPortalShell` | Delegates · Tasks · Alerts; Profile/Help off avatar |

## Feature parity matrix

| Web / CAP capability | Mobile | Status |
|----------------------|--------|--------|
| Email OTP + CAPTCHA | Login Step 1–2 | Done |
| Dashboard KPIs / shortcuts | Home hub | Done (9 KPIs; donut charts for profile/assignment/task; bar charts for orgs; type/org rollups; Delegate Coverage) |
| Org types CRUD + active | Orgs → Organisation Types screen | Done (name + technical code + description) |
| Organisations + DO preview / signed upload / nomination | Orgs hub | Done (4 KPIs: Organisations / LOs Nominated / Profiles Submitted / Types Represented) |
| Delete organisation | Orgs overflow | Done |
| Email + DO letter templates | More → Templates | Done (email body HTML + insert chips) |
| Activity master | Ops → Tasks → Activity Master | Done |
| LO review filters (org / type / status / language / availability) | LOs → Profiles filter chips + sheet | Done (languages from LO data; Active/Inactive + designation + mobile on cards) |
| LO hub stats (Total / Prior Experience / Active) | LOs hub strip above Profiles/Badges | Done |
| Add / edit / delete LO (nodal) | Add LO + overflow Edit/Delete | Done |
| LO detail (profile, languages, experience) | Profile sheet | Done |
| LO document preview (`/app/files/{id}`) | Detail → Documents chips | Done |
| Send LO reminder / remind pending incomplete | LO card overflow + **Remind pending** | Done |
| Set LO active / inactive | Overflow + detail actions | Done |
| Badge assign / download + BV quota | LOs → Badges (category pick + long-press); More → Quota | Done |
| Assign LO ↔ delegate (delegate-first) | Ops → Assign (calendars + filters; On screen/With LO/Unassigned KPIs; Assign N CTA + workload) | Done |
| Tasks CRUD / status / filters / delete | Ops → Tasks (+ KPI strip; LO→Delegate cascade) | Done |
| Catering requirements submit / distribute | More → Catering | Done (KPI strip; meal/date pickers; recipient distribute) |
| E-Coupons list + QR (`qrCodeData`) + PDF | More → E-Coupons | Done (APPROVED/DISTRIBUTED/AVAILABLE + My Committee's Quota + search) |
| Sub Nodal officers | More → Sub Nodals (search, Active toggle, designation, Role/Scope canApprove) | Done (Nodal only) |
| In-app notifications | AppBar bell + Alerts | Done |
| Help & Support | More / avatar | Done (Quick Overview + Contents §§1–18 + Download user manual) |
| Settings (color themes + font size) | Drawer → Settings | Done (8 palettes + S/M/L + light/dark; persisted) |
| Org Rep nominate / re-nominate / remind / import / team | OrgRepShell | Done + smoked (rank/designation on nominate; Team Active + designation; template wait-before-share) |
| LO profile wizard + delegates + travel + tasks | LoPortalShell | Done + smoked (Profile badge download; offline cache soft banner; travel from delegate detail) |
| Offline mutation queue + flush | Hive queue + replay on load | Done (task status only) |
| Offline list hydrate | Cache banner on load failure | Done |
| FCM killed-state push | Stub until Firebase configs + `ENABLE_FCM` | Stub / ready path |
| Filtered LO list PDF export | No CAP endpoint | Out of scope |
| Connecting flights on travel save | LO Portal travel editor | Known limit — CAP `updateTravel` strips connecting legs; not persisted server-side |

## Live API paths

- `GET/POST /app/liaison-officers`, `PUT/DELETE /app/liaison-officers/{id}`
- `POST …/reminder`, `POST …/reminders/pending`, `PUT …/active`
- `GET /app/files/{id}` for document preview
- `DELETE /app/lo-organisations/{id}`
- `GET /app/committee/bv-quota/mine` → `badgeLines` / `vehiclePassLines`

## UX note

Mobile does **not** clone the web sidebar/tables. Same capabilities use bottom nav, sheets, cards, FABs, and overflow menus per the mobile UX plan.
