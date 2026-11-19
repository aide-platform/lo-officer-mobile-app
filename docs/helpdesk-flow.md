# Help Desk — how it works (LO app)

This document explains the Help Desk feature of the Liaison Officer (LO) mobile app from end to end:
what the user sees, which server does what, how the LO is identified, when the Help Desk is shown,
every API call with its payload, error handling, configuration and how to test it.

The feature is a port of the Help Desk in the **attendees app** (`attendees-app`, branch `1.0.0`,
pages `src/app/pages/help-desk/*` and `src/app/modals/help-desk/*`). Tickets are stored in the same
place, so a query raised from the LO app shows up in the same dashboard as attendee queries.

| Repo | Branch | What changed |
|---|---|---|
| `lo-officer-mobile-app` (Flutter) | `feat/helpdesk` | Help Desk screens and data layer |
| `aide-service` (Java / Spring Boot) | `feat/lo-helpdesk` (from `ev-dev`) | New `/app/my-lo/me/helpdesk/*` endpoints that forward to eventservices |
| `attendees-app` | — | **Not changed.** Used only as the reference. |

---

## 1. The big picture

```
          ┌──────────────────────── LO mobile app (Flutter) ────────────────────────┐
          │  More ▸ Help Desk        FAQ ▸ "Still have questions?"                   │
          │  Help Desk list ── Ask for Help (form) ── Query details + comments       │
          └──────────────┬───────────────────────────────────┬──────────────────────┘
                         │ LO token                           │ no token (public "guest" calls)
                         ▼                                    ▼
          ┌──────────── aide-service ───────────────┐   form dropdown lists only:
          │ /app/my-lo/me/helpdesk/*                │   • /helpdesk/guest/query/list/{eventId}
          │ 1. who is this LO? (login)              │     (query types)
          │ 2. owner = LO login email               │   • /auth/guest/countries
          │ 3. forward with organiser host headers  │
          └───┬───────────────┬───────────────┬─────┘
              │ direct, inside the server network (no gateway)
              ▼               ▼               ▼
        eventservices    survey-services   media-services
        :8085 /helpdesk  :8089 form        :3002 /api/dpvu attachments
        (tickets)        (formType 16/11)  (returns public CDN url)
              │
              └─▶ the same tickets the attendees app and the dashboard use
```

**Why most calls go through aide-service.** This was checked against the live server (read-only
calls, see section 12):

| Call | Without an eventservices login |
|---|---|
| Ticket list `/helpdesk/helpdesklist` | **401 Unauthorized** |
| Help form `/surveyservicesv2/v2/survey/get/admin` | **401 Unauthorized** |
| Attachment upload `/mediaservices/api/dpvu` | **401 Unauthorized** |
| Query types `/helpdesk/guest/query/list/{eventId}` | 200 (public) |

The gateway accepts only an **eventservices** login for the first three. The attendees app has one
(attendees log in to eventservices); the LO app logs in to aide-service (email + captcha + OTP), and the
gateway rejects that token (401 `Error-006`).

aide-service already calls eventservices directly inside the server network for e-badges
(`EventServiceClient`), as the organiser account. The help desk uses the same route for tickets, the
form and attachments. Only the public dropdown lists are fetched by the app itself.

---

## 2. Whose ticket is it? (no badge needed)

Every LO can use the help desk. **No badge, pass or eventservices registration is required.**

| Value | Where it comes from | Used for |
|---|---|---|
| **Owner: login email** | The verified login token (`CurrentUserService.requireCurrentEmail()`, lower case) | Written into the ticket's `userInfo.email` (and each comment's `replyInfo.email`); the list is filtered by it; detail/comment check it |
| **Form** | `subFormType 11` ("Liaison Officer App") | Every LO ticket is saved with it; the list also filters by it, so only LO-app tickets show |
| EventUser id (optional) | `tdms.passes.eu_badge_reg_id` of the LO's current pass, **only if** their badge is registered in eventservices | Sent as `userId` when present; eventservices treats it as optional |
| **Event id** | aide-service property `app.event.default-id` (dev `6a33b3bd6d5c831733add5d5`, prod `6a9700ba03ffb80d9e93a87d`) | Every help desk call, the form, uploads, the `{eventID}` in option URLs |

The owner is always taken from the logged-in account, **never from the request**: aide-service overwrites
any email the app sends. An LO therefore only ever sees and writes their own tickets.

---

## 3. Where Help Desk appears

Help Desk is **always shown** to every logged-in LO. It does not depend on dashboard menu settings,
tickets or anything else:

1. **More page** → "Help Desk" row.
2. **FAQ page** → "Still have questions? / Contact Support" card at the bottom (same as the attendees FAQ page).

```
Open Help Desk
  │
  ├─ GET aide /app/my-lo/me/helpdesk/context ──► { eventId, … }   (once per session; optional)
  │
  └─ GET aide /app/my-lo/me/helpdesk/queries ──► the LO's tickets + Ask for Help
```

The `eventId` from `/context` is used for `{eventID}` in the form's option URLs; if that call fails the
app falls back to its configured event id.

---

## 4. The screens

### 4.1 Help Desk list (`helpdesk_screen.dart`)

Opened from More ▸ Help Desk (or FAQ ▸ Contact Support). Same as the attendees "Help Center" page.

* Shows the LO's tickets, **newest change first**, 10 per page; more load as you scroll.
* Each card: query type, "Updated 3 hrs ago", tracking number, status, title, description, attachments.
* **Search** (🔍): searches on Enter; clearing the box or Cancel shows all tickets again.
* **Pull down** to refresh.
* **Empty**: "No queries yet" + **Ask for Help** button. With tickets: floating **Ask for Help** button.
* Tap a ticket → Query details. Coming back after commenting refreshes the list.

Status labels (same codes as eventservices / the attendees app):

| `status` | Label |
|---|---|
| 0 | In review |
| 1, 2 | In progress |
| 4 | Closed |

### 4.2 Ask for Help (`ask_help_screen.dart`)

A dynamic form. Its fields are **not in the app**: they are the help desk form configured on the
dashboard form **"Liaison Officer App"** (survey `formType 16`, `subFormType 11`; the attendees app uses 8, "Attendee App Support"), fetched each time the screen opens. Changing the
form on the dashboard changes the app without a release.

* **Pages**: one page at a time, *Continue* / *Previous*, *Submit* on the last page, "Step 1 of 2".
* **Field types**:
  * text, email, number, telephone, url, password, textarea / texteditor;
  * dropdown, checkbox, radiogroup → a bottom-sheet picker (single or multi-select, search box when >8 options);
  * file → attachment upload (image from camera/gallery, or document), respecting the field's
    accepted types and max size (default 5 MB); single or multiple files.
  * `profileBanner` / `logo` file fields are skipped, as in the attendees app.
* **Show/hide rules (`visibleIf`)**: `{field} anyOf ['a','b']` shows a field only when `field` has one of
  those values; `{field} NOT ['a']` hides it for those values. A field with a rule stays hidden until its
  parent has a value.
* **Options from a URL (`choicesByUrl`)**: the list is loaded from the given URL and `path`, displaying
  `textName`.
  * `{eventID}` in the URL is replaced with the event id.
  * Any other `{name}` is another field's selected value → the list loads after that field is chosen,
    and is cleared/reloaded whenever that field changes (e.g. country → state).
  * For the `queryType` field only options whose `visibilitySpot` contains `11` are kept. **Dashboard setup needed:** in Help Desk settings ▸ Query types, add spot 11 (Liaison Officer App) to each query type LOs may choose; otherwise the dropdown is empty and the form cannot be submitted.
  * A full URL that is not an `/api/` route is treated as a CDN file and fetched without the token.
* **Prefill**: `firstName`, `lastName`, `email`, `contactNo` fields are prefilled from the LO profile (editable).
* **Validation**: required + visible + empty fields block *Continue/Submit* and show the field's
  `requiredErrorText`.
* **Leaving** with typed data asks "Leave without submitting?".
* **Submit** builds the same payload as the attendees app (see 5.3), shows "Your query was submitted."
  and returns to the list, which reloads.

### 4.3 Query details (`query_detail_screen.dart`)

Same as the attendees query-detail modal.

* The ticket card, then the **conversation** (name/initials or logo, message, attachments, time).
* **Write a comment** (max 200 characters, counter shown) with optional attachments → *Submit*.
  The comment appears at once; "Comment added."
* The comment box is **hidden when the ticket is Closed** (status 4); aide-service also refuses comments
  on closed tickets.
* Pull down to reload the conversation.

---

## 5. API reference

All aide-service endpoints require the LO's bearer token and role `LIAISON_OFFICER`, and use the
aide envelope `{ success, message, data, errorCode }`. Base: `https://<gateway>/api/aideservices`.

### 5.1 `GET /app/my-lo/me/helpdesk/context`

```json
{ "success": true, "data": { "registered": false, "ticketId": null, "eventId": "6a33b3bd6d5c831733add5d5" } }
```

The app uses `eventId`. `registered` / `ticketId` only describe the LO's badge; they do not limit anything.

### 5.2 `GET /app/my-lo/me/helpdesk/queries?page=0&size=10&search=car`

aide-service sends to eventservices `POST /helpdesk/helpdesklist` (header `eventId` set):

```json
{ "query": { "userInfo.email": "<LO login email>", "subFormType": 11 }, "searchText": "car",
  "sortBy": ["modifiedAt"], "sortOrder": ["desc"], "page": 0, "totalInList": 10 }
```

Returns eventservices' `data` (`{ "dataList": [ …tickets… ], … }`). eventservices answers "no tickets"
with `status: NOT_FOUND`; aide-service turns that into `{ "dataList": [], "total": 0 }`.
`size` is capped at 50.

Ticket fields the app reads: `id`, `title`, `queryType`, `trackingNo`, `status`, `modifiedAt`,
`moreInfo[]` (`description` → text, `attachments` → file URL or list of URLs).

### 5.3 `POST /app/my-lo/me/helpdesk/queries` — raise a ticket

App sends (same shape as the attendees app):

```json
{
  "surveyId": "<form id>", "subFormType": 11,
  "queryType": "Transport", "title": "Car not arrived",
  "answer":   [ { "name": "queryType", "title": "Query Type", "value": "Transport" }, … ],
  "moreInfo": [ …same as answer… ],
  "info":     { …answers of fields marked isPrimary… },
  "userInfo": { "firstName": "…", "lastName": "…", "email": "…", "contactNo": "…" }
}
```

aide-service **overwrites** `userInfo.email` (login email), `eventId` and `subFormType` (11), sets
`userId` only if the LO's badge has an EventUser id, checks `title` and `queryType` are present, and forwards to eventservices `POST /helpdesk/guest/query/add`. eventservices sets status
0, a tracking number (`ET` + 7 digits) and notifies the help desk team. Returns the tracking number.

### 5.4 `GET /app/my-lo/me/helpdesk/queries/{id}` — ticket + conversation

Forwards to eventservices `GET /helpdesk/guest/detail?Id={id}&eventId=…`. aide-service returns it only
if the ticket's `userInfo.email` is the LO's login email; otherwise **404 "Query not found."** (also for an id
that is not a 24-character ObjectId). Conversation items: `replyInfo{firstName,lastName,logo}`,
`description`, `attachment[]`, `createdAt`.

### 5.5 `POST /app/my-lo/me/helpdesk/queries/{id}/comments`

App sends `{ "description": "…", "attachment": ["https://cdn/…"], "replyInfo": { "firstName": …, … } }`.
aide-service checks ownership (as 5.4), refuses closed tickets, and forwards to eventservices
`POST /helpdesk/guest/query/conversion?id={id}` with
`{ "replyFrom": "USER", "status": 0, "description", "attachment", "replyInfo" }` (`replyInfo.email` forced
to the login email; `userId` added only when the LO's badge has an EventUser id).

### 5.6 `GET /app/my-lo/me/helpdesk/form` — the Ask for Help form

aide-service calls survey-services `POST {app.survey-service.base-url}/v2/survey/get/admin` with
`{ "filterQuery": { "formType": 16, "subFormType": 11 }, "refFilterQuery": { "eventId": … } }` (same request as the
attendees app) and returns its `data`: `{ "id": "<surveyId>", "pages": [ { "elements": [ …fields… ] } ] }`.

### 5.7 `POST /app/my-lo/me/helpdesk/attachments` — upload a file

Multipart `file` (aide-service limit 10 MB; the form field's own `maxSize`, default 5 MB, is checked
in the app first). aide-service sends it to media-services `POST {app.media-service.base-url}/dpvu`
with headers `dp: eidenghd` and `df: {"eventId":"…"}` (same as the attendees app) and returns
`{ "url": "<public CDN url>" }`. That URL is what goes into the ticket / comment, so the dashboard can open it.

### 5.8 Direct calls from the app (public, no login)

| Purpose | Call |
|---|---|
| Option lists | `GET`/`POST` the field's `choicesByUrl.url` (placeholders filled), always **without** the LO token. In the current form: query types `https://dev.evenuefy.com/api/eventservices/helpdesk/guest/query/list/{eventID}` and countries `https://dev.evenuefy.com/api/auth/guest/countries` (both public). |

---

## 6. Security

* The ticket owner is **always** the logged-in LO's login email, set by aide-service from the verified
  token. Any `email`, `userId`, `eventId` or `subFormType` sent by the app is overwritten.
* Detail and comment check the ticket belongs to the caller before returning or writing anything;
  someone else's ticket answers 404 (no hint it exists).
* aide-service talks to eventservices with the organiser host account configured in
  `app.event-service.*` (the same account used for e-badges). That account is never exposed to the app.
* Endpoints are limited to role `LIAISON_OFFICER` (`@PreAuthorize`).

---

## 7. Errors the user can see

| Situation | Message |
|---|---|
| Ticket not theirs / bad id | Query not found. |
| Comment on a closed ticket | This query is closed. |
| Missing title / query type | Please enter a title for your query. / Please choose a query type. |
| eventservices down / timeout | Help desk is unreachable right now. Please try again. |
| eventservices rejects the request | eventservices' own message |
| Form not configured for the event | The help form is not set up for this event yet. |
| File too large | File is too large. Maximum size is N MB. |
| No network | Could not reach the server. Check your connection and try again. |

---

## 8. Configuration

**aide-service** (`application*.properties`):

| Property | Meaning |
|---|---|
| `app.event-service.base-url` | eventservices URL (existing, `${host}:8085`) |
| `app.survey-service.base-url` | **New.** survey-services URL, `${host}:8089` (same port eventservices uses for it) |
| `app.media-service.base-url` | **New.** media-services URL, `${host}:3002/api` (same as eventservices / aero-services) |
| `app.event.default-id` | Event id (existing) |
| `app.event-service.event-user-id`, `auth-user-id`, `user-type`, `access-codes` | Organiser host account headers (existing) |
| `app.event-service.paths.helpdesk-list` / `-add` / `-detail` / `-conversation` | Optional overrides; default to the eventservices paths in section 5 |

**LO app** (`--dart-define`, see `lib/core/config/api_config.dart`):

| Define | Default |
|---|---|
| `API_GATEWAY_URL` | `https://aeroindia.evenuefy.com/api` (aide-service is `${API_GATEWAY_URL}/aideservices`) |
| `EVENT_ID` | Fallback only; the event id from aide-service `/context` wins |
| — | `ApiConfig.helpdeskSubFormType = 11` (dashboard form "Liaison Officer App"; query types need visibilitySpot 11) |

---

## 9. Code map

**Flutter (`lib/features/helpdesk/`)**

| File | Role |
|---|---|
| `data/helpdesk_repository.dart` | All calls: context, tickets, form and upload via aide-service; option lists direct; `HelpdeskContext` |
| `domain/helpdesk_models.dart` | Ticket, comment, form, field, `visibleIf` rule, status labels, "Updated … ago" |
| `presentation/helpdesk_screen.dart` | List screen + ticket card |
| `presentation/ask_help_screen.dart` | Dynamic form |
| `presentation/query_detail_screen.dart` | Ticket details + comments |
| `presentation/helpdesk_widgets.dart` | Attachment pick/upload, status pill, shared widgets, LO → `userInfo` |

Also touched: `core/config/api_config.dart` (paths), `lo_more_screen.dart` (Help Desk row),
`lo_portal_shell.dart` (opens Help Desk), `faq_screen.dart` (Contact Support card). No new packages.

**aide-service (`in.co.bel.aide.mgmt`)**

| File | Role |
|---|---|
| `controller/tdms/MyLoHelpdeskController.java` | The seven `/app/my-lo/me/helpdesk/*` endpoints |
| `service/LoHelpdeskService.java` | Builds the eventservices requests; owner = login email; ownership checks |
| `service/MyLoService.java` | `myEventServicesIdentity()` → optional EventUser id + ticket id from the LO's badge |
| `service/EventServiceClient.java` | `helpdeskCall(...)` (eventservices), `helpdeskForm(...)` (survey-services), `uploadHelpdeskAttachment(...)` (media-services), all with the host headers |
| `application*.properties` | `app.survey-service.base-url`, `app.media-service.base-url` |

---

## 10. How to test

Deploy order: **aide-service first** (all Help Desk data comes from the new endpoints).
Dashboard: a query type must be visible for **Liaison Officer App (11)**.

1. Log in to the LO app with any LO (no badge needed).
2. More ▸ **Help Desk** is there (always), and FAQ ends with the "Contact Support" card.
3. Help Desk ▸ **Ask for Help** → the dashboard form loads. Press Submit empty → required errors.
   Fill it (with an attachment) → "Your query was submitted." → it is first in the list, **In review**.
4. Open it → add a comment with an attachment → "Comment added."
5. Dashboard ▸ help desk: the ticket is there with the LO's name. Reply → in the app pull to refresh →
   the reply shows. Close it → the app shows **Closed** and no comment box.
6. Search for part of the title; pull to refresh; scroll with more than 10 tickets.
7. Log in as a different LO: the first LO's tickets are not listed, and opening one by id answers "Query not found."

Build checks: `flutter analyze` for the app and `mvnw compile` for aide-service.

---

## 11. Differences from the attendees app (and why)

| Attendees app | LO app | Why |
|---|---|---|
| Calls eventservices with the attendee's own token; tickets owned by `eventUserId` | Calls go through aide-service; tickets owned by the LO's login email (`userInfo.email`) | The LO login is an aide-service login, and LOs need no eventservices registration |
| Help Desk shown per dashboard menu setting (`/tabs/help-desk`, ticket rule) | Always shown to every LO | Product decision: Help Desk is always available to LOs |
| Uses the attendee form (subFormType 8) | Uses the "Liaison Officer App" form (subFormType 11) | Separate form configured on the dashboard |
| Event id from app config / login | Event id from aide-service `/context` | Keeps dev / prod event ids in one place (aide-service config) |
| Multiple file fields share one attachment list (bug) | Each file field keeps its own attachments | Bug not carried over |
| Form and uploads called with the attendee's token | Form and uploads go through aide-service | Those services need an eventservices login |

---

## 12. Verification status

**Checked**

* aide-service compiles (`mvnw compile`); Flutter `analyze` clean (Flutter 3.47.8, the team's version).
* Live server, read-only calls with a non-existent user / ticket id (nothing created, nothing exposed):
  ticket list, form and upload answer **401** without an eventservices login; query types answer
  **200**. This is why the design above routes the first three through aide-service.
* Code of survey-services (`/v2/survey/get/admin`, port 8089, no auth filter) and media-services
  (`/api/dpvu`, port 3002, needs `dp` + `df.eventId`, no auth, returns `data.cdn_url`) matches what
  aide-service sends.
* Deployed aide-service (`feat/lo-helpdesk` at the time): `/helpdesk/context` → 200 for a logged-in
  LO; More shows Help Desk.
* eventservices code: `userId` is optional for add / conversation, notifications use `userInfo.email`,
  and the list accepts any field filter (`userInfo.email`, `subFormType`).

**Not yet checked (needs the email-owner version of aide-service deployed)**

* Form, upload, raise ticket, list, detail, comment end to end (section 10). If `/form` or
  `/attachments` fails, the aide-service log names the service and the HTTP status
  (`survey-services help form http=…`, `media-services help desk upload http=…`).

**Open point for the backend team:** `GET /helpdesk/guest/detail?Id=…` returns any ticket by id
without a login. That is existing eventservices behaviour (the attendees app relies on it), not part of
this change; aide-service additionally checks the ticket belongs to the LO.
