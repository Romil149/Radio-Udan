# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+59** (pushing) | **pending** | 2026-07-11 | Fix inbox tap, VO Refresh crash, showing-count label |
| TestFlight iOS | **2.0.0+59** | CI after push | 2026-07-11 | Retest: tap row → detail; VO All→Unread→Refresh→swipe |
| Staging WP plugin | **needs redeploy** | **no** | 2026-07-11 | copy key notifications_showing_count + prior FCM/Open-in-app |
| Staging API smoke | 19/19 | local | 2026-07-11 | |
| Staging copy keys | 459 | staging | 2026-07-11 | Redeploy for new keys |

## Open deploy blockers

1. **Deploy App API plugin zip** — new copy keys + FCM data title/body.
2. **Device test +59** — sighted tap opens detail; VO Refresh no crash; count line shows how many rows.
