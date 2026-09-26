# LO Help sections ↔ APIs & app requirements

Crosswalk from the [Help & Support manual](lo-help-and-support-manual.md) to CAP APIs ([Swagger UI](http://35.244.48.209:8080/swagger-ui/index.html)) and mobile-specific requirements beyond the web help text.

Base URL: `http://35.244.48.209:8080` · Endpoint catalog: [`api-lo-endpoints.md`](api-lo-endpoints.md) · Status matrix: [`lo-requirements-matrix.md`](lo-requirements-matrix.md)

---

## Section → API map

| Help section | Required APIs (Swagger-confirmed) | Mobile extras / notes |
|--------------|-----------------------------------|------------------------|
| **1. Access & Login** | `POST /api/auth/check-email`, `GET /api/auth/captcha`, `POST /api/auth/request-otp`, `POST /api/auth/resend-otp`, `POST /api/auth/verify-otp` | CAPTCHA required before OTP; JWT in session store; no password |
| **2. Complete & Submit Profile** | `GET/PUT /app/my-lo/me`; `POST` photo, signature, aadhaar-front/back, org-badge-front/back; `GET/POST/DELETE` languages; `GET/POST/PUT/DELETE` experiences | “Atomic Submit” is **client orchestration** of multiple calls on final Submit; wizard holds draft locally until then. Step 3 UI: **Has LO Experience?** Yes/No + experience table (not a separate “years” field). Read-only view may show **Load failed** document previews even after upload — CAP preview/fetch, not missing upload APIs |
| **3. View Delegates** | `GET /app/my-lo/me/delegates`; `GET …/assignments/{id}/nominations`; `GET …/assignments/{id}/vehicles`; arrival via `PUT …/arrival-flight` / `travel` | Web Actions: eye, family, nominations, vehicle, arrival. Nominations/vehicles/arrival are Swagger My LO; **family** has no `/app/my-lo/me/**` path. Mobile: list icons → detail/sheets |
| **4. Update Travel** | `PUT …/arrival-flight`; `PUT …/travel` | Offline queue on travel writes; movement kinds: arrival / transfer / venue_entry / departure |
| **5. Manage Tasks** | `GET /app/my-lo/me/tasks`; `PUT …/tasks/{taskId}/status` | Grouped by delegate; web Actions uses a sync-style status control (opens picker); optional remarks; offline status queue |
| **6. Notifications** | `GET /app/notifications/mine`; `POST …/read`, `…/read-all`; `GET …/unread-count` | AppBar CAP inbox + Alerts tab; local OS reminders; optional FCM (`ENABLE_FCM`) |
| **7. Help & Support** | None | Avatar → Help; Download/share user manual is **client-only** (no PDF API) |

---

## Other APIs used by this app

| API | Swagger | Purpose |
|-----|---------|---------|
| `GET /app/committee/bv-quota/badge/{passId}/download` | Yes | LO badge PDF |
| `POST /app/my-lo/me/issues` | **No** | Issue reporting — wired with soft-fail + Hive queue + Share escalate |

Path constants: [`lib/core/config/api_config.dart`](../lib/core/config/api_config.dart).

---

## Requirements beyond Help & Support copy

| Area | Requirement | Status / notes |
|------|-------------|----------------|
| LO-only shell | Delegates · Tasks · Alerts (+ profile, help, theme) | Done — `LoPortalShell` |
| Accommodation | Struck from LO mobile scope | **SKIP** |
| Issue reporting | Report exceptions during coordination | Done locally; CAP POST not in OpenAPI |
| Offline durability | Queue task status + travel (+ issues) | Hive flush on portal load |
| Theme | Light / dark | Avatar menu |
| Push (FCM) | Background push when killed | Opt-in `ENABLE_FCM`; see store/notifications guide |
| Mock mode | Offline UI without CAP | `USE_MOCK_API=true`; demo OTP `123456` |
| Network | Corporate proxy bypass for CAP host | `NO_PROXY=35.244.48.209` |

---

## Explicitly out of scope

- Committee Nodal / Org Rep admin UIs (nomination, allocation, review)
- Accommodation booking modules
- Conservancy `/app/cons-issues*` (different product — not LO issue reporting)
- Dedicated LO family-members CRUD under `/app/my-lo/me/**` (not in My LO OpenAPI)
- Backend PDF generation for the user manual

---

## Gaps to track

1. **`POST /app/my-lo/me/issues`** — app depends on it; confirm or add to CAP OpenAPI, or document official alternative.
2. **`PUT /app/my-lo/me/experiences/{id}`** — present in Swagger; ensure mobile edit path uses it if in-place edit is required (delete + recreate may already cover updates).
3. **User manual PDF** — web generates client-side; mobile shares markdown; no shared CAP endpoint.
4. **In-app Help screen** — [`help_support_screen.dart`](../lib/features/liaison_officer/presentation/screens/help_support_screen.dart) uses a shorter mobile-oriented outline; this repo manual is the full portal-aligned source. Sync UI later if desired.
5. **Profile document previews** — live web My Profile view can show **Load failed** / **Preview unavailable** for all six slots after uploads; fix is on CAP preview/fetch, not Flutter upload wiring.
6. **LO family members** — web My Delegates row action; no My LO Swagger endpoint under `/app/my-lo/me/**`.

---

## Run (live CAP)

```bash
# Windows PowerShell
$env:NO_PROXY='35.244.48.209'
flutter run `
  --dart-define=USE_MOCK_API=false `
  --dart-define=API_BASE_URL=http://35.244.48.209:8080
```
