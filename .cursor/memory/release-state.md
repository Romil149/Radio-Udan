# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+61** @ `b67dcf9` | **yes** | 2026-07-11 | Notifications simplified: list-only, no detail page |
| TestFlight iOS | **2.0.0+61** | CI after push | 2026-07-11 | Simple inbox: title + full message; push opens list |
| Staging WP plugin | **needs redeploy** | **no** | 2026-07-11 | |
| Staging copy keys | 459 | staging | 2026-07-11 | |

## Open deploy blockers

1. Deploy plugin zip when ready.
2. Device test **+61**: list shows full messages; no detail page; push opens Notifications list; VO Refresh stable.
