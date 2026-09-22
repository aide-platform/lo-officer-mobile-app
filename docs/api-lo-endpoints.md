# CAP LO API endpoints (Committee Automation Portal)

Base URL: `http://35.244.48.209:8080`  
OpenAPI: `http://35.244.48.209:8080/v3/api-docs`  
Swagger UI: `http://35.244.48.209:8080/swagger-ui/index.html`

Corporate networks: set `NO_PROXY=35.244.48.209` (or `*`) so the proxy does not block this host.

Envelope: `{ success, message, data, errorCode, timestamp }`  
Auth header: `Authorization: Bearer <accessToken>`

## Authentication

| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/auth/check-email` | `{ email }` |
| GET | `/api/auth/captcha` | `{ captchaId, imageBase64 }` |
| POST | `/api/auth/request-otp` | `{ email, captchaId, captchaAnswer }` |
| POST | `/api/auth/resend-otp` | `{ email }` |
| POST | `/api/auth/verify-otp` | `{ email, otp }` → JWT |

JWT: `accessToken`, `expiresInMs`, `userId`, `email`, `role`

## Session

| Method | Path |
|--------|------|
| GET | `/app/me` |

## My LO (LO.5 / LO.9)

| Method | Path |
|--------|------|
| GET/PUT | `/app/my-lo/me` |
| POST | `/app/my-lo/me/photo`, `signature`, `org-badge-front/back`, `aadhaar-front/back` |
| GET/POST | `/app/my-lo/me/experiences` |
| GET/POST | `/app/my-lo/me/languages` |
| GET | `/app/my-lo/me/delegates` |
| GET | `/app/my-lo/me/tasks` |
| PUT | `/app/my-lo/me/tasks/{taskId}/status?statusCode=` |
| PUT | `/app/my-lo/me/assignments/{assignmentId}/travel` |
| PUT | `/app/my-lo/me/assignments/{assignmentId}/arrival-flight` |
| GET | `/app/my-lo/me/assignments/{assignmentId}/vehicles` |
| GET | `/app/my-lo/me/assignments/{assignmentId}/nominations` |

## Organisation representative (LO.4)

| Method | Path |
|--------|------|
| GET | `/app/my-organisation/me` |
| GET/POST | `/app/my-organisation/me/los` |
| GET | `/app/my-organisation/me/los/{loId}` (read-only LO detail) |
| GET | `/app/my-organisation/me/los/import-template` |
| POST | `/app/my-organisation/me/los/bulk-import` (Excel/CSV bytes) |
| POST | `/app/my-organisation/me/los/{loId}/reminder` |
| POST | `/app/my-organisation/me/reminders/pending` |
| CRUD | `/app/org-sub-nodal-officers` (+ `/mine`) |

## Nodal officer (LO.2–LO.8)

| Method | Path |
|--------|------|
| CRUD | `/app/lo-org-types` (incl. activate/deactivate) |
| CRUD | `/app/lo-organisations` |
| CRUD | `/app/email-templates` |
| CRUD | `/app/do-letter-templates` (+ `/{id}/file` download/upload) |
| CRUD | `/app/lo-activities` |
| CRUD | `/app/liaison-officers` (+ `/{id}/experiences`, `/{id}/languages`) |
| CRUD | `/app/lo-assignments`, `/app/lo-assignments/delegates` |
| CRUD | `/app/lo-tasks` |
| GET | `/app/committee/bv-quota/mine` |
| POST | `/app/committee/bv-quota/assign-badge` (`personIds[]`) |
| GET | `/app/committee/bv-quota/badge/{passId}/download` |

### CAP caveat — LO org DO letter / nomination

Public OpenAPI does **not** document:

- `/app/lo-organisations/{id}/do-letter/preview`
- `/app/lo-organisations/{id}/do-letter/signed`
- `/app/lo-organisations/{id}/send-nomination`

The Flutter client:

1. Uses `/app/do-letter-templates` for template CRUD + PDF.
2. Resolves an org’s DO download from the template matching its org type.
3. Attempts the speculative LO-org paths above when live; on **404** or empty bytes, **client-generates** a filled PDF via `DoLetterPdfBuilder` (org name, head, designation, address, signing authority). AcroForm merge of arbitrary uploaded PDFs is not supported client-side.
4. On nomination send, templates tagged **DO Letter Communication** auto-attach the locally stored signed DO PDF when available.
5. Does **not** wire generic `/app/organisations/{id}/do-letter/*` (different module) to LO org IDs.

## Flutter dart-defines

```bash
flutter run \
  --dart-define=API_BASE_URL=http://35.244.48.209:8080 \
  --dart-define=USE_MOCK_API=false
```

Offline demo:

```bash
flutter run --dart-define=USE_MOCK_API=true
```

Mock emails: `liaison@test.com`, `org@test.com`, `admin@aeroindia.gov.in` — OTP `123456`
