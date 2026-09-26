# CAP API endpoints — Liaison Officer app

Base URL: `http://35.244.48.209:8080`  
OpenAPI: `http://35.244.48.209:8080/v3/api-docs`  
Swagger UI: http://35.244.48.209:8080/swagger-ui/index.html

Verified against live OpenAPI (`Aero India Event Management API` v1). Tag: **My LO (Liaison Officer portal)** (+ Authentication, Notifications).

Corporate networks: set `NO_PROXY=35.244.48.209` (or `*`) so the proxy does not block this host.

Envelope: `{ success, message, data, errorCode, timestamp }`  
Auth header: `Authorization: Bearer <accessToken>`

## Coverage

| Status | Meaning |
|--------|---------|
| **Swagger-confirmed** | Path exists in live `/v3/api-docs` |
| **Wired** | Dio repository calls this path when `USE_MOCK_API=false` |
| **Offline queue** | On failure, Hive stores the write and retries on next portal load |
| **Not in Swagger** | App may still call it; backend contract is unverified / soft-fail |

## Help manual → API map

| Help section | Primary APIs |
|--------------|--------------|
| 1. Access & Login | `/api/auth/*` |
| 2. Complete & Submit Profile | `GET/PUT /app/my-lo/me`, document `POST`s, languages, experiences |
| 3. View Delegates | `GET /app/my-lo/me/delegates`, `…/nominations`, `…/vehicles` |
| 4. Update Travel | `PUT …/arrival-flight`, `PUT …/travel` |
| 5. Manage Tasks | `GET /app/my-lo/me/tasks`, `PUT …/tasks/{taskId}/status` |
| 6. Notifications | `/app/notifications/mine*` |
| 7. Help & Support | None (client-generated manual) |

Full crosswalk + mobile extras: [`lo-help-api-and-requirements.md`](lo-help-api-and-requirements.md). User manual: [`lo-help-and-support-manual.md`](lo-help-and-support-manual.md).

---

### Authentication — Swagger-confirmed · wired

| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/auth/check-email` | `{ email }` |
| GET | `/api/auth/captcha` | `{ captchaId, imageBase64 }` |
| POST | `/api/auth/request-otp` | `{ email, captchaId, captchaAnswer }` |
| POST | `/api/auth/resend-otp` | `{ email }` |
| POST | `/api/auth/verify-otp` | `{ email, otp }` → JWT |

No password login endpoints under `/api/auth/*` for LO.

### My LO portal — Swagger-confirmed · wired

| Method | Path | Notes |
|--------|------|-------|
| GET | `/app/my-lo/me` | My Liaison Officer profile |
| PUT | `/app/my-lo/me` | Update my Liaison Officer profile |
| POST | `/app/my-lo/me/photo` | Document upload |
| POST | `/app/my-lo/me/signature` | Document upload |
| POST | `/app/my-lo/me/aadhaar-front` | Document upload |
| POST | `/app/my-lo/me/aadhaar-back` | Document upload |
| POST | `/app/my-lo/me/org-badge-front` | Document upload |
| POST | `/app/my-lo/me/org-badge-back` | Document upload |
| GET/POST | `/app/my-lo/me/experiences` | Prior LO experience list / add |
| PUT | `/app/my-lo/me/experiences/{id}` | Update experience row (Swagger; wire if editing in place) |
| DELETE | `/app/my-lo/me/experiences/{id}` | Delete experience row |
| GET/POST | `/app/my-lo/me/languages` | Languages known |
| DELETE | `/app/my-lo/me/languages/{rowId}` | Remove language; client often replace-set |
| GET | `/app/my-lo/me/delegates` | Delegates assigned to me |
| GET | `/app/my-lo/me/assignments/{assignmentId}/nominations` | Events my delegate is nominated for |
| GET | `/app/my-lo/me/assignments/{assignmentId}/vehicles` | Vehicles allocated to my delegate |
| PUT | `/app/my-lo/me/assignments/{assignmentId}/travel` | Arrival + departure travel (offline queue) |
| PUT | `/app/my-lo/me/assignments/{assignmentId}/arrival-flight` | Actual arrival flight |
| GET | `/app/my-lo/me/tasks` | Tasks assigned to me |
| PUT | `/app/my-lo/me/tasks/{taskId}/status` | Query: `statusCode`, optional `remarks` (offline queue) |

Itinerary has **no dedicated API** — mobile composes travel fields + nominations (+ vehicle pickup).

### Notifications — Swagger-confirmed · wired

| Method | Path | Notes |
|--------|------|-------|
| GET | `/app/notifications/mine` | In-app feed |
| POST | `/app/notifications/mine/{id}/read` | Mark one read |
| POST | `/app/notifications/mine/read-all` | Mark all read |
| GET | `/app/notifications/mine/unread-count` | Badge count |

### Other wired (Swagger-confirmed, supporting)

| Method | Path | Notes |
|--------|------|-------|
| GET | `/app/committee/bv-quota/badge/{passId}/download` | LO badge PDF download |

### Not in Swagger

| Method | Path | App behaviour | Notes |
|--------|------|---------------|-------|
| POST | `/app/my-lo/me/issues` | Wired + Hive offline queue + Share escalate | Soft-fail if backend rejects; **not** listed under My LO in OpenAPI. Do not confuse with `/app/cons-issues` (conservancy). |
| — | Help / PDF user manual | Client-only | No `/app/help` or manual download API. Web PDF / mobile markdown share. |
| — | LO family-members CRUD under `/app/my-lo/me/**` | N/A | Web “family” action is outside My LO OpenAPI surface. |

---

## Flutter dart-defines

```bash
flutter run \
  --dart-define=API_BASE_URL=http://35.244.48.209:8080 \
  --dart-define=USE_MOCK_API=false
```

Mock: `liaison@test.com` — OTP `123456`

## Related docs

- Help manual: [`lo-help-and-support-manual.md`](lo-help-and-support-manual.md)
- Help ↔ API requirements: [`lo-help-api-and-requirements.md`](lo-help-api-and-requirements.md)
- Requirements matrix: [`lo-requirements-matrix.md`](lo-requirements-matrix.md)
- Web ↔ mobile inventory: [`web-mobile-feature-inventory.md`](web-mobile-feature-inventory.md)
