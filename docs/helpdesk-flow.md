# Help Desk — how it works

Liaison Officers (LOs) raise help desk queries from the **LO app**; the **LO Nodal** team answers them
in **aide-ui**. Everything is stored in **aide-service** (its own database tables). Attachments are
files on **media-services**. **eventservices is not used.**

| Repo | Branch | Part |
|---|---|---|
| `lo-officer-mobile-app` (Flutter) | `feat/helpdesk` | LO: raise queries, see replies, comment |
| `aide-service` (Spring Boot) | `feat/lo-helpdesk` | APIs + tables |
| `aide-ui` (React) | `feat/lo-helpdesk` | LO Nodal: query types + raised queries |

---

## 1. Big picture

```
 LO app (Flutter)                          aide-ui (React, LO Nodal)
 More ▸ Help Desk / FAQ ▸ Contact Support   Sidebar ▸ Help Desk
   list · Ask for Help · details+comments     tabs: Create Query Type | Raised Queries
        │  LO login token                          │  Nodal login token
        ▼                                          ▼
 aide-service /app/my-lo/me/helpdesk/*      aide-service /app/lo-helpdesk/*
        └──────────────┬───────────────────────────┘
                       ▼
        PostgreSQL  tdms.lo_helpdesk_query_types
                    tdms.lo_helpdesk_tickets
                    tdms.lo_helpdesk_messages
                       │ attachments (upload)
                       ▼
        media-services  POST {app.media-service.base-url}/dpvu   (dp: eidenghd)
                        → public CDN URL stored on the ticket / message
```

---

## 2. Database (aide-service)

Created by `src/main/resources/db/patch_lo_helpdesk.sql` (safe to re-run; also adds the sidebar menu
and permission chips).

**`tdms.lo_helpdesk_query_types`** — `id`, `name` (unique, case-insensitive), `is_active`, `sort_order`, audit columns.

**`tdms.lo_helpdesk_tickets`** — one row per query:

| Column | Meaning |
|---|---|
| `ticket_no` | `HD000001`, `HD000002`, … (sequence `tdms.lo_helpdesk_ticket_no_seq`) |
| `query_type_id` | → query type |
| `title`, `description` | from the form |
| `attachments` | JSON array of CDN URLs (max 5) |
| `status` | `OPEN` (new, waiting for the team) → `IN_PROGRESS` (team replied) → `CLOSED` |
| `closed_type`, `closed_at`, `closed_by_user_id` | how / when / who closed it (`CHAT` or `CALL`) |
| `source` | `ANDROID`, `IOS` or `WEB` |
| **`raised_by_user_id`** | **`mdms.users.id` of the LO who raised it** (ownership) |
| `liaison_officer_id` | `mdms.liaison_officers.id` of that LO |
| `raised_by_name`, `raised_by_email`, `raised_by_phone` | snapshot for display |
| `read_by_team` | false while the LO has added something the team has not opened |
| `last_activity_at` | last message / status change (lists sort by it) |

**`tdms.lo_helpdesk_messages`** — the conversation: `ticket_id`, `sender_type` (`LO`, `TEAM`, `SYSTEM`),
`sender_user_id`, `sender_name`, `body`, `attachments`, `created_at`. `SYSTEM` = automatic notes
(query transferred).

---

## 3. LO app

**Where:** More ▸ **Help Desk** (always shown), and FAQ ▸ "Still have questions? / Contact Support".

**Help Desk list** — the LO's own queries (latest activity first, 10 per page, load more on scroll),
search, pull to refresh, status (Open / In progress / Closed), **Ask for Help** button.

**Ask for Help** — a fixed form:

| Field | Rules |
|---|---|
| Select your Query | required; active query types from the Nodal team |
| Query Title | required, max 200 characters |
| Description | required, max 4000 characters |
| Attachments | optional; up to **5** files; **JPEG, JPG, PNG, PDF**; **5 MB** each |

**Query details** — the query, the conversation (LO comments, help desk replies, notes), and a comment
box with attachments while the query is not closed.

---

## 4. aide-ui (LO Nodal)

Sidebar ▸ **Help Desk** (`/lo-nodal/helpdesk`):

* **Create Query Type** — create, rename, activate / deactivate query types.
* **Raised Queries** — filters (search, status, query type, source, closed by), table (unread dot),
  details panel (query, raiser name / email / phone, conversation), **reply** with attachments,
  **close** (resolved by chat / call, optional closing message), **transfer** to another query type,
  **Export to Excel** (ticket no., title, type, status, closed by, raiser name / email / phone, source, description, dates).

Access: Admin and LO Nodal: everything. Sub Nodal Officers per permission chip:
`LO_HELPDESK_VIEW`, `LO_HELPDESK_REPLY`, `LO_HELPDESK_EDIT` (query types, close, transfer),
`LO_HELPDESK_EXPORT`. Buttons the user may not use are hidden.

---

## 5. Flow and notifications

```
LO raises query ──► status OPEN, read_by_team=false ──► in-app alert to LO Committee nodals
LO comments      ──► read_by_team=false (status unchanged)
Team opens it    ──► read_by_team=true
Team replies     ──► status IN_PROGRESS ──► in-app alert to the LO ("Help desk replied on HD…")
Team transfers   ──► query type changed + SYSTEM note in the conversation
Team closes      ──► status CLOSED, closing message ──► in-app alert to the LO; no more comments
```

Alerts use aide-service `NotificationService` (shown in the LO app's Alerts and the aide-ui bell).

---

## 6. API reference (aide-service, envelope `{ success, message, data }`)

### LO app — `/app/my-lo/me/helpdesk` (role `LIAISON_OFFICER`)

| Method | Path | Body / params | Returns |
|---|---|---|---|
| GET | `/query-types` | — | `[{id, name, active, sortOrder}]` (active only) |
| GET | `/queries` | `page`, `size`, `search` | `{items: [Ticket], total, page, size}` — own queries |
| POST | `/queries` | `{queryTypeId, title, description, attachments: [url], source}` | Ticket (with messages) |
| GET | `/queries/{id}` | — | Ticket with `messages` (own only, else 404) |
| POST | `/queries/{id}/comments` | `{body, attachments: [url]}` | Ticket with `messages` |
| POST | `/attachments` | multipart `file` | `{url}` |

### LO Nodal — `/app/lo-helpdesk`

| Method | Path | Body / params | Access |
|---|---|---|---|
| GET | `/query-types` | — (active) | read |
| GET | `/query-types/all` | — | read |
| POST | `/query-types` | `{name}` | EDIT |
| PUT | `/query-types/{id}` | `{name}` | EDIT |
| PUT | `/query-types/{id}/active` | `?active=true/false` | EDIT |
| GET | `/tickets` | `search, status, queryTypeId, source, closedType, page, size` | read |
| GET | `/tickets/unread-count` | — | read |
| GET | `/tickets/{id}` | — (marks read) | read |
| POST | `/tickets/{id}/reply` | `{body, attachments}` | REPLY |
| PUT | `/tickets/{id}/close` | `{closedType: CHAT/CALL, message?}` | EDIT |
| PUT | `/tickets/{id}/transfer` | `{queryTypeId}` | EDIT |
| POST | `/attachments` | multipart `file` | REPLY |
| GET | `/export` | same filters as `/tickets` → `.xlsx` | EXPORT |

**Ticket:** `id, ticketNo, queryTypeId, queryTypeName, title, description, attachments[], status,
closedType, closedAt, source, raisedBy{userId, liaisonOfficerId, name, email, phone}, readByTeam,
createdAt, lastActivityAt, messages[]` — **Message:** `id, senderType, senderName, body, attachments[], createdAt`.

---

## 7. Rules and security

* An LO only sees and writes their own queries (`raised_by_user_id` = login user); others → 404.
* Owner, name, email and phone are taken from the login / LO profile, never from the request.
* Closed queries accept no comments or replies.
* Attachments: only URLs returned by the upload (http/https), max 5 per query or message; the upload
  accepts JPG / JPEG / PNG / PDF up to 5 MB.

---

## 8. Configuration and deploy

* Run `db/patch_lo_helpdesk.sql` on the aide database (dev and prod).
* `app.media-service.base-url` — dev `${host}:3002/api`; prod env **`MEDIA_SERVICE_URL`**
  (e.g. `http://mediaservices:3002/api`). aide-service must reach media-services on the network.
* Create at least one active query type in aide-ui before LOs use the form.

---

## 9. Code map

**aide-service** (`in.co.bel.aide.mgmt`): `domain/tdms/LoHelpdeskQueryType|Ticket|Message`,
`repository/tdms/LoHelpdesk*Repository`, `service/LoHelpdeskService` (LO), `service/LoHelpdeskAdminService`
(Nodal), `service/LoHelpdeskSupport` (shared rules / mapping), `service/HelpdeskMediaClient` (upload),
`service/dto/LoHelpdeskDtos`, `controller/tdms/MyLoHelpdeskController`, `controller/tdms/LoHelpdeskAdminController`,
`fwk/StringListJsonConverter`, access rules in `security/CommitteeAccessGuard`, `db/patch_lo_helpdesk.sql`.

**LO app** (`lib/features/helpdesk/`): `data/helpdesk_repository.dart`, `domain/helpdesk_models.dart`,
`presentation/helpdesk_screen.dart`, `ask_help_screen.dart`, `query_detail_screen.dart`, `helpdesk_widgets.dart`;
paths in `core/config/api_config.dart`; entry points in `lo_more_screen.dart`, `lo_portal_shell.dart`, `faq_screen.dart`.

**aide-ui** (`src/modules/lo-committee/`): `pages/LoHelpdeskPage.tsx`, `components/LoHelpdeskQueryTypesTab.tsx`,
`services/loHelpdeskApi.ts`; menu in `layouts/lo-nodal/LONodalLayout.tsx`; route in `App.tsx`.

---

## 10. How to test

1. Run the SQL patch, deploy aide-service, run aide-ui and the LO app.
2. aide-ui (LO Nodal) ▸ Help Desk ▸ **Create Query Type** ▸ create "Transport".
3. LO app ▸ More ▸ Help Desk ▸ **Ask for Help**: Submit empty → required errors; fill all, add a PDF →
   "Your query was submitted." → `HD000001`, **Open**.
4. aide-ui ▸ **Raised Queries**: the query is listed with an unread dot; open it (raiser name / email /
   phone shown) → reply with an attachment → status **In Progress**; the LO gets an alert.
5. LO app ▸ open the query → reply is shown → add a comment → aide-ui shows the unread dot again.
6. aide-ui ▸ Transfer → note in the conversation; Close (chat) → LO app shows **Closed**, no comment box.
7. Filters, search, export to Excel. Log in as another LO → the first LO's queries are not visible.
