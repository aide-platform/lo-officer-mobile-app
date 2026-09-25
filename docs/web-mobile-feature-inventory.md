# CAP Web ↔ Mobile — Liaison Officer inventory

Live portal: `http://35.244.48.209/` · API: `http://35.244.48.209:8080`

This Flutter app is **Liaison Officer only** (`LoPortalShell`). Committee Nodal / Org Rep UIs are web-portal only.

## Mobile IA

| Surface | Nav |
|---------|-----|
| `/lo-portal/*` equivalents | Delegates · Tasks · Alerts; Profile / Help / Theme off avatar |

## Feature parity (LO portal)

| Capability | Mobile | Status |
|------------|--------|--------|
| Email OTP + CAPTCHA | Login | Done |
| My LO profile | My Profile | Done |
| Assigned delegates + detail | Delegates tab | Done |
| Itinerary (composed) | Delegate detail | Done |
| Transport / vehicles | Delegate detail | Done |
| Travel / movement update | Detail sheets | Done |
| Tasks + status | Tasks tab | Done |
| Issue reporting | Detail / Alerts → issues | Done (on-device + speculative CAP POST + Share) |
| Notifications | Alerts + AppBar inbox | Done |
| Theme light/dark | Avatar menu | Done |
| Help & Support | Avatar menu | Done |
| Accommodation | — | Out of scope |

## Out of scope (web / other CAP modules)

Org types, organisations, DO letters, Org Rep nominate/import, Nodal assign/review, catering, e-coupons, quota admin, sub-nodals.
