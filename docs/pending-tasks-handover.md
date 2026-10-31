# Liaison Officer Mobile App — Pending Tasks & Handover Notes

**Branch:** `feature/lo-mobile-production`
**App version:** `1.0.7+8`
**Prepared for:** Client (BEL / Aero India project team)
**Status date:** 2026-10-28

This document lists the work that still needs client-side input, backend action, or infrastructure provisioning before the Liaison Officer mobile app can be shipped end-to-end. It complements [`lo-requirements-matrix.md`](lo-requirements-matrix.md), which tracks the Flutter feature coverage, and [`production-readiness-requirements.md`](production-readiness-requirements.md), which lists the Play Store / App Store launch checklist.

Items here are **not Flutter code defects**. The mobile client implements every endpoint declared in `lib/core/config/api_config.dart`. The blockers below are backend configuration, cloud credentials, or platform assets that only the client can provide or confirm.

---

## 1. Summary

| Severity | Count | Blocks release? |
|----------|-------|-----------------|
| Blocker  | 2     | Yes             |
| High     | 5     | Yes (feature-level) |
| Medium   | 4     | No, but recommended before store submission |
| Low      | 3     | Housekeeping — can go into the next sprint |

The app is **functionally complete** against the LO requirements matrix (items 1–11 marked DONE). The gaps below are integration and deployment items.

---

## 2. Blockers — must be resolved before UAT

### 2.1 Backend base URL mismatch
- **File:** `lib/core/config/api_config.dart` (line 18)
- **Currently points to:** `http://34.47.128.151:6080`
- **Documented production URL (per `lo-requirements-matrix.md`):** `http://35.244.48.209:8080`
- **Observed:** `GET /api/auth/captcha` on `34.47.128.151:6080` connects but does not return a response within the 8 s client timeout.
- **Action required (client / aide-service team):** confirm the correct public URL for the Liaison Officer back-end and whether the captcha endpoint is live. Once confirmed, we will update `API_BASE_URL` and ship a release build with `--dart-define=API_BASE_URL=<url>`.

### 2.2 Mock mode is the default
- **File:** `lib/core/config/api_config.dart` (line 13)
- **Setting:** `USE_MOCK_API` defaults to `true`.
- **Impact:** any build produced without `--dart-define=USE_MOCK_API=false` runs on the in-memory mock repositories. The release workflow sets this flag, but ad-hoc builds and QA sideloads can silently use mocks.
- **Action required (us):** flip the default to `false` once the backend URL (item 2.1) is confirmed, and update the release scripts to make the flag explicit.

---

## 3. High-priority — required for push, iOS parity, and plugin stability

### 3.1 Firebase credentials (Android)
- **Missing file:** `android/app/google-services.json`
- **Impact:** FCM is wired in `lib/core/services/fcm_device_registrar.dart` and `lib/core/services/push_notification_service.dart`, but push notifications are disabled at runtime until the Firebase config file is present. Runtime log confirms: `PushNotificationService: FCM off. Build with --dart-define=ENABLE_FCM=true after adding android/app/google-services.json.`
- **Action required (client):** share the `google-services.json` for the Aero India Firebase project (production + staging).

### 3.2 Firebase credentials (iOS)
- **Missing file:** `ios/Runner/GoogleService-Info.plist`
- **Also missing:** `ios/Podfile` is not present in the repository, so a Pods install has not been bootstrapped for the current branch.
- **Impact:** no iOS push, and the iOS build cannot be produced on a Mac host without first running `pod install`.
- **Action required (client):** share the iOS Firebase plist and confirm the Apple Developer team ID and bundle identifier (`com.bel.liaison_officer`) are provisioned.

### 3.3 iOS permission strings
- **File:** `ios/Runner/Info.plist`
- **Missing keys:** `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`.
- **Impact:** `image_picker` and `file_picker` will crash on the first permission prompt on iOS. Apple also rejects submissions that use these APIs without a usage description.
- **Action required (us):** add the usage strings once the client approves the user-facing copy (sample text can be provided).

### 3.4 Device-registration endpoints are not in the public API
- **Files:** `lib/core/config/api_config.dart` (lines 82, 86); `docs/api-lo-endpoints.md` (line 91)
- **Endpoints:** `POST /api/devices/register`, `POST /api/devices/unregister`
- **Observed:** CAP currently returns `404` for both. The client treats this as a soft failure (logged and ignored) so that logout still completes, but push cannot work until the backend route is live.
- **Action required (aide-service team):** add these routes to the production API and confirm the request / response contract so we can finalise retry semantics.

### 3.5 Kotlin Gradle Plugin (KGP) migration warning
- **Observed in build:** plugins `file_picker`, `firebase_analytics`, `firebase_core`, `firebase_crashlytics`, `firebase_performance`, `share_plus` apply the legacy KGP configuration.
- **Impact:** future Flutter releases will fail the Android build.
- **Action required (us):** track the upstream plugin versions and bump when they publish a built-in-Kotlin compatible release. Not blocking today, but worth planning before the next SDK bump.

---

## 4. Medium — recommended before store submission

| # | Item | File / location | Note |
|---|------|-----------------|------|
| 4.1 | Reconcile the two NDK configs | `android/app/build.gradle.kts` and `android/fix_compile_sdk.gradle` | One file sets `ndkVersion = "28.2.13676358"`, the other sets `android.ndkVersion = null` in a subproject hook. The two should agree. |
| 4.2 | Gradle wrapper changed from `all.zip` to `bin.zip` | `android/gradle/wrapper/gradle-wrapper.properties` | Smaller download, no bundled source/docs. Fine for CI; please confirm this is the intended distribution. |
| 4.3 | Java 8 source/target deprecation warning | shows during `assembleDebug` | Flutter plugins still inject Java 8 source compatibility even though the app targets 17. Will become a hard error in future Android Gradle Plugin versions. |
| 4.4 | Doc divergence | `docs/delegate-assignment-notification.md:15` | The doc states `google-services.json` is "already added". It is not. Doc should be updated once item 3.1 is resolved. |

---

## 5. Low — pre-existing backlog (not blocking)

These items existed on `main` before the current setup pass and are flagged for a future housekeeping sprint:

- Three analyzer `info`-level lints:
  - `lib/core/auth/domain/auth_repository.dart:53` — `prefer_initializing_formals`
  - `lib/core/widgets/role_profile_drawer_header.dart:108` — `unnecessary_underscores`
  - `lib/features/liaison_officer/data/repository/dio_lo_portal_repository.dart:399` — `unawaited_return_in_try_block`
- Android template comment left in `android/app/build.gradle.kts:34` (`TODO: Specify your own unique Application ID`). Cosmetic.
- Automated test coverage gaps. There are 4 test files (~850 lines). The following flows have no automated tests yet: `DioLoPortalRepository`, `FcmDeviceRegistrar`, `PushNotificationService`, document upload flows, and the offline-queue flush path.

---

## 6. What is already complete (for context)

Reference: [`lo-requirements-matrix.md`](lo-requirements-matrix.md).

- OTP login with CAPTCHA, JWT session handling, secure storage of the access token
- Delegate list, delegate detail, itinerary and transport cards
- Task list with grouped-by-delegate view, task status updates with offline queue
- Delegate movement sheet (arrival, transfer, venue entry, departure)
- Issue reporting with Hive-backed offline queue and share-sheet fallback
- Notifications: in-app CAP inbox, local OS reminders, FCM client wiring (gated on item 3.1)
- Profile, document uploads (passport photo, signature, Aadhaar front/back, org badge front/back), language picker
- Theming (light / dark / system) with persisted preference
- Firebase Analytics, Crashlytics and Performance monitoring (no personal data; gated on item 3.1 for actual delivery)

---

## 7. Owner / next-action summary

| ID  | Area                                   | Owner                      | Next action |
|-----|----------------------------------------|----------------------------|-------------|
| 2.1 | Backend URL confirmation               | Client / aide-service team | Share correct `API_BASE_URL` and confirm `/api/auth/captcha` is reachable |
| 2.2 | Default build flag                     | Mobile team                | Flip default once 2.1 is confirmed |
| 3.1 | `google-services.json` (Android)       | Client                     | Share from Firebase console |
| 3.2 | `GoogleService-Info.plist` (iOS)       | Client                     | Share from Firebase console + confirm bundle ID |
| 3.3 | iOS permission strings                 | Mobile team                | Add once copy is approved |
| 3.4 | Device-register routes                 | aide-service team          | Implement `/api/devices/register` and `/api/devices/unregister` on CAP |
| 3.5 | KGP plugin upgrades                    | Mobile team                | Track and bump when upstream ready |
| 4.1 | NDK config reconcile                   | Mobile team                | Pick a single source of truth |
| 4.2 | Gradle wrapper distribution            | Mobile team                | Confirm `bin.zip` is intended |
| 4.3 | Java 8 deprecation                     | Mobile team / plugin owners | Monitor plugin updates |
| 4.4 | Doc correction                         | Mobile team                | Update after 3.1 lands |
| 5.* | Backlog cleanup                        | Mobile team                | Schedule in next housekeeping sprint |

---

## 8. Build and run reference (for the client's QA team)

Prerequisites: Flutter 3.47.8 stable channel, Android SDK 36, Android NDK 28.2.13676358, JDK 17 (bundled with Android Studio).

```bash
flutter pub get
flutter run -d <device-id>                                           # mock mode (default)
flutter run -d <device-id> --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=http://<confirmed-url>                  # live backend
flutter build apk --release --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=http://<confirmed-url> \
  --dart-define=ENABLE_FCM=true                                      # after google-services.json is in place
```

Mock credentials for the current build: email `liaison@test.com`, any non-empty CAPTCHA answer, OTP `123456`.
