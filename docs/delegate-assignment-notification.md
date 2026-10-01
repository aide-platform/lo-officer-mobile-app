# Delegate assignment notification

When a liaison officer is assigned a delegate on the web, that officer’s phone should show a notification. This note splits the work already done on the mobile app and in Firebase from the work still required on the Spring Boot portal service.

Portal API base URL used by the phone: `http://34.47.128.151:6080`

Firebase project: [lo-mobile-app](https://console.firebase.google.com/project/lo-mobile-app/overview)

Android application id: `com.bel.liaison_officer`

## What the phone does today

The client is in this repository. Remote push runs only in a build made with both of these:

- `android/app/google-services.json` from the Firebase Android app `com.bel.liaison_officer` (already added; the Google Services Gradle plugin turns on only when that file is present)
- `--dart-define=ENABLE_FCM=true` together with the live defines `--dart-define=USE_MOCK_API=false` and `--dart-define=API_BASE_URL=http://34.47.128.151:6080`

Without those, the phone never talks to Firebase and never posts a device token. Local task reminders still work; they are not this notification.

After a successful OTP login, and again whenever Firebase rotates the device token, the app calls:

```http
POST /api/devices/register
Authorization: Bearer <officer access token>
Content-Type: application/json
```

```json
{
  "email": "lo@example.com",
  "fcmToken": "<device token>",
  "platform": "android"
}
```

`platform` is `android` or `ios`. The call uses the same Bearer token as the rest of the portal. The app treats any HTTP 2xx as success. It does not read `data`. On 404 it logs the failure and continues; that is the current live behaviour, so the token is not stored anywhere.

Code:

- Token post: `lib/core/services/fcm_device_registrar.dart` (also started from `lib/main.dart` and after login in `lib/core/routing/role_home_router.dart`)
- Path constant: `ApiConfig.devicesRegisterPath` in `lib/core/config/api_config.dart`
- Display and tap: `lib/core/services/push_notification_service.dart`

When a message arrives:

- Title comes from the notification block, or from `data.title`, or the fallback text `Liaison Officer`.
- Body comes from the notification block or `data.body`.
- A tap reads only `data.link`. If that string contains `delegate`, the app opens the Delegates tab. If it contains `task`, it opens the Tasks tab. See `LoPortalShell._openPushLink` in `lib/features/liaison_officer/presentation/shells/lo_portal_shell.dart`.

Logout clears the token in memory on the phone only. The app does not call an unregister API.

The officer must install a build that includes `ENABLE_FCM=true`, then sign in once, before any server send can reach that phone.

## Give the web team this

Send them this section only. Do not send the Web Push certificate from the Firebase console, and do not send `google-services.json`.

| What | Value |
|------|--------|
| Firebase project | `lo-mobile-app` |
| Sender ID | `813770238672` |
| Account they must send as | `lo-mobile-fcm-sender@lo-mobile-app.iam.gserviceaccount.com` |
| Role already granted | Firebase Cloud Messaging API Admin |
| Private JSON key | None. Both service accounts show **No keys**. Organization policy blocks key creation. |

They call Firebase as that sender account, aimed at the one device token stored for the officer. If the portal runs on Google Cloud, attach that service account to the server and initialize Firebase once. If they need a JSON file on a machine outside Google Cloud, an organization admin must allow key creation on `lo-mobile-app` first. Until then the console cannot add a key.

Leave `firebase-adminsdk-fbsvc@lo-mobile-app.iam.gserviceaccount.com` as it is. The Web Push key pair is for browsers, not this Android app.

## What is done in Firebase

Handled on the mobile / Firebase side. The Spring Boot service does not create the Firebase project.

| Item | Value |
|------|--------|
| Project | `lo-mobile-app` |
| Android app | `com.bel.liaison_officer` |
| Client config | `android/app/google-services.json` in the mobile repo |
| Cloud Messaging API | Enabled |
| Sender service account | `lo-mobile-fcm-sender@lo-mobile-app.iam.gserviceaccount.com` |
| Role on that account | Firebase Cloud Messaging API Admin (`roles/firebasecloudmessaging.admin`) |

That role allows the account to send a message to a device token. It is not a client key and it is not inside the APK.

A downloadable Admin JSON private key was **not** created. The Google organization policy `constraints/iam.disableServiceAccountKeyCreation` blocks key creation for every service account in this project, including the built-in `firebase-adminsdk-fbsvc@lo-mobile-app.iam.gserviceaccount.com`. No private key file was written, and none must be added to the mobile repo, git, or the APK.

How the portal server should authenticate:

- If the Spring Boot process runs on Google Cloud, attach `lo-mobile-fcm-sender@lo-mobile-app.iam.gserviceaccount.com` to that runtime and call `FirebaseApp.initializeApp()` once at startup with Application Default Credentials. No JSON key is required.
- If the server is outside Google Cloud and must use a JSON key, an organization admin has to allow service-account key creation on project `lo-mobile-app`. After that, generate one key for `lo-mobile-fcm-sender` and keep it only in the portal server secret store. Do not send that file back into the mobile repository.

## What the Spring Boot service must build

Two changes. Until both exist, assigning a delegate on the web does not notify the phone.

### 1. Store the device token

Add `POST /api/devices/register`.

Request: Bearer JWT of the signed-in liaison officer, plus the JSON body above.

Response: the usual portal envelope `{ success, message, data, errorCode, timestamp }` with HTTP 200. Any 2xx is enough.

Rules:

- Reject the call when the JWT is missing or is not a liaison officer.
- Bind the token to the authenticated user. If `email` does not match the JWT subject, reject the call. Do not trust the body email alone.
- Upsert one row per officer and platform. The phone posts again on the next login and on token refresh; replace the previous token.
- Do not log the raw `fcmToken`.

Suggested table `lo_device_token`:

| Column | Notes |
|--------|--------|
| `id` | Primary key |
| `user_email` | Officer email from the JWT |
| `fcm_token` | Latest device token |
| `platform` | `android` or `ios` |
| `updated_at` | Set on every upsert |

Unique constraint: `(user_email, platform)`.

### 2. Send when a delegate is assigned

In the existing service method that saves a **new** delegate assignment to a liaison officer, after that database transaction commits:

1. Load `fcm_token` for that officer where `platform = android`.
2. If no row exists, leave the assignment saved and log that the officer has no device. Do not roll back the assignment.
3. Send one Firebase Cloud Messaging HTTP v1 message with the Admin SDK (`com.google.firebase:firebase-admin`) from account `lo-mobile-fcm-sender@lo-mobile-app.iam.gserviceaccount.com`.

Set both the notification block and the data map. The phone can show title and body from either. The tap path reads only `data.link`.

`assignmentId` is the id the officer’s delegate list already uses (`MyLoAssignmentDto.assignmentId`). The link only has to contain the word `delegate` to open the Delegates tab. The id is included so a later app build can open that person. Installed 1.0.7 does not open a details card.

Send once per new assignment. Do not send on profile edits, travel updates, or other saves of an existing assignment. If Firebase returns an unregistered or invalid token, delete that `lo_device_token` row.

Initialize `FirebaseApp` once at process startup.

### Sample the server should send

Logical message for one new assignment. Firebase Cloud Messaging `data` cannot hold a nested object, so the wire form below flattens every value to a string.

```json
{
  "notificationId": "NTF-2027-00001245",
  "notificationType": "DELEGATE_ASSIGNED",
  "priority": "HIGH",
  "title": "New Delegate Assigned",
  "body": "Delegate John Smith from Boeing has been assigned to you.",
  "data": {
    "eventCode": "AERO_INDIA_2027",
    "eventName": "Aero India 2027",
    "assignmentId": "ASN-2027-004521",
    "delegateId": "DEL-2027-001245",
    "delegateCode": "AI27-DEL-001245",
    "delegateName": "John Smith",
    "designation": "Vice President",
    "organization": "Boeing",
    "country": "United States",
    "loId": "LO-2027-00045",
    "loName": "Rajesh Kumar",
    "assignmentStatus": "ASSIGNED",
    "assignedDate": "2026-10-01T09:30:00+05:30",
    "screen": "DELEGATE_DETAILS",
    "deepLink": "aeroindia://delegates/DEL-2027-001245",
    "action": "VIEW_DELEGATE",
    "requiresAction": "true"
  }
}
```

Wire form. `priority` HIGH is the Android message priority (`android.priority` = `high`), not a data field the app reads. `data.link` must stay present so the installed app opens the Delegates tab. The custom scheme `aeroindia://delegates/...` is not registered on this app.

```text
notification.title = New Delegate Assigned
notification.body  = Delegate John Smith from Boeing has been assigned to you.
android.priority   = high

data.notificationId   = NTF-2027-00001245
data.notificationType = DELEGATE_ASSIGNED
data.title            = New Delegate Assigned
data.body             = Delegate John Smith from Boeing has been assigned to you.
data.link             = delegate:ASN-2027-004521
data.eventCode        = AERO_INDIA_2027
data.eventName        = Aero India 2027
data.assignmentId     = ASN-2027-004521
data.delegateId       = DEL-2027-001245
data.delegateCode     = AI27-DEL-001245
data.delegateName     = John Smith
data.designation      = Vice President
data.organization     = Boeing
data.country          = United States
data.loId             = LO-2027-00045
data.loName           = Rajesh Kumar
data.assignmentStatus = ASSIGNED
data.assignedDate     = 2026-10-01T09:30:00+05:30
data.screen           = DELEGATE_DETAILS
data.action           = VIEW_DELEGATE
data.requiresAction   = true
```

### What the phone shows today

The tray header is the app label `Aero India LO` from `android/app/src/main/AndroidManifest.xml`. `eventName` is data. It is not that header.

```text
Aero India LO
New Delegate Assigned
Delegate John Smith from Boeing has been assigned to you.
```

A tap reads `data.link` in `LoPortalShell._openPushLink`. `delegate:ASN-2027-004521` contains `delegate`, so the app opens the Delegates tab. It does not open a details page.

### Details card for a later build

Send the fields above now. A later app build can show this summary, then open `LoDelegateDetailScreen` when `assignmentId` matches a row already in the delegate list. This document does not add that screen.

```text
Delegate Details

John Smith
Vice President
Boeing
United States

Delegate ID
AI27-DEL-001245

Assignment Status
ASSIGNED

Assigned On
01 Oct 2026, 09:30 AM

Liaison Officer
Rajesh Kumar

[ View Full Details ]
```

`assignedDate` `2026-10-01T09:30:00+05:30` is the source of “01 Oct 2026, 09:30 AM”. `delegateCode` is the Delegate ID line. `organization` is the organisation line (`MyLoAssignmentDto` spells the list field `organisation`).

## Flow

```text
Phone login
  -> Firebase issues a device token
  -> POST /api/devices/register
  -> Spring Boot upserts lo_device_token

Web assigns a delegate
  -> assignment row commits
  -> Spring Boot loads the officer token
  -> Firebase delivers title, body, data.link = delegate:<assignmentId>, and the flat data fields
  -> phone shows "New Delegate Assigned"
  -> tap opens the Delegates tab
```

## Not in this change

- No unregister call on logout.
- No push yet for tasks, schedule changes, or meetings. Those can reuse `lo_device_token` later with `data.link` starting with `task:` when that work is scheduled.
- No change is required in the mobile register call or the Delegates tap handling.
- The details card above is not built. 1.0.7 does not open it.
