# Help Desk — how it works

Liaison Officers (LOs) raise help desk queries from the **LO app**; the **LO Nodal** team answers them
in **aide-ui**. Everything is stored in **aide-service**: its own database tables, and attachment files
on its storage folder (a local folder on GCP, the **NFS mount on NIC**). **eventservices and
media-services are not used.**

| Repo | Branch | Part |
|---|---|---|
| `lo-officer-mobile-app` (Flutter) | `feat/helpdesk` | LO: raise queries, see replies, comment |
| `aide-service` (Spring Boot) | `feat/lo-helpdesk` | APIs, tables, file storage, notifications |
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
                    tdms.lo_helpdesk_attachments  (relative file paths)
                       │
                       ▼
        files       app.helpdesk.storage-root/<yyyy>/<MM>/<uuid>.<ext>
                    (GCP: local folder / volume · NIC: NFS mount)
                    downloaded only through the endpoints, with the token
```

---

## 2. Database (aide-service)

Created by `src/main/resources/db/patch_lo_helpdesk.sql` (safe to re-run; also adds the sidebar menu
and permission chips). On a database where the earlier version of the patch ran (GCP), the same
script removes the old plain-text columns.

**No personal data is copied into these tables.** The LO's name, email and phone are read from
`mdms.users` / `mdms.liaison_officers`, where they are encrypted, and decrypted in Java when shown.

**`tdms.lo_helpdesk_query_types`** — `id`, `name` (unique, case-insensitive), `is_active`, `sort_order`, audit columns.

**`tdms.lo_helpdesk_tickets`** — one row per query:

| Column | Meaning |
|---|---|
| `ticket_no` | `HD000001`, `HD000002`, … (sequence `tdms.lo_helpdesk_ticket_no_seq`) |
| `query_type_id` | → query type |
| `title`, `description` | from the form |
| `status` | `OPEN` (new, waiting for the team) → `IN_PROGRESS` (team replied) → `CLOSED` |
| `closed_type`, `closed_at`, `closed_by_user_id` | how / when / who closed it (`CHAT` or `CALL`) |
| `source` | `ANDROID`, `IOS` or `WEB` |
| **`raised_by_user_id`** | **`mdms.users.id` of the LO who raised it** (ownership) |
| `liaison_officer_id` | `mdms.liaison_officers.id` of that LO (name / phone are read from there) |
| `read_by_team` | false while the LO has added something the team has not opened |
| `last_activity_at` | last message / status change (lists sort by it) |

**`tdms.lo_helpdesk_messages`** — the conversation: `ticket_id`, `sender_type` (`LO`, `TEAM`, `SYSTEM`),
`sender_user_id`, `body`, `created_at`. The sender's name is read from `mdms.users`. `SYSTEM` = automatic
notes (query transferred).

**`tdms.lo_helpdesk_attachments`** — one row per file: `ticket_id`, `message_id` (null = sent with the
query), `file_name` (original name), `storage_name` (path **relative** to the storage root), `mime_type`
(detected from the content), `size_bytes`.

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

The files are sent **in the same request** as the query (multipart), so nothing is uploaded until the
LO submits.

**Query details** — the query, the conversation (LO comments, help desk replies, notes), and a comment
box with attachments while the query is not closed. Tapping a file downloads it with the LO's token,
saves it (Downloads on Android, the share sheet on iOS) and opens it.

**Push:** when the team replies or closes the query, the phone gets a push; tapping it opens that query.
If the app is open, the help desk list and an open query reload.

---

## 4. aide-ui (LO Nodal)

Sidebar ▸ **Help Desk** (`/lo-nodal/helpdesk`):

* **Create Query Type** — create, rename, activate / deactivate query types.
* **Raised Queries** — filters (search by ticket no. / title, status, query type, **Liaison Officer**,
  source, closed by), table (unread dot), details panel (query, raiser name / email / phone,
  conversation), **reply** with attachments, **close** (resolved by chat / call, optional closing
  message), **transfer** to another query type, **Export to Excel** (ticket no., title, type, status,
  closed by, raiser name / email / phone, source, description, dates).
* LO names and emails are encrypted at rest, so they cannot be searched as text; pick the LO in the
  **Liaison Officer** filter instead.
* Clicking a file downloads it with the login token (files are not public links).

Access: Admin and LO Nodal: everything. Sub Nodal Officers per permission chip (tab-wise):

| Chip | Allows |
|---|---|
| `LO_HELPDESK_QUERY_TYPES_TAB` | see the Create Query Type tab |
| `LO_HELPDESK_QUERY_TYPES_MANAGE` | add / edit / activate query types (includes the tab) |
| `LO_HELPDESK_RAISED_QUERIES_TAB` | see the Raised Queries tab and open queries |
| `LO_HELPDESK_RAISED_QUERIES_MANAGE` | reply, close, transfer (includes the tab) |
| `LO_HELPDESK_EXPORT` | Export to Excel (includes the Raised Queries tab) |

Tabs and buttons the user may not use are hidden; with no chip the page says so.

---

## 5. Flow and notifications

```
LO raises query ──► status OPEN, read_by_team=false ──► in-app alert to LO Committee nodals
LO comments      ──► read_by_team=false (status unchanged)
Team opens it    ──► read_by_team=true
Team replies     ──► status IN_PROGRESS ──► LO: in-app alert + phone push ("Help desk replied on HD…")
Team transfers   ──► query type changed + SYSTEM note in the conversation
Team closes      ──► status CLOSED, closing message ──► LO: in-app alert + phone push; no more comments
```

* **In-app alerts** use aide-service `NotificationService` (`tdms.notifications`): shown in the LO app's
  Alerts tab (`/app/notifications/mine`) and the aide-ui bell.
* **Phone push** uses `LoFcmNotificationService.notifyHelpdeskUpdate` (FCM, the LO's device token),
  with link `helpdesk:<ticketId>`. The LO app opens that query when the push is tapped.
* All notifications are sent **after the transaction commits**, and a failed notification never fails
  the request.

---

## 6. API reference (aide-service, envelope `{ success, message, data }`)

### LO app — `/app/my-lo/me/helpdesk` (role `LIAISON_OFFICER`)

| Method | Path | Body / params | Returns |
|---|---|---|---|
| GET | `/query-types` | — | `[{id, name, active, sortOrder}]` (active only) |
| GET | `/queries` | `page`, `size`, `search` | `{items: [Ticket], total, page, size}` — own queries |
| POST | `/queries` | multipart: `queryTypeId, title, description, source`, `files` (0–5) | Ticket (with messages) |
| GET | `/queries/{id}` | — | Ticket with `attachments` and `messages` (own only, else 404) |
| POST | `/queries/{id}/comments` | multipart: `body`, `files` (0–5) | Ticket with `messages` |
| GET | `/attachments/{id}` | — | the file (only files of the LO's own queries, else 404) |

### LO Nodal — `/app/lo-helpdesk`

| Method | Path | Body / params | Access |
|---|---|---|---|
| GET | `/query-types` | — (active) | any chip |
| GET | `/query-types/all` | — | QUERY_TYPES_TAB |
| POST | `/query-types` | `{name}` | QUERY_TYPES_MANAGE |
| PUT | `/query-types/{id}` | `{name}` | QUERY_TYPES_MANAGE |
| PUT | `/query-types/{id}/active` | `?active=true/false` | QUERY_TYPES_MANAGE |
| GET | `/tickets` | `search, status, queryTypeId, raisedByUserId, source, closedType, page, size` | RAISED_QUERIES_TAB |
| GET | `/raisers` | — (LOs who raised queries, for the filter) | RAISED_QUERIES_TAB |
| GET | `/tickets/unread-count` | — | RAISED_QUERIES_TAB |
| GET | `/tickets/{id}` | — (marks read) | RAISED_QUERIES_TAB |
| POST | `/tickets/{id}/reply` | multipart: `body`, `files` (0–5) | RAISED_QUERIES_MANAGE |
| PUT | `/tickets/{id}/close` | `{closedType: CHAT/CALL, message?}` | RAISED_QUERIES_MANAGE |
| PUT | `/tickets/{id}/transfer` | `{queryTypeId}` | RAISED_QUERIES_MANAGE |
| GET | `/attachments/{id}` | — (the file) | RAISED_QUERIES_TAB |
| GET | `/export` | same filters as `/tickets` → `.xlsx` | EXPORT |

**Ticket:** `id, ticketNo, queryTypeId, queryTypeName, title, description, attachments[], status,
closedType, closedAt, source, raisedBy{userId, liaisonOfficerId, name, email, phone}, readByTeam,
createdAt, lastActivityAt, messages[]` — **Message:** `id, senderType, senderName, body, attachments[], createdAt`
— **Attachment:** `id, fileName, mimeType, sizeBytes`.

---

## 7. Rules and security

* An LO only sees and writes their own queries (`raised_by_user_id` = login user); others → 404. The
  same check applies to file downloads.
* Owner, name, email and phone are taken from the login / LO profile, never from the request, and are
  not copied into the help desk tables.
* Closed queries accept no comments or replies.
* Files: max 5 per query or message, 5 MB each. The real type is detected from the content (Tika):
  only JPEG, PNG and PDF are accepted, whatever the extension says. Files are written to a temp file
  and moved into place; paths that would leave the storage root are rejected; files of a request that
  fails are deleted. Downloads are sent with `Content-Disposition: attachment` and
  `X-Content-Type-Options: nosniff`.

---

## 8. Configuration and deploy

* Run `db/patch_lo_helpdesk.sql` on the aide database (GCP and NIC).
* File storage (`application.properties`):
  * `app.helpdesk.storage-root=${APP_HELPDESK_ROOT:${app.storage.upload-root}/lo-helpdesk}`
  * `app.helpdesk.max-file-bytes` (default 5 MB), `app.helpdesk.max-files=5`

| Environment | `APP_HELPDESK_ROOT` | Folder |
|---|---|---|
| Local / dev | not set | `<working dir>/aide-uploads/lo-helpdesk` |
| GCP (testing) | not set, or a mounted volume | `/opt/aide/uploads/lo-helpdesk`; mount a volume there so files survive a redeploy |
| NIC (production) | `/mnt/nfs/aero/lo-helpdesk` | the NFS folder (mount it into the container; the container user must be able to write) |

* Back up the storage folder together with the DB: the DB stores only relative paths.
* Phone push needs Firebase configured on aide-service (same as task / delegate pushes).
* Create at least one active query type in aide-ui before LOs use the form.
* Deploy aide-service, aide-ui and the new LO app together: older app builds use the removed endpoints.

---

## 9. Code map

**aide-service** (`in.co.bel.aide.mgmt`): `domain/tdms/LoHelpdeskQueryType|Ticket|Message|Attachment`,
`repository/tdms/LoHelpdesk*Repository`, `service/LoHelpdeskService` (LO), `service/LoHelpdeskAdminService`
(Nodal), `service/LoHelpdeskSupport` (shared rules / mapping / decrypted names), `service/LoHelpdeskFileStore`
(file storage), `LoFcmNotificationService.notifyHelpdeskUpdate` (push), `service/dto/LoHelpdeskDtos`,
`controller/tdms/MyLoHelpdeskController`, `controller/tdms/LoHelpdeskAdminController`, access rules in
`security/CommitteeAccessGuard`, `db/patch_lo_helpdesk.sql`.

**LO app** (`lib/features/helpdesk/`): `data/helpdesk_repository.dart`, `data/helpdesk_updates.dart`,
`domain/helpdesk_models.dart`, `presentation/helpdesk_screen.dart`, `ask_help_screen.dart`,
`query_detail_screen.dart`, `helpdesk_widgets.dart`; paths in `core/config/api_config.dart`; entry points
and the `helpdesk:<id>` push link in `lo_more_screen.dart`, `lo_portal_shell.dart`, `faq_screen.dart`.

**aide-ui** (`src/modules/lo-committee/`): `pages/LoHelpdeskPage.tsx`, `components/LoHelpdeskQueryTypesTab.tsx`,
`services/loHelpdeskApi.ts`; menu in `layouts/lo-nodal/LONodalLayout.tsx`; route in `App.tsx`.

---

## 10. How to test

1. Run the SQL patch, deploy aide-service, run aide-ui and the LO app.
2. aide-ui (LO Nodal) ▸ Help Desk ▸ **Create Query Type** ▸ create "Transport".
3. LO app ▸ More ▸ Help Desk ▸ **Ask for Help**: Submit empty → required errors; fill all, add a PDF and
   a photo → "Your query was submitted." → `HD000001`, **Open**. The files are in the storage folder.
4. aide-ui ▸ **Raised Queries**: the query is listed with an unread dot; open it (raiser name / email /
   phone shown) → open both files → reply with an attachment → status **In Progress**; the LO's phone
   gets a push and the Alerts tab an alert. Tap the push → the query opens.
5. LO app ▸ open the reply's file → add a comment → aide-ui shows the unread dot again.
6. aide-ui ▸ Transfer → note in the conversation; Close (chat) → push; LO app shows **Closed**, no comment box.
7. Filters (Liaison Officer, status, type, …), search by ticket no. / title, export to Excel.
8. Log in as another LO → the first LO's queries and files are not visible (404).
9. Try to attach a renamed file (e.g. a `.exe` renamed to `.pdf`) → rejected.
