# Store Launch and Notifications Guide — Liaison Officer App

This guide explains how to publish **Liaison Officer** to the **Google Play Store** and **Apple App Store**, which permissions the app needs, common issues you may face, and every practical way to implement notifications for LO.9.4.

**Related docs**

- [production-readiness-requirements.md](./production-readiness-requirements.md) — QA, security, and compliance checklist (use before submission)
- This document — step-by-step store setup, permissions, launch workflow, and notification architecture

**App identifiers (current repo)**

| Platform | Identifier | Location |
|----------|------------|----------|
| Android | `com.bel.liaison_officer` | `android/app/build.gradle.kts` |
| iOS | `com.bel.liaisonOfficer` | `ios/Runner.xcodeproj/project.pbxproj` |
| Version | `1.0.0+1` | `pubspec.yaml` (`versionName` / `versionCode` or `CFBundleShortVersionString` / `CFBundleVersion`) |

> **Note:** Android and iOS bundle IDs use different naming (`liaison_officer` vs `liaisonOfficer`). Align them before launch if your organization requires a single canonical ID.

**Demo credentials for store reviewers**

- Email: `liaison@test.com`
- OTP: `123456`

---

# Part A — Google Play Store (Android)

## A.1 Account and prerequisites

Before you upload **Liaison Officer** (`com.bel.liaison_officer`), set up a Google Play developer account and gather legal/support assets. This section walks through each step in order.

### What you need before you start

| Item | Required? | Notes |
|------|-----------|-------|
| Google account (Gmail or Workspace) | Yes | Use a long-lived org email, not a personal account you may lose |
| Credit/debit card | Yes | One-time **$25 USD** registration fee |
| Government-issued ID | Often | For identity verification (individual or org contact) |
| D-U-N-S number | Org only | Free from Dun & Bradstreet; can take **5–30 business days** |
| Privacy policy URL (HTTPS) | Yes (before production) | Must be public; no login wall |
| Support email or URL | Yes | e.g. `support@bel.com` or help desk page |
| Signed release AAB | Yes (for upload) | See [A.2](#a2-prepare-this-app-for-play) |

### Step 1 — Create a Google Play Console account

1. Open [Google Play Console](https://play.google.com/console/signup).
2. Sign in with the Google account that will **own** the developer account (preferably a shared org account, not an individual employee’s personal Gmail).
3. Accept the **Developer Distribution Agreement** and **Google Play policies**.
4. Choose account type:

   **Individual developer**
   - Best for: solo developers, small teams, fast setup
   - Listed on store as your **legal name** (not a company name)
   - Verification: government ID, sometimes phone/video
   - Timeline: often **1–3 days** after payment

   **Organization developer**
   - Best for: BEL / government / corporate apps (recommended for Liaison Officer)
   - Listed on store as **organization name** (e.g. Bharat Electronics Limited)
   - Requires: legal entity name, address, contact, **D-U-N-S number**
   - Google verifies business via Dun & Bradstreet and may request extra documents
   - Timeline: often **3–10+ business days**

5. Pay the **$25 USD** one-time registration fee (non-refundable).
6. Complete the **account details** form:
   - Developer name (shown to users on the store listing)
   - Email address (public support contact — use a monitored inbox)
   - Phone number (for Google verification; may not be public)
   - Website (optional but recommended: `https://bel.com` or product page)

### Step 2 — Developer identity verification

Google requires identity verification for all new developer accounts (expanded enforcement since 2023–2024).

**Individual accounts — typical flow**

1. Play Console prompts **Verify identity** after signup.
2. Provide:
   - Full legal name (must match ID)
   - Address
   - Phone number (SMS or call verification)
3. Upload **government-issued photo ID** (passport, driver’s license, or national ID).
4. In some regions, Google requests a **selfie** or video verification.
5. Wait for email from Google (usually **24–72 hours**; can take longer on first review).

**Organization accounts — typical flow**

1. Enter legal business name exactly as registered.
2. Submit **D-U-N-S number** (9 digits). Lookup: [D-U-N-S Request](https://www.dnb.com/duns-number.html).
3. Google matches your business in Dun & Bradstreet’s database.
4. If match fails: verify D-U-N-S legal name/address matches Play Console exactly (including “Ltd.” vs “Limited”).
5. Google may email the Account Holder asking for:
   - Certificate of incorporation
   - Business registration extract
   - Letter on company letterhead

**If verification is rejected**

- Fix name/address mismatches between ID, D-U-N-S, and Play Console.
- Re-submit clearer ID photos (all corners visible, no glare).
- Use [Play Console Help → Contact support](https://support.google.com/googleplay/android-developer/) — do not create a second account (can cause permanent ban).

**Until verification completes**

- You can explore Play Console and sometimes upload to **internal testing**
- **Production** release may be blocked until identity is approved

### Step 3 — Payments profile (optional for Liaison Officer v1)

Liaison Officer is **free** with no in-app purchases today — you can **skip** the payments profile for initial launch.

Create a payments profile only when you need:

- Paid app download
- In-app purchases or subscriptions
- Paid content

If you add monetization later:

1. Play Console → **Settings → Payments profile**
2. Link a **Google payments merchant account**
3. Provide tax information (W-9, GSTIN, etc. depending on country)
4. Add bank account for payouts
5. Allow **1–2 weeks** for financial verification

### Step 4 — Legal and policy prerequisites

These are mandatory before **production** release (can be prepared while building internal test tracks).

#### Privacy policy (required)

Must be:

- Hosted at a **stable HTTPS URL** (e.g. `https://bel.com/privacy/liaison-officer`)
- Publicly readable without login
- Written in a language your users understand

Must describe for this app (at minimum):

- What data is collected (email, session tokens, task/travel data)
- Why it is collected (authentication, LO workflow)
- Where it is stored (device local storage, future backend servers)
- How users can contact you for data questions or deletion
- Third parties (future: Firebase, email provider — list when integrated)

#### Support contact (required)

Provide at least one:

- Support email (monitored), or
- Support URL with contact form

Play Store shows this to users who tap **Contact developer**.

#### Data safety form (required before production)

Completed inside Play Console → **App content → Data safety**. See [A.4](#a4-play-console-setup-step-by-step) for field-level guidance. Prepare answers **before** filling the form:

- Email address → collected for account management
- App activity (tasks, travel) → app functionality
- Data encrypted in transit → Yes (when API uses HTTPS)
- Data deletion → describe process (support request or in-app logout + server delete)

#### Content rating (required)

IARC questionnaire in Play Console. For Liaison Officer (business/event logistics, no violence/adult content), expect **Everyone / 3+ / PEGI 3** class ratings unless you declare sensitive features later.

#### Target audience

Declare whether the app targets children. Liaison Officer is an **adult professional tool** — typically **not designed for children** (under 13). Incorrect declaration can cause policy strikes.

### Step 5 — Invite your team (recommended)

Play Console → **Users and permissions**

| Role | Use for |
|------|---------|
| Admin | Full access; limit to 1–2 people |
| Developer | Upload builds, manage releases (CI service account) |
| Finance | Payments profile only |
| View app information | QA / management read-only |

For CI/CD (GitLab, GitHub Actions):

- Create a dedicated Google Cloud service account or use **Play App Signing** upload key in pipeline
- Never share the Account Holder’s personal Google password

### Step 6 — Pre-launch timeline (typical)

| Day | Activity |
|-----|----------|
| Day 0 | Pay $25, submit identity/business info |
| Day 1–3 | Identity verification (individual) |
| Day 1–10+ | Organization + D-U-N-S verification |
| Day 3–5 | Prepare privacy policy, support email, screenshots |
| Day 5–7 | First internal testing upload (AAB) |
| Day 7–14 | QA on real devices, fix Data safety / listing |
| Day 14+ | Production rollout (staged 5% → 100%) |

### Common blockers at account stage

| Problem | What to do |
|---------|------------|
| “Developer account pending verification” | Wait; check email; re-submit ID if rejected |
| D-U-N-S not found | Request free D-U-N-S; wait for Dun & Bradstreet to publish |
| Wrong account type chosen | Cannot convert Individual ↔ Organization easily; contact Google support early |
| Used personal Gmail | Migrate to org account before first production release |
| No privacy policy URL | Draft and publish before production submission |
| Payment profile requested unexpectedly | Only needed for paid/IAP apps; free apps skip it |

Once A.1 is complete and your account shows **Verified**, proceed to [A.2 Prepare this app for Play](#a2-prepare-this-app-for-play).

## A.2 Prepare this app for Play

### Release signing (required before production)

The project currently signs release builds with **debug keys** (`android/app/build.gradle.kts`). Play Store production uploads require a **release/upload keystore**.

**Step 1 — Create upload keystore (one time, on a secure machine)**

```bash
keytool -genkey -v \
  -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Store the keystore and passwords in a **password manager**. Never commit them to git.

**Step 2 — Create `android/key.properties` (gitignored)**

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

**Step 3 — Wire signing in `android/app/build.gradle.kts`**

Load `key.properties`, define a `release` signing config, and set `buildTypes.release.signingConfig` to that release config instead of `debug`.

**Step 4 — Enable Play App Signing**

- On first upload, Google Play App Signing is recommended
- Google holds the app signing key; you upload with the upload key
- If you lose the upload key, you can reset it through Play Console (with delay)

### Build commands

```bash
# Production artifact for Play Store (required format: AAB)
flutter build appbundle --release

# Output:
# build/app/outputs/bundle/release/app-release.aab

# APK (sideload / internal testing only — not for new Play production apps)
flutter build apk --release
```

### Versioning

In `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- `1.0.0` → Android `versionName`
- `1` → Android `versionCode` (must increase on every Play upload)

## A.3 Permissions for Liaison Officer

### Current permissions (as of this repo)

| Permission | Where declared | Why needed |
|------------|----------------|------------|
| `INTERNET` | `android/app/src/debug/AndroidManifest.xml` and `profile/` only | Network API calls, opening maps/WhatsApp links |

**Action before Play release:** add `INTERNET` to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

The main manifest currently has **no** dangerous permissions (camera, location, contacts, storage).

### Features used without extra manifest permissions

- **Phone calls** — `url_launcher` with `tel:` (opens dialer; no `CALL_PHONE` if user confirms in dialer)
- **WhatsApp / Maps** — HTTPS intents via `url_launcher`
- **Local storage** — SQLite (`sqflite`) and SharedPreferences (no legacy external storage permission)

### Permissions to add when features ship

| Feature | Permission | Play Data Safety impact |
|---------|------------|-------------------------|
| Push notifications (FCM) | `POST_NOTIFICATIONS` (Android 13+) | Declare notifications; user must grant at runtime |
| Reschedule local alarms after reboot | `RECEIVE_BOOT_COMPLETED` | Declare in Data safety if used |
| Profile photo from camera | `CAMERA` | Photos/videos collection |
| Profile photo from gallery | `READ_MEDIA_IMAGES` (API 33+) | Photos collection |
| Live venue GPS | `ACCESS_FINE_LOCATION` | Location collection + prominent disclosure |

### Play Data Safety — what to declare for this app

Based on current code:

| Data type | Collected? | Purpose | Encrypted in transit | User can request deletion |
|-----------|------------|---------|----------------------|---------------------------|
| Email address | Yes (login) | Account / LO role | Yes (when real API used) | Yes (via support/backend) |
| App activity (tasks, travel updates) | Yes (local + future sync) | App functionality | Yes | Yes |
| Device or other IDs | Only if FCM added | Push notifications | Yes | Yes |

Mock/demo mode still stores session in SharedPreferences — disclose local data storage honestly.

## A.4 Play Console setup (step-by-step)

### 1. Create the app

1. Play Console → **Create app**
2. App name: **Liaison Officer**
3. Default language: English (or primary market language)
4. App or game: **App**
5. Free or paid: **Free**
6. Accept declarations (policies, US export laws, etc.)

### 2. Store listing (Main store listing)

| Field | Guidance |
|-------|----------|
| App name | Liaison Officer |
| Short description | Max 80 chars — e.g. "Manage delegate assignments, travel, and tasks for event liaison officers." |
| Full description | Max 4000 chars — LO.9 features: delegate dossier, travel updates, tasks, notifications |
| App icon | 512×512 PNG |
| Feature graphic | 1024×500 PNG |
| Phone screenshots | Min 2; recommend 4–8 showing Delegates, Tasks, Travel, Notifications |
| Tablet screenshots | Optional unless targeting tablets |

### 3. App content section

Complete every required form:

- **Privacy policy** — URL required
- **Ads** — No ads (unless added later)
- **Content rating** — Complete IARC questionnaire (likely Everyone / low maturity for business app)
- **Target audience** — Select appropriate age band; not a children's app
- **News app** — No
- **COVID-19 apps** — No
- **Data safety** — Match actual data collection (see A.3)
- **Government apps** — Only if applicable

### 4. App access

If login is required:

- Select **All or some functionality is restricted**
- Provide demo credentials:
  - Username/email: `liaison@test.com`
  - Password/OTP: use OTP flow; note OTP `123456` in instructions
- Explain: "Tap Send OTP, enter 123456, then access LO portal."

### 5. Release pipeline

```
Internal testing → Closed testing → Open testing → Production
```

1. **Testing → Internal testing → Create new release**
2. Upload `app-release.aab`
3. Add release notes
4. Review and roll out to internal testers
5. After QA, promote to **Production** (or staged rollout: 5% → 20% → 100%)

### 6. Production checklist in Play Console

- [ ] App signing configured
- [ ] Data safety published
- [ ] Content rating received
- [ ] Store listing complete
- [ ] App access instructions for reviewers
- [ ] Target countries selected
- [ ] `versionCode` incremented

## A.5 Common Play Store issues (this project)

| Issue | Cause | Fix |
|-------|-------|-----|
| Upload rejected: debug certificate | Release signed with debug key | Configure upload keystore (A.2) |
| App crashes on launch | Storage/init failure | Ensure SQLite works on device; web uses SharedPreferences fallback (`lib/core/storage/sqlite/app_sqlite_db.dart`) |
| Data safety rejection | Form says "no data" but app stores email/session | Update Data safety to match behavior |
| Missing privacy policy | No URL in listing | Host policy on bel.com or docs site |
| Gradle build fails on CI | Corporate proxy / SSL | Use local `gradle.properties` for proxy + truststore; **never commit passwords** |
| `targetSdk` policy warning | Outdated target SDK | Keep Flutter/Android Gradle Plugin updated |
| Reviewer cannot log in | OTP not documented | Add demo OTP in App access section |
| Misleading screenshots | Marketing images ≠ app UI | Capture from release build |
| Tasks empty on web | sqflite unavailable in browser | Expected on web; mobile builds use SQLite — test on real Android device |

---

# Part B — Apple App Store (iOS)

## B.1 Account and prerequisites

Before you upload **Liaison Officer** (`com.bel.liaisonOfficer`) to the App Store, enroll in the Apple Developer Program and prepare your Mac/Xcode environment. Apple’s process is stricter and more expensive than Google Play, but it is mandatory for public iOS distribution.

### What you need before you start

| Item | Required? | Notes |
|------|-----------|-------|
| Apple ID | Yes | Enable **two-factor authentication (2FA)** — required for enrollment |
| Mac with macOS | Yes* | *Or CI macOS runner (GitHub Actions, Codemagic, etc.) for builds |
| Xcode (latest stable) | Yes | Install from Mac App Store; match Flutter’s iOS requirements |
| Legal entity or individual name | Yes | Must match enrollment type |
| D-U-N-S number | Organization only | Same as Google Play org flow |
| Credit/debit card | Yes | **$99 USD / year** (auto-renews) |
| Privacy policy URL (HTTPS) | Yes (before submission) | Same policy can serve both stores |
| iPhone or iPad for testing | Strongly recommended | Simulators miss push, camera, some url_launcher behavior |

### Step 1 — Prepare your Apple ID

1. Use an Apple ID you control long-term (prefer **org-managed** Apple ID for companies, not a departing employee’s personal ID).
2. Enable **Two-Factor Authentication**:
   - Apple ID settings → **Sign-In and Security → Two-Factor Authentication**
   - Enrollment **will fail** without 2FA
3. If your organization uses **Managed Apple IDs** (Apple Business Manager), confirm with IT whether they can enroll in the Developer Program or if a dedicated “App Store” Apple ID is needed.

### Step 2 — Enroll in the Apple Developer Program

1. Go to [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/).
2. Click **Start your enrollment**.
3. Sign in with your Apple ID.
4. Choose entity type:

   **Individual**
   - Legal name appears as **seller name** on the App Store
   - Enrollment uses your personal legal identity
   - Faster approval (often **24–48 hours**)
   - Best for: indie/solo developers

   **Organization**
   - Legal **company name** appears as seller (e.g. Bharat Electronics Limited)
   - Requires:
     - Legal entity status (company, nonprofit, government org, etc.)
     - **D-U-N-S number** (Apple verifies via Dun & Bradstreet)
     - Authority to bind the organization (Account Holder must be owner/founder/exec/senior employee)
   - Apple may call or email to verify employment/authority
   - Timeline: **1–4 weeks** if D-U-N-S or authority verification delays
   - **Recommended for Liaison Officer** if publishing under BEL or government brand

5. Complete the enrollment form:
   - Contact information
   - Business address (must match D-U-N-S for organizations)
   - Agree to **Apple Developer Program License Agreement**
6. Pay **$99 USD** annual fee (charged yearly until cancelled).
7. Wait for confirmation email: **“Welcome to the Apple Developer Program”**.

**After enrollment you gain access to:**

- [App Store Connect](https://appstoreconnect.apple.com) — app listings, TestFlight, analytics
- [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources) — signing assets
- TestFlight — beta distribution
- App Store submission and review

### Step 3 — Understand roles and access

Apple splits responsibilities across **Apple Developer** (technical) and **App Store Connect** (business/listing).

| Role | Where | Responsibilities |
|------|-------|------------------|
| **Account Holder** | Both | Legal agreements, renewal payment, highest authority; only one per org |
| **Admin** | App Store Connect | Manage users, apps, contracts, all app metadata |
| **App Manager** | App Store Connect | Create/edit apps, submit for review, manage TestFlight |
| **Developer** | App Store Connect | Upload builds via Xcode/Transporter; limited metadata access |
| **Marketing** | App Store Connect | Promo codes, analytics (optional) |
| **Finance** | App Store Connect | Reports, tax/banking (if selling paid apps) |
| **Customer Support** | App Store Connect | Respond to reviews (optional) |

**Recommended setup for Liaison Officer team**

| Person / system | Role |
|-----------------|------|
| IT lead / release manager | Account Holder or Admin |
| Mobile developer | Developer + App Manager |
| QA lead | App Manager (TestFlight) |
| CI pipeline (Codemagic, etc.) | Dedicated Apple ID with Developer role + API key |

**App Store Connect API key (for CI, optional but recommended)**

1. App Store Connect → **Users and Access → Integrations → App Store Connect API**
2. Generate key with **Developer** or **App Manager** role
3. Download `.p8` file once (cannot re-download)
4. Use in CI for `flutter build ipa` upload via `xcrun altool` or fastlane

### Step 4 — Mac and Xcode requirements

**Why a Mac is required**

- iOS apps must be **signed** with Apple certificates
- `flutter build ipa` invokes Xcode toolchain (`xcodebuild`)
- App Store upload uses **Transporter** or Xcode Organizer

**Minimum setup**

1. **Mac** running a macOS version supported by current Xcode (check [Xcode release notes](https://developer.apple.com/documentation/xcode-release-notes)).
2. Install **Xcode** from the Mac App Store (full app, not only Command Line Tools).
3. Open Xcode once → accept license → install additional components.
4. Install Xcode Command Line Tools (if prompted):

   ```bash
   xcode-select --install
   ```

5. Install **CocoaPods** (Flutter iOS dependency manager):

   ```bash
   sudo gem install cocoapods
   cd ios && pod install && cd ..
   ```

6. Verify Flutter sees Xcode:

   ```bash
   flutter doctor -v
   ```

   Fix any iOS toolchain issues before building release IPA.

**Without a local Mac**

Use a cloud macOS CI service:

- Codemagic, Bitrise, GitHub Actions (`macos-latest`), GitLab macOS runners
- Store signing certificates and provisioning profiles as **encrypted CI secrets**
- Same $99/year Apple Developer membership still required

### Step 5 — Legal and policy prerequisites (Apple)

Same core assets as Google Play (can reuse one privacy policy):

| Asset | Apple-specific notes |
|-------|---------------------|
| Privacy policy URL | Required in App Store Connect → App Privacy |
| Support URL | Required; must load in Safari |
| App Privacy “nutrition labels” | Declare data types collected (email, identifiers when push added) |
| Export compliance | Answer encryption questions; often exempt for HTTPS-only apps |
| Age rating | Complete questionnaire in App Store Connect |

**Export compliance (encryption)**

Liaison Officer uses HTTPS for API calls (standard TLS). In App Store Connect you will be asked whether the app uses encryption. Most teams answer:

- Uses encryption → **Yes**
- Exempt under Category 5 / mass market → **Yes** (if only standard HTTPS)

Optionally add to `Info.plist` after legal review:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### Step 6 — Register your Bundle ID early

Before first upload, register **`com.bel.liaisonOfficer`**:

1. [developer.apple.com/account/resources/identifiers/list](https://developer.apple.com/account/resources/identifiers/list)
2. **+** → **App IDs** → **App**
3. Description: `Liaison Officer`
4. Bundle ID: **Explicit** → `com.bel.liaisonOfficer`
5. Enable capabilities you need now or soon:
   - **Push Notifications** (enable before FCM — can register now, implement later)
6. Register

This ID must match `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`.

### Step 7 — Pre-launch timeline (typical)

| Week | Activity |
|------|----------|
| Week 0 | Enroll Apple Developer Program; wait for approval |
| Week 0–1 | Register Bundle ID; set up Xcode signing on Mac |
| Week 1 | First `flutter build ipa`; upload to TestFlight internal |
| Week 1–2 | QA on physical iPhone; fix crashes and url_launcher schemes |
| Week 2 | Complete App Privacy, screenshots, metadata |
| Week 2–3 | Submit for App Review (24–48 h typical; longer if rejected) |
| Week 3+ | Release to App Store |

### Common blockers at account stage

| Problem | What to do |
|---------|------------|
| Enrollment fails — no 2FA | Enable two-factor authentication on Apple ID |
| D-U-N-S mismatch | Legal name/address must match Apple enrollment exactly |
| “Authority to sign” rejected | Account Holder must be verified executive; provide HR letter |
| Xcode not found (`flutter doctor`) | Install full Xcode; run `sudo xcode-select -s /Applications/Xcode.app` |
| No physical device | Borrow iPhone for TestFlight; push requires real device |
| Bundle ID typo | Cannot change after first upload; create new ID if wrong |
| Apple ID on personal email | Create org-owned Apple ID before production release |
| Membership expired | Renew $99/year or all signing/upload stops immediately |

Once B.1 is complete and you can access App Store Connect + Xcode signing, proceed to [B.2 Prepare this app for App Store](#b2-prepare-this-app-for-app-store).

## B.2 Prepare this app for App Store

### Bundle ID and display name

- **Bundle ID:** `com.bel.liaisonOfficer`
- **Display name:** `Liaison Officer` (`ios/Runner/Info.plist`)

Register the bundle ID in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) before first upload.

### Code signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target → **Signing & Capabilities**
3. Team: your Apple Developer team
4. Enable **Automatically manage signing** for development
5. For release: **Distribution** certificate + **App Store** provisioning profile

### Build commands

```bash
# Flutter IPA (requires Xcode, signing configured)
flutter build ipa --release

# Output under build/ios/ipa/

# Alternative: Archive in Xcode
# Product → Archive → Distribute App → App Store Connect
```

### Export compliance

In App Store Connect, answer encryption questions. For standard HTTPS/TLS only:

- Often qualifies for exemption
- Add to `Info.plist` if applicable:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

(Confirm with your security team before setting.)

## B.3 Permissions and Info.plist

### Current state

`ios/Runner/Info.plist` has **no** privacy usage descriptions — correct for current features (no camera, mic, location, photo library prompts).

### url_launcher (phone, WhatsApp, maps)

If external apps fail to open on iOS, add query schemes to `Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>tel</string>
  <string>sms</string>
  <string>https</string>
  <string>whatsapp</string>
</array>
```

### When push notifications are added

1. Xcode → **Signing & Capabilities** → **+ Capability** → **Push Notifications**
2. Enable **Background Modes** → **Remote notifications**
3. Create APNs key in Apple Developer portal (or use Firebase which manages APNs)
4. User sees system permission dialog on first push request

### Future usage description keys

| Key | When needed |
|-----|-------------|
| `NSCameraUsageDescription` | LO profile photo capture |
| `NSPhotoLibraryUsageDescription` | Pick profile photo from gallery |
| `NSLocationWhenInUseUsageDescription` | Live venue navigation |
| `NSUserTrackingUsageDescription` | Only if advertising/tracking (not current scope) |

Apple **rejects** apps that request sensitive permissions without clear in-app justification strings.

## B.4 App Store Connect setup (step-by-step)

### 1. Certificates and identifiers

1. **Identifiers** → App IDs → register `com.bel.liaisonOfficer`
2. Enable capabilities as needed (Push later)
3. **Certificates** → Apple Distribution certificate
4. **Profiles** → App Store distribution profile

### 2. Create app record

1. [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → **+**
2. Platform: iOS
3. Name: Liaison Officer
4. Primary language
5. Bundle ID: `com.bel.liaisonOfficer`
6. SKU: e.g. `liaison-officer-ios`

### 3. App Information

| Field | Suggestion |
|-------|------------|
| Category | Business or Productivity |
| Content rights | Confirm you own or licensed content |
| Age rating | Complete questionnaire |

### 4. Pricing and availability

- Price: Free
- Availability: select countries/regions

### 5. App Privacy (nutrition labels)

Mirror Android Data Safety:

- Contact info (email)
- User content (task/travel notes if synced)
- Identifiers (device token when push enabled)
- Data linked to user vs not linked — document accurately

### 6. Prepare for Submission (version page)

| Asset | Requirement |
|-------|-------------|
| Screenshots | 6.7" display minimum set; add 6.5", 5.5" if supporting |
| App preview video | Optional |
| Promotional text | Optional, 170 chars |
| Description | Full feature list |
| Keywords | Comma-separated, 100 chars max |
| Support URL | Required |
| Privacy policy URL | Required |
| Version | Match `pubspec.yaml` |
| Build | Select uploaded TestFlight build |

### 7. TestFlight → Review

1. Upload build via Xcode or `flutter build ipa`
2. **TestFlight** → internal testing (team)
3. External testing (optional beta)
4. **Submit for Review** → production

### 8. Review notes (important)

Include in **App Review Information**:

```
Demo account:
Email: liaison@test.com
OTP: 123456 (tap "Send OTP" on login screen, then enter OTP)

This is a Liaison Officer (LO) workflow app for managing assigned VIP/delegate
profiles, travel updates, tasks, and in-app notifications during events.
```

## B.5 Common App Store rejection reasons

| Guideline | Issue | Prevention |
|-----------|-------|------------|
| 2.1 Performance | Crashes, blank screens | Test release on physical iPhone/iPad |
| 2.1 | Broken login | Provide working demo OTP path |
| 4.2 Design | "Minimum functionality" / too demo | Ensure core LO flows work end-to-end |
| 5.1.1 Privacy | Missing or wrong privacy policy | Host policy; match App Privacy labels |
| 5.1.2 | Data use without consent | Permission strings before sensitive APIs |
| 2.3.1 | Hidden features | Store description matches app |
| 2.5.1 | Software requirements | Build with current Xcode/iOS SDK |
| External links | tel/maps/WhatsApp fail | Add `LSApplicationQueriesSchemes` |
| Metadata | Screenshots don't match UI | Capture from production build |
| Export | Encryption questions unanswered | Complete compliance section |

Review typically takes **24–48 hours** (can be longer).

---

# Part C — Pre-launch checklist (both stores)

Use this unified checklist before submitting. For deeper QA gates, see [production-readiness-requirements.md](./production-readiness-requirements.md) §16 (Review Gates).

## Build and signing

- [ ] `flutter test` passes
- [ ] `flutter build appbundle --release` succeeds (Android)
- [ ] `flutter build ipa --release` succeeds (iOS)
- [ ] Android release uses **upload keystore**, not debug
- [ ] iOS distribution certificate and provisioning profile valid
- [ ] Version/build incremented in `pubspec.yaml`

## Legal and support

- [ ] Privacy policy published (HTTPS URL)
- [ ] Terms of service (if required by org)
- [ ] Support email or support page live
- [ ] Data safety (Play) and App Privacy (Apple) completed accurately

## Store assets

- [ ] App icon (Play 512×512; Apple via Xcode asset catalog)
- [ ] Feature graphic (Play 1024×500)
- [ ] Screenshots: Delegates, Tasks, Travel Updates, Notifications
- [ ] Short and full descriptions written
- [ ] Release notes for v1.0.0

## App behavior

- [ ] Login + OTP demo path works on release builds
- [ ] Delegate list, dossier, tasks, travel save, notifications verified
- [ ] Phone / WhatsApp / maps links tested on real devices
- [ ] Light and dark mode acceptable on key screens
- [ ] No hardcoded secrets in repo (API keys, keystore passwords, proxy passwords)
- [ ] Crash reporting configured (recommended: Firebase Crashlytics or Sentry)

## Reviewer access

- [ ] Demo credentials in Play **App access** and App Store **Review notes**
- [ ] Instructions explain OTP flow clearly

## Post-launch

- [ ] Monitor crash rates in Play Console / App Store Connect
- [ ] Plan hotfix process (`versionCode` / build number bump)
- [ ] Staged rollout on Play (recommended for first production release)

---

# Part D — Notifications (all approaches for Liaison Officer)

This section covers **every practical notification method** for LO.9.4, the **current implementation**, and a **recommended production path**.

## D.1 What the app does today

| Component | File | Behavior |
|-----------|------|----------|
| In-portal feed | `lib/features/liaison_officer/presentation/screens/lo_notifications_screen.dart` | `LoNotificationStore` singleton; unread badge; filters by type |
| Mock email | `lib/core/notifications/mock_email_notifier.dart` | Writes to local outbox (`email_outbox` key); debug print only |
| Triggers | Travel save, task status change, assignment seed | Portal notification + mock email to nodal officer |
| Upcoming task timer | `lib/features/liaison_officer/data/services/upcoming_task_reminder_service.dart` | Checks every 60s; fires 60 min before `scheduledDate` |

### LO.9.4 requirements vs current state

| Requirement | Status |
|-------------|--------|
| Email alerts | Mock only (local outbox) |
| In-portal notifications | Implemented |
| New task / travel / delegate updates | Partial (local triggers on LO actions only) |
| Upcoming task alerts | In-app + mock email when app running |
| Delivery when app killed | **Not implemented** |
| Server-driven push | **Not implemented** |

### Architecture diagram

**Current**

```
Travel save / Task status / Assignment seed
        │
        ├──► LoNotificationStore (in-app feed)
        └──► MockEmailNotifier (local outbox)

UpcomingTaskReminderService (Timer, 60 min lead)
        │
        ├──► LoNotificationStore
        └──► MockEmailNotifier
```

**Target production**

```
Backend (LO API)
        │
        ├──► FCM ──► Android / iOS system tray
        ├──► APNs (via Firebase or direct)
        ├──► Email service (SendGrid / SES) ──► Nodal officer + LO inbox
        └──► WebSocket (optional) ──► In-app badge while foreground

Device
        │
        ├──► NotificationService (Flutter) ──► LoNotificationStore + OS tray
        └──► flutter_local_notifications (scheduled reminders backup)
```

---

## D.2 Notification methods (complete comparison)

### 1. In-app notification feed (current)

**How it works:** Events insert into `LoNotificationStore`; UI reads from memory; badge shows unread count.

**Packages:** None (built-in).

**Permissions:** None.

**Backend:** Optional sync API to persist history across devices.

**Pros:** Simple, full UI control, works offline, no store permission prompts.

**Cons:** User sees nothing when app is closed; lost on app restart (current singleton is not persisted).

**LO.9.4 fit:** Required — keep as notification **history** and in-app inbox.

**Improvements to plan:**
- Persist notifications to SQLite/SharedPreferences
- Sync read/unread from backend

---

### 2. Local notifications (device-scheduled)

**How it works:** App schedules alarms on the device OS for upcoming tasks (e.g. 60 minutes before `LoTaskAssignment.scheduledDate`).

**Packages:**
- `flutter_local_notifications`
- `timezone` (accurate scheduling)
- `flutter_timezone` (device timezone)

**Android permissions:**
- `POST_NOTIFICATIONS` (Android 13+, runtime prompt)
- `RECEIVE_BOOT_COMPLETED` (reschedule after reboot)
- Exact alarm: `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` (API 31+ for precise task reminders)

**iOS permissions:**
- User notification permission dialog (first schedule)

**Backend:** None required; schedule from local task data.

**Pros:** Works offline; reliable for time-based LO reminders; no server cost.

**Cons:** Not suitable for server-initiated events (new assignment from nodal officer); schedules lost if user clears app data unless rebuilt on launch.

**LO.9.4 fit:** **High** — upcoming scheduled task alerts (backup/complement to push).

**Implementation sketch:**

```dart
// On task load or save:
await flutterLocalNotificationsPlugin.zonedSchedule(
  id: task.id.hashCode,
  title: 'Upcoming: ${task.taskTitle}',
  body: '${task.delegateName} · ${task.location}',
  scheduledDate: task.scheduledDate.subtract(Duration(minutes: 60)),
  ...
);
```

---

### 3. Firebase Cloud Messaging (FCM) — recommended for push

**How it works:** Backend sends message to FCM → Google/Apple delivers to device → app handles foreground/background.

**Packages:**
- `firebase_core`
- `firebase_messaging`
- `flutter_local_notifications` (display foreground notifications on Android)

**Setup:**
1. Create Firebase project
2. Add Android app (`com.bel.liaison_officer`) and iOS app (`com.bel.liaisonOfficer`)
3. Download `google-services.json` → `android/app/`
4. Download `GoogleService-Info.plist` → `ios/Runner/`
5. Enable Push in Apple Developer; upload APNs key to Firebase

**Android permissions:**
- `INTERNET`
- `POST_NOTIFICATIONS` (Android 13+)

**iOS:**
- Push Notifications capability
- Background Modes → Remote notifications
- User permission dialog

**Backend events to send:**

| Event | Payload example | Recipient |
|-------|-----------------|-----------|
| `task.assigned` | task title, delegate, time | LO email/device |
| `task.updated` | status change | LO + nodal officer |
| `travel.updated` | delegate name | Nodal officer |
| `delegate.assigned` | delegate list | LO |
| `task.due_soon` | 60 min warning | LO |

**Backend API:**

```
POST /api/devices/register
{ "email": "...", "fcmToken": "...", "platform": "android|ios" }

POST /api/notifications/send  (internal/admin)
{ "event": "task.assigned", "loEmail": "...", "data": { ... } }
```

**Pros:** Industry standard; one pipeline for Android + iOS; scales to many LOs.

**Cons:** Requires Firebase + backend; APNs setup for iOS; token refresh handling.

**LO.9.4 fit:** **Primary** for remote alerts.

---

### 4. Apple Push Notification service (APNs) direct

**How it works:** Backend sends directly to APNs (bypassing FCM on iOS only).

**When to use:** iOS-only product or policy restricting Firebase.

**Packages:** `flutter_apns` or native platform channels; most teams still use FCM as APNs proxy.

**Pros:** No Google dependency on iOS path.

**Cons:** Separate Android solution (FCM) still needed; more ops complexity.

**LO.9.4 fit:** Use only if Firebase is not allowed; otherwise prefer FCM (method 3).

---

### 5. Email notifications (production)

**How it works:** Backend sends real email via SMTP or provider API when events occur.

**Replace:** `MockEmailNotifier` in `lib/core/notifications/mock_email_notifier.dart`

**Providers:** SendGrid, Amazon SES, Mailgun, Microsoft Graph (org email)

**Backend:**

```
POST /internal/notifications/email
{
  "to": "nodal.officer@example.com",
  "template": "travel_updated",
  "data": { "delegateName": "...", "loEmail": "..." }
}
```

**Permissions:** None on device.

**Pros:** Required for nodal officer workflow; auditable; works without app installed.

**Cons:** Not instant on device; spam/filter issues; requires templates and bounce handling.

**LO.9.4 fit:** **Required** for nodal officer email alerts.

**Flutter role:** Trigger email via API after LO saves travel/task; do not embed SMTP credentials in app.

---

### 6. SMS notifications

**How it works:** Backend sends SMS via Twilio, AWS SNS, etc.

**Use cases:** Urgent VIP arrival, critical schedule change.

**Permissions:** None on device.

**Pros:** High visibility.

**Cons:** Cost per message; regulatory compliance (TRAI/DND in India, etc.); user consent required.

**LO.9.4 fit:** Optional for **urgent** tier only.

---

### 7. WebSocket / Server-Sent Events (SSE)

**How it works:** Persistent connection while app is foreground; server pushes events instantly to update badge and feed.

**Packages:** `web_socket_channel` or `dio` SSE

**Backend:** WebSocket gateway subscribed per LO email/session

**Permissions:** `INTERNET` only

**Pros:** Instant in-app updates without polling

**Cons:** Does not work when app backgrounded/killed; battery and connection management

**LO.9.4 fit:** Supplement for **live badge** while LO has app open; combine with FCM for background.

---

### 8. Background fetch / periodic sync

**How it works:** OS wakes app periodically to fetch new assignments/notifications.

**Packages:** `workmanager` (Android); iOS `BGAppRefreshTask` (limited)

**Permissions:** Background modes (iOS)

**Pros:** Fallback when push unavailable

**Cons:** Not reliable on iOS; unpredictable timing; Play/Android battery restrictions

**LO.9.4 fit:** Low priority; use only as fallback.

---

### 9. Data / silent push

**How it works:** FCM data-only message (no visible notification) triggers background sync.

**Use case:** Refresh task list and `LoNotificationStore` without alerting user.

**Requirements:**
- iOS: `content-available: 1`, background remote notification capability
- Android: high-priority data messages

**LO.9.4 fit:** Sync assignments silently before showing a visible "New task" notification.

---

### 10. Web Push (Flutter web)

**How it works:** Browser push via service worker + FCM web or VAPID.

**Packages:** `firebase_messaging` (web support), service worker in `web/`

**Permissions:** Browser notification permission

**LO.9.4 fit:** Only if LO portal continues to ship as **web** (`flutter build web`); separate from Play/App Store mobile apps.

**Note:** Current web build uses SharedPreferences instead of sqflite — test notifications and task storage on web separately.

---

## D.3 Permission summary for notifications

| Method | Android | iOS |
|--------|---------|-----|
| In-app feed | None | None |
| Local notifications | `POST_NOTIFICATIONS`, optional exact alarm | Notification permission |
| FCM push | `POST_NOTIFICATIONS`, `INTERNET` | Push capability + user permission |
| Email/SMS | None (server-side) | None |
| WebSocket | `INTERNET` | `INTERNET` |
| Web Push | Browser prompt | N/A (desktop browsers) |

---

## D.4 Recommended production architecture

1. **Keep** `LoNotificationStore` as the in-app inbox (persist to local DB).
2. **Add** `NotificationService` facade:
   - Receives FCM messages
   - Inserts into `LoNotificationStore`
   - Shows system notification via `flutter_local_notifications`
3. **Add** FCM + device token registration on login (`AuthBloc` success).
4. **Schedule** local notifications for upcoming tasks (60 min lead) as backup.
5. **Replace** `MockEmailNotifier` with `POST /api/notifications/email` on backend.
6. **Backend** fan-out service:
   - Subscribes to domain events: `TaskAssigned`, `TravelUpdated`, `TaskDueSoon`
   - Sends FCM + email (and optional SMS for urgent)

### Suggested backend event schema

```json
{
  "eventId": "uuid",
  "type": "task.assigned",
  "recipientEmail": "liaison@test.com",
  "title": "New task assigned",
  "body": "Airport Pickup for Dr. Michael Thompson at 14:00",
  "data": {
    "taskTitle": "Airport Pickup",
    "delegateName": "Dr. Michael Thompson",
    "scheduledDate": "2026-08-24T14:00:00+05:30",
    "location": "T2 Arrivals"
  },
  "channels": ["push", "email", "in_app"]
}
```

---

## D.5 Implementation phases (recommended order)

### Phase 1 — Local notifications (no backend)

- Add `flutter_local_notifications`
- Schedule/cancel on task load from `LoTaskAssignment`
- Request `POST_NOTIFICATIONS` on Android 13+
- **Outcome:** Upcoming task reminders work offline

### Phase 2 — Firebase + FCM

- Firebase project, config files, push capabilities
- Token registration API
- Handle foreground/background/terminated states
- **Outcome:** Server can push task/travel/delegate alerts

### Phase 3 — Backend email

- Email templates for nodal officer and LO
- Remove mock outbox from production builds (keep for dev/demo flag)
- **Outcome:** Real LO.9.4 email alerts

### Phase 4 — Preferences and sync

- Per-LO settings: push on/off, email on/off, reminder lead time (30/60/120 min)
- Persist notification history; sync read state with backend
- **Outcome:** Production-grade notification UX

---

## D.6 Testing notifications

| Method | How to test |
|--------|-------------|
| In-app | Trigger travel save / task status change in app |
| Mock email | Inspect `email_outbox` in local storage (debug) |
| Local | Schedule task 2 minutes ahead in test build |
| FCM | Firebase Console → Send test message to device token |
| Email | Staging SMTP + mail catcher (Mailhog) |
| iOS push | Physical device required (simulator limited for push) |
| Android push | Emulator with Google Play image or physical device |

---

## D.7 Flutter packages reference

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_messaging` | FCM push |
| `flutter_local_notifications` | Local + foreground display |
| `timezone` | TZ-aware scheduling |
| `permission_handler` | Optional unified permission UX |
| `workmanager` | Background tasks (Android) |

Add to `pubspec.yaml` only when implementing each phase — do not add all at once for store v1 unless required.

---

## D.8 Security and compliance notes

- Never embed SMTP, FCM server keys, or Twilio secrets in the Flutter app
- Device tokens are user-linked — treat as personal data in privacy policy
- Allow users to disable non-essential notifications (platform settings + in-app prefs)
- Log notification delivery on backend for nodal officer audit trail
- For government/event apps, align retention and access with org IT policy

---

## Quick reference commands

```bash
# Android release bundle (Play Store)
flutter build appbundle --release

# Android release APK (sideload)
flutter build apk --release

# iOS release
flutter build ipa --release

# Web (separate deployment, not Play/App Store)
flutter build web --release

# Tests before submission
flutter test
```

---

## Document history

| Version | Date | Notes |
|---------|------|-------|
| 1.0 | 2026-08-24 | Initial guide: Play + App Store launch, permissions, notifications |


