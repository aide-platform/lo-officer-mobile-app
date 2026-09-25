# CAP API endpoints — Liaison Officer app

Base URL: `http://35.244.48.209:8080`  
OpenAPI: `http://35.244.48.209:8080/v3/api-docs`  
Swagger UI: `http://35.244.48.209:8080/swagger-ui/index.html`

Corporate networks: set `NO_PROXY=35.244.48.209` (or `*`) so the proxy does not block this host.

Envelope: `{ success, message, data, errorCode, timestamp }`  
Auth header: `Authorization: Bearer <accessToken>`

## Coverage

| Status | Meaning |
|--------|---------|
| **Wired** | Dio repository calls this path when `USE_MOCK_API=false` |
| **Offline queue** | On failure, Hive stores the write and retries on next portal load |

### Authentication — wired

| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/auth/check-email` | `{ email }` |
| GET | `/api/auth/captcha` | `{ captchaId, imageBase64 }` |
| POST | `/api/auth/request-otp` | `{ email, captchaId, captchaAnswer }` |
| POST | `/api/auth/resend-otp` | `{ email }` |
| POST | `/api/auth/verify-otp` | `{ email, otp }` → JWT |

### My LO portal — wired

| Method | Path | Notes |
|--------|------|-------|
| GET/PUT | `/app/my-lo/me` | Profile |
| POST | `/app/my-lo/me/photo`, `signature`, `org-badge-front/back`, `aadhaar-front/back` | |
| GET/POST | `/app/my-lo/me/experiences` | |
| DELETE | `/app/my-lo/me/experiences/{id}` | |
| GET/POST | `/app/my-lo/me/languages` | |
| DELETE | `/app/my-lo/me/languages/{rowId}` | Replace-set |
| GET | `/app/my-lo/me/delegates` | |
| GET | `/app/my-lo/me/tasks` | |
| PUT | `/app/my-lo/me/tasks/{taskId}/status?statusCode=` | Offline queue |
| PUT | `/app/my-lo/me/assignments/{assignmentId}/travel` | Offline queue (movement) |
| PUT | `/app/my-lo/me/assignments/{assignmentId}/arrival-flight` | |
| GET | `/app/my-lo/me/assignments/{assignmentId}/vehicles` | |
| GET | `/app/my-lo/me/assignments/{assignmentId}/nominations` | |
| POST | `/app/my-lo/me/issues` | Wired + Hive offline queue + Share escalate |
| GET | `/app/committee/bv-quota/badge/{passId}/download` | LO badge PDF |

### Notifications — wired

| Method | Path |
|--------|------|
| GET | `/app/notifications/mine` |
| POST | `/app/notifications/mine/{id}/read` |
| POST | `/app/notifications/mine/read-all` |
| GET | `/app/notifications/mine/unread-count` |

## Flutter dart-defines

```bash
flutter run \
  --dart-define=API_BASE_URL=http://35.244.48.209:8080 \
  --dart-define=USE_MOCK_API=false
```

Mock: `liaison@test.com` — OTP `123456`

## Related docs

- Requirements: [`lo-requirements-matrix.md`](lo-requirements-matrix.md)
- Web ↔ mobile inventory: [`web-mobile-feature-inventory.md`](web-mobile-feature-inventory.md)
