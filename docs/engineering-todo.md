# Liaison Officer Mobile App — Engineering TODO

**Branch:** `feature/lo-mobile-production`
**App version:** `1.0.7+8`
**Audience:** Mobile team + aide-service team
**Last updated:** 2026-10-29

A single, prioritised backlog of every known defect, gap or follow-up on the Liaison Officer mobile client, together with every item that depends on the aide-service backend. Each row includes an owner slot, acceptance criteria, the files that need to change and a reference back to the audit evidence.

For the client-facing version of this list, see [`pending-tasks-handover.md`](pending-tasks-handover.md). This file is the engineering working copy.

---

## How to use this document

1. Pick a task from the highest priority band that is still open.
2. Add your name in the **Owner** cell and move it to the "In progress" column of your tracker (if you use one).
3. Open the files listed under **Touches**.
4. Complete the change until the **Acceptance** criteria are met.
5. Open a PR referencing the task ID (`TASK-M-01`, `TASK-B-02`, etc.).
6. Mark the task **Done** in this file in the same PR (change the Status cell).

## Priority legend

| Band | Meaning | Target close |
|------|---------|--------------|
| **P0 — Blocker** | Breaks a core user journey or crashes the app. Ship-stopper. | Before next build |
| **P1 — High** | Degrades a feature, hides errors, or risks data loss. | Current sprint |
| **P2 — Medium** | Contract drift, cleanup, non-blocking warnings. | Next sprint |
| **P3 — Low** | Cosmetic, docs, test coverage, dependency hygiene. | Backlog |

Owner codes used below: **MOB** = mobile team, **BE** = aide-service team, **BOTH** = coordinate across teams.

---

## P0 — Blockers

### TASK-M-01 — Fix issues endpoint path (404 on every report)

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 1 hour |

**Problem.** `lib/core/config/api_config.dart:37` declares `myLoIssuesPath = '/app/my-lo/me/issues'`, and `lib/features/liaison_officer/data/repository/dio_lo_portal_repository.dart:381` POSTs to that path. The backend does not expose it; the real controller is `ConsIssueController` mounted at `/app/cons-issues/**`. Every issue report submitted from the app returns `404 Not Found`, falls through to the offline queue and silently never flushes.

**Touches.**
- `lib/core/config/api_config.dart` — change the constant.
- `lib/features/liaison_officer/data/repository/dio_lo_portal_repository.dart` — adjust the call site if the signature of the real endpoint differs.
- The retry/queue behaviour in `lib/features/liaison_officer/data/cache/lo_offline_store.dart` should not need changes.

**Acceptance.**
- A fresh issue report submitted from the Liaison Officer app returns `200 OK` from aide-service.
- The report appears in the aide-service `cons_issues` table (or whichever table backs `ConsIssueController`).
- The offline queue flushes cleanly on reconnect — no stale items left in Hive after a successful retry.
- An automated integration test covers the happy path.

**Depends on.** TASK-B-01 (coordinate with backend team on exact path and payload shape).

---

### TASK-M-02 — Guard `dart:io` imports so the web build does not crash

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 2 hours |

**Problem.** Two files import `dart:io` and use `File` / `path_provider` without a `kIsWeb` guard:

- `lib/features/liaison_officer/presentation/shells/lo_portal_shell.dart:1,139-142`
- `lib/features/liaison_officer/presentation/screens/help_support_screen.dart:1,319-323`

The app starts on web because the code paths are lazy, but tapping "share manual" or "download PDF" throws `Unsupported operation: _Namespace` and dumps a red error screen.

**Touches.** Same two files.

**Acceptance.**
- The two affected actions either (a) open successfully on web using a web-safe equivalent (`html.AnchorElement` / `url_launcher` for downloads), or (b) are hidden on web via `if (kIsWeb) return;` with a user-visible tooltip explaining the action is mobile-only.
- No red-screen regression on mobile.
- A smoke test on `flutter run -d chrome` reaches every tab without throwing.

---

## P1 — High

### TASK-B-01 — Confirm or implement the issues endpoint

| | |
|---|---|
| **Owner** | BE |
| **Status** | Open |
| **Estimate** | half day |

**Problem.** See TASK-M-01 for context. The mobile team needs the backend team to confirm which of the following is correct:

1. The mobile client should call the existing `ConsIssueController` route (e.g. `POST /app/cons-issues/facility/{facilityId}`), in which case we need the exact request/response contract.
2. A dedicated `my-lo` wrapper route should be added, matching the Swagger shape the mobile client already expects.

**Acceptance.**
- A documented endpoint (OpenAPI entry) that accepts the mobile client's current `LoIssueReport` payload.
- Confirmation sent to the mobile team so TASK-M-01 can land.

---

### TASK-B-02 — Add `POST /api/devices/unregister`

| | |
|---|---|
| **Owner** | BE |
| **Status** | Open |
| **Estimate** | half day |

**Problem.** `lib/core/config/api_config.dart:86` points at `/api/devices/unregister`. The backend only exposes `/api/devices/register`. On logout the client tries to drop the FCM token, receives `404`, swallows the error, and the token stays active on the server. If the device is handed to a different officer, pushes will reach the wrong account.

**Touches (backend).** New controller mapping and persistence call.

**Acceptance.**
- `POST /api/devices/unregister` accepts `{deviceToken, email}` (or whatever shape the mobile client already sends) and deletes the matching row.
- Returns `204 No Content` on success, `404` only when the token was never registered.
- Added to Swagger / OpenAPI.
- Mobile client's logout log stops reporting the 404.

---

### TASK-M-03 — Replace silent `catch(_){}` blocks with observable error handling

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 1 day |

**Problem.** Fourteen call sites swallow exceptions silently. The worst cluster is the offline queue, which hides data-loss conditions:

| File | Lines |
|------|-------|
| `lib/features/liaison_officer/data/cache/lo_offline_store.dart` | 56, 78, 88, 124, 143, 176, 182, 192, 204 |
| `lib/core/services/push_notification_service.dart` | 252 |
| `lib/features/liaison_officer/data/repository/dio_lo_portal_repository.dart` | 393, 400 |
| `lib/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart` | 637 |
| `lib/features/liaison_officer/presentation/shells/lo_portal_shell.dart` | 89 |
| `lib/features/liaison_officer/presentation/screens/help_support_screen.dart` | 25 |

**Touches.** The files above.

**Acceptance.**
- Every `catch(_){}` either rethrows, logs via `debugPrint`, or forwards to `FirebaseCrashlytics.instance.recordError` with the originating call context.
- The offline queue adds a `queuedAt` + `lastFailureReason` field so UIs can surface failed sync attempts.
- Lint rule `empty_catches` is enabled in `analysis_options.yaml` to prevent regressions.

---

### TASK-M-04 — Make mock upload implementations actually record data

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | half day |

**Problem.** `lib/features/liaison_officer/data/repository/mock_lo_portal_repository.dart:259-274` contains six `uploadXxx(bytes, filename) async {}` methods with empty bodies. The UI shows "upload successful" even though nothing was persisted. This hides real upload bugs behind a passing mock.

**Touches.** `lib/features/liaison_officer/data/repository/mock_lo_portal_repository.dart`.

**Acceptance.**
- Each mock upload stores the bytes and filename in an in-memory map keyed by the field name (photo, signature, aadhaar-front, aadhaar-back, badge-front, badge-back).
- The corresponding `GET` methods return the stored payload so the "already uploaded" UI state is visible in dev.
- A widget test for the upload flow asserts the stored filename matches what the picker returned.

---

### TASK-B-03 — Return `400 Bad Request` on captcha mismatch, not `500`

| | |
|---|---|
| **Owner** | BE |
| **Status** | Open |
| **Estimate** | 2 hours |

**Problem.** `POST /api/auth/request-otp` with a wrong captcha answer returns `500 Internal Server Error`. The mobile client's `ApiErrorMessage` cannot distinguish this from a true server error, so the user sees "Server error, please try again later" instead of "CAPTCHA does not match". The backend already throws `AideBusinessException` with code `CAPTCHA_MISMATCH` (`CaptchaService.java:70`) but the global exception handler maps business exceptions to 500 for this path.

**Touches (backend).** The global `@ControllerAdvice` or wherever `AideBusinessException` is handled.

**Acceptance.**
- Captcha mismatch, expired, or already-used returns HTTP `400` with a body like `{"error": "CAPTCHA_MISMATCH", "message": "CAPTCHA does not match"}`.
- Mobile client shows the correct message without additional changes.

---

## P2 — Medium

### TASK-B-04 — Prevent email enumeration on `/api/auth/resend-otp`

| | |
|---|---|
| **Owner** | BE |
| **Status** | Open |
| **Estimate** | 2 hours |

**Problem.** `POST /api/auth/resend-otp` returns `200 OK` for both registered and unregistered email addresses, which is correct for login flows — except that `check-email` already acknowledges unknown accounts in the same way. If an attacker can time the response, they can enumerate registered addresses. Low severity but worth closing.

**Acceptance.** Response time padded or structured so the two paths are indistinguishable. Rate-limit by IP as a defence in depth.

---

### TASK-M-05 — Remove unused `sqflite` and `sqflite_common` dependencies

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 1 hour |

**Problem.** `pubspec.yaml` declares `sqflite` but no file in `lib/` imports it. Dead weight that enlarges the APK.

**Acceptance.** `flutter pub remove sqflite` succeeds and the app still builds. Any related transitive deps that are no longer needed are removed by `flutter pub get`.

---

### TASK-M-06 — Replace hardcoded `API_BASE_URL` default

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 1 hour |

**Problem.** `lib/core/config/api_config.dart:18` defaults to `http://34.47.128.151:6080`. That host is unreachable (confirmed by probe). Any build without `--dart-define=API_BASE_URL=…` goes to a dead host.

**Acceptance.** The default is either `http://localhost:8080` (dev-friendly) or removed, forcing the build to specify a URL. The release workflow passes `API_BASE_URL` explicitly, which it already does.

---

### TASK-M-07 — Reconcile NDK configuration

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 1 hour |

**Problem.** `android/app/build.gradle.kts:24` sets `ndkVersion = "28.2.13676358"`. `android/fix_compile_sdk.gradle` sets `android.ndkVersion = null` in a subproject hook. The two configurations fight each other.

**Acceptance.** One place sets NDK, and all subprojects inherit it. The build log no longer prints the NDK mismatch warning.

---

### TASK-M-08 — Instrument `reportIssue` retry failures

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 2 hours |

**Problem.** `lib/features/liaison_officer/data/repository/dio_lo_portal_repository.dart:400` swallows a `DioException` inside a retry branch. If the retry fails too, no log, no Crashlytics event, no user feedback. Partly covered by TASK-M-03 but called out separately because it is the retry path for issue reports.

**Acceptance.** Retry failure is surfaced via Crashlytics and the UI shows a persistent toast or badge until the item flushes.

---

### TASK-M-09 — Correct docs that reference missing files

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 30 minutes |

**Problem.** `docs/delegate-assignment-notification.md:15` claims `google-services.json` is "already added". It is not.

**Acceptance.** Doc updated to reflect that the file is still pending client delivery (track against TASK-M-10).

---

### TASK-M-10 — Wire Firebase credentials

| | |
|---|---|
| **Owner** | BOTH |
| **Status** | Open |
| **Estimate** | 1 day once credentials arrive |

**Problem.** `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` are missing. All Firebase surfaces (FCM, Analytics, Crashlytics, Performance) are wired but inert.

**Acceptance.**
- Both files committed (or stored in CI secrets and injected at build time).
- `--dart-define=ENABLE_FCM=true` produces a build whose startup log shows `PushNotificationService: FCM ready` instead of the current `FCM off` line.
- Test device receives a push from the Firebase console.

---

## P3 — Low

### TASK-M-11 — Clear the three analyzer `info` lints

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 15 minutes |

**Problem.** `flutter analyze` reports:

- `lib/core/auth/domain/auth_repository.dart:53` — `prefer_initializing_formals`
- `lib/core/widgets/role_profile_drawer_header.dart:108` — `unnecessary_underscores`
- `lib/features/liaison_officer/data/repository/dio_lo_portal_repository.dart:399` — `unawaited_return_in_try_block`

**Acceptance.** `flutter analyze` returns zero issues.

---

### TASK-M-12 — Delete the Android template `TODO`

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 2 minutes |

**Problem.** `android/app/build.gradle.kts:34` still carries the stock Android Studio `TODO: Specify your own unique Application ID` comment, even though the application ID is set below.

**Acceptance.** Comment removed.

---

### TASK-M-13 — Add tests for untested critical paths

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 3 days |

**Problem.** The following flows have no automated coverage:

- `DioLoPortalRepository` happy and sad paths
- `FcmDeviceRegistrar` register / unregister
- `PushNotificationService` foreground + background handlers
- Document upload end-to-end
- Offline queue flush path

**Acceptance.** New test files under `test/` with meaningful assertions. Overall line coverage up by at least 20 percentage points on the touched files.

---

### TASK-M-14 — Dependency hygiene

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | 2 days |

**Problem.** 25 packages have major-version upgrades blocked by constraints. The security-sensitive stuck set:

| Package | Current | Available |
|---------|---------|-----------|
| `firebase_core` | 4.15.0 | 5.1.0 |
| `firebase_messaging` | 16.7.0 | 17.0.1 |
| `firebase_crashlytics` | 5.4.0 | 6.0.1 |
| `flutter_secure_storage` | 9.2.4 | 11.2.0 |

**Acceptance.** All four bumped, breaking-change migration notes handled, app still passes `flutter analyze` and the full test suite.

---

### TASK-M-15 — Introduce `kIsWeb` branching where behaviour genuinely differs

| | |
|---|---|
| **Owner** | MOB |
| **Status** | Open |
| **Estimate** | half day |

**Problem.** `kIsWeb` is not used anywhere in `lib/`. For now the only concrete problem is the two `dart:io` sites in TASK-M-02, but future web-vs-native branching needs a convention. Agree on either per-call `kIsWeb` checks or conditional imports (`io_stub.dart` / `web_stub.dart`).

**Acceptance.** A short section in `README.md` documents the chosen convention. TASK-M-02 is reworked to follow it.

---

## Reference material

- Audit evidence that produced this list: internal engineering audit, 2026-10-29.
- Client-facing summary: [`pending-tasks-handover.md`](pending-tasks-handover.md).
- Requirements matrix: [`lo-requirements-matrix.md`](lo-requirements-matrix.md).
- Production readiness checklist: [`production-readiness-requirements.md`](production-readiness-requirements.md).
- aide-service repository (local): `C:\Users\baps\Documents\BEL\aide-service`.
- aide-service OpenAPI (local): `http://localhost:8080/v3/api-docs`.
- aide-service Swagger UI (local): `http://localhost:8080/swagger-ui.html`.

---

## Change log

| Date       | Who | Change |
|------------|-----|--------|
| 2026-10-29 | engineering audit | Initial version with 17 tasks drawn from the first full audit cycle. |
