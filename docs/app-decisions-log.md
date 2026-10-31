# LO Mobile App — Decisions & Change Log

A running log of every meaningful change made to `lo-officer-mobile-app`, with the reasoning behind each decision. The document is append-only — new entries go at the top of the **Change Log** section, older entries stay as the historical record.

Audience:

- The engineering team working on this repo day-to-day.
- The ops team that will later deploy aide-service + aide-ui + this app on the **NIC server**. The GCP deployment is a staging mirror; the NIC rollout must be able to re-create the same wiring from this document alone.

---

## 1. Overview

- **App name:** Liaison Officer portal (Flutter 3.47.8 / Dart 3.13.7).
- **Target platforms:** Android (primary), iOS, Web (Chrome used for dev + verification).
- **Backend:** `aide-service` (Spring Boot 3.5.6). Mirrors the aide-ui client; the mobile app and aide-ui share the same base URL.
- **State management:** `flutter_bloc` with `LoPortalBloc` / `AuthBloc`.
- **HTTP:** `dio` with `BrowserHttpClientAdapter` on web.
- **Secure storage:** `flutter_secure_storage` + Hive for offline cache.
- **Push + analytics:** Firebase (Messaging, Crashlytics, Analytics, Performance) via FlutterFire.

---

## 2. Environments

The app uses compile-time flags (`--dart-define`) to switch backends. Values bake in at build; a hot reload does **not** pick them up — a full Stop → Run is required.

Two shapes of flag:

- **Gateway form** (preferred, matches aide-ui's `serviceUrls.ts`): pass `API_GATEWAY_URL=...` and let `ApiConfig` derive `aideServiceUrl` = `${gateway}/aideservices` and `eventServiceUrl` = `${gateway}/eventservices`.
- **Legacy single-service form**: pass `API_BASE_URL=...` to pin aide-service directly. Still honoured for local dev where aide-service runs standalone on port 8080 without a `/aideservices` subpath.

| Environment | Flag                                                                                    | `USE_MOCK_API` | Notes |
|-------------|-----------------------------------------------------------------------------------------|----------------|-------|
| Mock        | — (ignored)                                                                             | `true`         | In-memory repositories, used for UI work and offline demos. |
| Local       | `API_BASE_URL=http://localhost:8080` (web) / `http://10.0.2.2:8080` (Android emulator) / `http://localhost:8080` + `adb reverse` (physical device) | `false`        | Standalone Spring Boot on 8080. Gateway form does not apply here. |
| GCP staging | `API_GATEWAY_URL=https://aeroindia.evenuefy.com/api`                                    | `false`        | Mirrors aide-ui `.env` → `VITE_API_BASE_URL`. aide-service + event-services both derived. |
| NIC (future)| `API_GATEWAY_URL=https://<nic-host>/api`                                                | `false`        | To be filled in when the NIC server is provisioned. |

Convenience launch wrappers:

- `scripts/run-mock.ps1`
- `scripts/run-local.ps1 [-Device chrome|android|<serial>]`
- `scripts/run-gcp.ps1 [-Device chrome|android|<serial>] [-EnableFcm]`

When NIC comes online, add `scripts/run-nic.ps1` by copying `run-gcp.ps1` and swapping the base URL.

---

## 3. Change Log

Each entry follows the same shape:

```
### YYYY-MM-DD — <short title>
**What changed:** bullet list of concrete edits (files, scripts, config).
**Why:** the problem being solved and the trade-off chosen.
**Impact for deployment:** anything NIC rollout needs to know.
```

### 2026-10-29 — Split ApiConfig into gateway + per-service URLs

**What changed**

- `lib/core/config/api_config.dart`
  - New `apiGatewayUrl` (dart-define `API_GATEWAY_URL`, default `https://aeroindia.evenuefy.com/api`).
  - New `aideServiceUrl` getter — resolves to `$apiGatewayUrl/aideservices` unless `--dart-define=AIDE_SERVICE_URL=...` overrides it.
  - New `eventServiceUrl` getter — resolves to `$apiGatewayUrl/eventservices` unless `--dart-define=EVENT_SERVICE_URL=...` overrides it.
  - `baseUrl` is now a getter. It prefers the legacy `--dart-define=API_BASE_URL=...` when supplied, otherwise returns `aideServiceUrl`. Old run configs keep working with no edit.
- `scripts/run-gcp.ps1` — switched from `API_BASE_URL` to `API_GATEWAY_URL`, so the aide-service and event-services URLs stay in sync when the gateway host changes (e.g. moving to NIC).

**Why**

- aide-ui's `services/serviceUrls.ts` fans one gateway root into `AIDE_SERVICE_URL`, `EVENT_SERVICE_URL`, `PRODUCT_SERVICE_URL`, `EXHIBITOR_EVENT_SERVICE_URL`. The LO app currently only calls aide-service, but keeping the shape identical means a future feature (e.g. aircraft registration lives on event-services per `fsdApi.ts` line 576) can add a Dio client against `ApiConfig.eventServiceUrl` instead of inventing a second config class.
- Legacy `API_BASE_URL` is preserved as an override so no existing teammate's Android Studio run config breaks on this pull.
- `baseUrl` becoming a getter (not a `const`) is fine — both call sites (`DioProvider` and the login screen footer) read it at runtime.

**Impact for deployment**

- NIC rollout: set `--dart-define=API_GATEWAY_URL=https://<nic-host>/api` once; aide-service and event-services both inherit.
- Local dev unchanged: `scripts/run-local.ps1` still passes `API_BASE_URL=http://localhost:8080` because aide-service runs standalone on port 8080 without a `/aideservices` prefix. The legacy override path exists for exactly this case.

---

### 2026-10-29 — Fix duplicate "Upcoming task" alerts + add "New task assigned" alert

**What changed**

- `lib/features/liaison_officer/data/cache/lo_portal_cache.dart`
  - `pushAlert` now takes an optional `dedupeKey`. When the key already exists in the saved alert list, the new row is dropped.
  - `loadAlerts` dedupes by `key` at read time, so alerts persisted before this change (which carried no key) also collapse to the newest entry.
- `lib/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart` (`_onLoad`)
  - "Upcoming task" alert now carries `dedupeKey: 'task-reminder:<taskId>'`, so one row per task across all refreshes.
  - Added a `previousTaskIds` diff against the cached task list. Each task whose id did not exist in the previous snapshot gets a `dedupeKey: 'task-new:<taskId>'` alert titled "New task assigned". The diff is only applied when the previous cache is non-empty, so a fresh install does not flood the Alerts tab with historical tasks on first login.

**Why**

- Reproduction: assigning one task from aide-ui showed up four times in the mobile Alerts tab. `_onLoad` was looping every task on every refresh and calling `pushAlert` with no de-dup, so each pull-to-refresh appended another copy.
- Dedupe by stable key is simpler than per-call existence checks at every call site, and it survives SharedPreferences round-trips.
- The `previousTaskIds` guard is important: without it, a fresh install (empty cache) would still produce one "new task" alert per existing task, which is noisy and misleading because those tasks are not actually new to the server.

**Impact for deployment**

- Pure client-side fix. No schema change.
- The Alerts tab is still a **local** feed built from refresh events. It is **not** a push notification. Real push on task-assignment requires:
  1. Client built with `--dart-define=ENABLE_FCM=true`.
  2. Device token successfully posted to aide-service via `POST /api/devices/register` (handler is `FcmDeviceRegistrar`; endpoint is `TASK-B-01` on `engineering-todo.md` if the server route is still 404).
  3. aide-service calling Firebase Admin SDK on task-assign write (not yet implemented server-side).
  Without all three, mobile only ever sees new tasks on the next refresh — same behaviour aide-ui gives on the web.

---

### 2026-10-29 — Delegate action icons parity with aide-ui

**What changed**

- New file `lib/features/liaison_officer/presentation/screens/lo/lo_delegate_sheets.dart` exposing three modal bottom-sheet openers:
  - `openDelegateViewSheet` — Eye icon: read-only profile fields + family table + Email/Call/WhatsApp actions.
  - `openDelegateNominationsSheet` — Calendar icon: event nominations table (Event Name / Date / Time / Venue).
  - `openDelegateVehiclesSheet` — Car icon: vehicle allocations table (Category / Type / Number / Driver Name / Driver Contact / Remarks) plus a "Call driver" button per allocation.
- `lib/features/liaison_officer/presentation/screens/lo/lo_delegates_screen.dart`
  - Card icons now route to the three new sheets instead of pushing the same long detail screen with a scroll target.
  - Tapping the card body still opens `LoDelegateDetailScreen` (the full combined view) via a new `onOpenFullProfile` callback — keeps the "give me everything on one page" affordance.
  - Plane icon unchanged — still opens `LoTravelEditor` (writes).

**Why**

- The user reported that the four action icons on the delegates list all opened the same screen, which is not how aide-ui behaves. aide-ui's `MyLoDelegatesPage` fires four distinct dialogs (`viewFor`, `nomFor`, `vehFor`, `travelFor`). Each icon should land on a focused surface, not a scroll position in a long list.
- Mobile-idiomatic equivalent of a web dialog is a modal bottom sheet with a drag handle. `DraggableScrollableSheet` lets the LO pull it up / dismiss with a swipe without hunting for the close button.
- Column shape of each sheet mirrors the aide-ui table exactly (same labels, same order) so the two clients stay in lockstep when columns are added or renamed on either side.
- `LoPortalDelegateExtrasRequested` is dispatched by the sheet opener itself, which means the sheet renders empty for a moment and then fills in — same behaviour as aide-ui's `useEffect` fetch inside the dialog.

**Impact for deployment**

- No new endpoints — reuses `GET /app/my-lo/me/assignments/{id}/nominations` and `GET /app/my-lo/me/assignments/{id}/vehicles`, which already serve aide-ui.
- No change to the full `LoDelegateDetailScreen`; it remains the canonical "everything about this delegate" page for whoever prefers scroll-through over sheet-hop.

---

### 2026-10-29 — Wire LO app to GCP-deployed aide-service

**What changed**

- `lib/core/config/api_config.dart`
  - Default `API_BASE_URL` moved from the dead `http://34.47.128.151:6080` to the GCP URL `https://aeroindia.evenuefy.com/api/aideservices`.
  - Added a doc block listing all known base URLs (local / emulator / GCP) and pointing at the launch scripts.
- `scripts/run-gcp.ps1`, `scripts/run-local.ps1`, `scripts/run-mock.ps1` — three PowerShell wrappers that pass the right `--dart-define` combination to `flutter run`.

**Why**

- aide-ui already runs against the GCP deployment through its `.env`. Mirroring that URL in the mobile app keeps both clients pointed at the same backend and the same test data, which removes a whole class of "works on web, broken on mobile" bugs.
- Picking a safe default (GCP, which responds) over the previous dead IP means a fresh clone no longer fails with a connection timeout before anyone has set anything up.
- `USE_MOCK_API` default stays `true` so a clean clone still boots without a backend. The switch to live is an explicit flag, not an accidental one.
- Scripts live outside `lib/` because they are developer ergonomics, not shipped code. They are the Flutter equivalent of aide-ui's `.env.development` / `.env.production` split — a single reproducible invocation per environment.

**Impact for deployment**

- When NIC is live, copy `scripts/run-gcp.ps1` to `scripts/run-nic.ps1` and update `$baseUrl`.
- Build the APK for NIC with: `flutter build apk --release --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://<nic-host>/api/aideservices --dart-define=ENABLE_FCM=true`.
- The default in `api_config.dart` can be updated to the NIC URL at that point if NIC becomes the primary target — the GCP URL then moves into `scripts/run-gcp.ps1` only.

---

### 2026-10-29 — Integrate Firebase (project `aero-lo-app`)

**What changed**

- Ran FlutterFire CLI against the `aero-lo-app` Firebase project. Generated:
  - `lib/firebase_options.dart` (Web + Android + iOS options).
  - `android/app/google-services.json` (overwrites the previous `lo-mobile-app` project config, which was backed up to `android/app/google-services.lo-mobile-app.bak.json`).
- `lib/main.dart`
  - Calls `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` on startup.
  - Starts `LoFirebaseMonitor.instance.start()` immediately after, so Crashlytics / Analytics / Performance run on every launch.
- `lib/core/services/push_notification_service.dart`
  - Removed the redundant `Firebase.initializeApp()` call from the FCM init path.
  - Background isolate handler (`loFirebaseBackgroundHandler`) now passes `options: DefaultFirebaseOptions.currentPlatform` — required for the Web and iOS targets.
- `pubspec.yaml` — unchanged (`firebase_core` / `firebase_messaging` / `firebase_crashlytics` / `firebase_analytics` / `firebase_performance` already present).

**Why**

- The previous project (`lo-mobile-app`, 813770238672) belonged to a different Google account. The client-owned project is `aero-lo-app`; shipping on the wrong project would send crash reports and tokens to an inbox nobody monitors.
- Decoupling Crashlytics / Analytics / Performance from the FCM feature flag means we get crash reporting even in builds where push is intentionally off. Previously `LoFirebaseMonitor.start()` only ran inside the FCM gate.
- `main.dart` wraps both the Firebase init and the monitor start in a `try/catch` that logs and continues. Firebase outages must never block the LO portal from opening — the officers rely on it for live event ops.
- The background isolate explicitly needs `DefaultFirebaseOptions.currentPlatform`; a bare `Firebase.initializeApp()` works on Android (reads `google-services.json`) but silently fails on Web and iOS.

**Impact for deployment**

- NIC deployment uses the same Firebase project — `aero-lo-app` is Google-hosted and does not change between environments. The APK carries its own `google-services.json`, so NIC does not need to serve any Firebase assets.
- If a future environment switches Firebase projects, re-run `flutterfire configure --project=<new-id>` and commit the regenerated `firebase_options.dart` + `google-services.json`.
- Push notifications stay feature-gated behind `--dart-define=ENABLE_FCM=true`. Flip to true in the NIC release build when the server-side token sender is live.

---

### 2026-10-29 — Fix Gender dropdown validation + ListTile ink warnings

**What changed**

- Added a backend-driven gender lookup: new `LoGenderOption` model, new `/app/lookups/genders` path (`ApiConfig.lookupGendersPath`), new `listGenderLookups()` on both the Dio and mock `LoPortalRepository`, new `LoPortalGenderLookupsRequested` event, new `genderOptions` field on `LoPortalState`, and a handler in `LoPortalBloc` that short-circuits when options are already cached.
- `lib/features/liaison_officer/presentation/screens/lo/lo_profile_screen.dart`
  - Dispatches `LoPortalGenderLookupsRequested` from `initState`.
  - Dropdown rebuilt inside a `Builder` that reads `state.genderOptions` and derives both the displayed items and the stored id directly from the backend lookup; disables selection while options load.
  - DOB and Experience `ListTile`s wrapped in `Material(type: MaterialType.transparency)` to silence the "No Material widget ancestor" assertion.
- `lib/features/liaison_officer/presentation/screens/lo/lo_helplines_screen.dart`
  - Phone-number `Text` inside the row chip wrapped in `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))` to prevent the 25 px `RenderFlex` overflow on narrow screens.

**Why**

- Original bug: a new LO who had not completed onboarding always saw "Gender is required" even after picking a value. Root cause — the local `_genderIdByName` map was only populated from a loaded profile, so for a brand-new LO the dropdown's `onChanged` always wrote `null` into `_genderId`.
- Hard-coded gender lists are a liability for a government-adjacent app — the backend already exposes a lookup table so admins can change the set without a release. Reusing the existing languages-lookup pattern keeps the state machine small and testable.
- `Material(type: transparency)` is the Flutter-recommended fix for the ink-splash assertion when a `ListTile` sits inside a non-Material parent like a plain `Container` or `ListView`.
- `Flexible` + `ellipsis` is the standard container response to an unbounded `Text` in a `Row` — the alternative (`SingleChildScrollView`) scrolls horizontally and looks broken in a card.

**Impact for deployment**

- `/app/lookups/genders` must be reachable on every environment the mobile app connects to. Confirmed present on local aide-service and on GCP; verify once NIC is up.
- No schema changes; this is pure client wiring over an existing endpoint.

---

### 2026-10-28 — End-to-end audit against local aide-service

**What changed**

- Produced two review documents:
  - `docs/pending-tasks-handover.md` — client-facing status (blockers, high / medium / low items, what's done, owner + next-action table, build-and-run reference).
  - `docs/engineering-todo.md` — team-facing TODO (17 tasks tagged `TASK-M-01..15` for mobile, `TASK-B-01..04` for backend, each with owner / status / estimate / problem / files-touched / acceptance / dependencies).
- Verified against two real accounts: `uma@gmail.com` (fully onboarded) and `exhir808@example.com` (needs onboarding).

**Why**

- Two separate audiences, two separate documents. The client needs to know "what is blocked / what are you working on / what's done"; the engineering team needs file-level, acceptance-criteria tasks. Combining them produces a document neither party actually reads.
- All items reference concrete `file:line` so the triage reviewer can jump to the code without re-exploring the repo.

**Impact for deployment**

- The engineering TODO lists everything standing between today's build and a releasable app. NIC deployment should wait until the P0 and P1 items are closed, or at least flagged as known-ship-risk in release notes.

---

### 2026-10-28 — Android NDK + Gradle setup fixes

**What changed**

- `android/app/build.gradle.kts` line 24 — `ndkVersion` set from empty string to `"28.2.13676358"`.
- `android/gradle/wrapper/gradle-wrapper.properties` — pinned to `gradle-9.1.0-bin.zip`.
- `android/gradle.properties` — IPv4-preference JVM args added so Gradle resolves Maven over corporate networks that stall on IPv6.
- `android/app/build.gradle.kts` lines 88–90 — the `com.google.gms.google-services` plugin is applied **only when** `google-services.json` is present. Build still succeeds for teammates who have not synced Firebase keys yet.

**Why**

- Firebase (and several other plugins — `file_picker`, `image_picker`) require NDK 28.2.13676358. An unpinned `ndkVersion` picks the SDK default, which drifted and failed the build.
- Conditional plugin apply means the repo clones green on day one; the plugin lights up the moment a developer runs `flutterfire configure`.

**Impact for deployment**

- NIC build hosts must have Android SDK 36, NDK 28.2.13676358, and JDK 17 (Android Studio bundled JDK is the known-good one). CI must install the same versions explicitly.

---

## 4. Known pending items

Live task list is in `docs/engineering-todo.md`. Summary of priorities as of 2026-10-29:

- **P0 (2):** blockers that must close before any release build.
- **P1 (5):** must close before the NIC rollout.
- **P2 (6):** post-launch cleanup.
- **P3 (4):** nice-to-have / tech debt.

Firebase integration (above) is not in that list; add a task if additional Firebase features (Remote Config, Dynamic Links) are planned.

---

## 5. How to maintain this document

When you ship a change that affects *any* of the following, add an entry at the top of the Change Log in this file **in the same commit**:

- A new environment, new base URL, or any change to `--dart-define` flags.
- Any file under `lib/core/config/`, `android/app/`, `ios/Runner/`, or `web/`.
- Firebase project changes, new Firebase products, or any `firebase_options.dart` regeneration.
- Changes to `scripts/` or to the build / release workflow.
- A bug fix that required a design decision — not every typo, but anything that will be surprising to a reader six months from now.

Entries do not need to be long. They need to be **honest** about the trade-off that was chosen, so the next person does not undo it by accident.

Do not delete historical entries. If a decision is later reversed, write a **new** entry that supersedes the old one and references it by date.
