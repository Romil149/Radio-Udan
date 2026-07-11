# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+60** (pushing) | **pending** | 2026-07-11 | Fix Showing-18-but-one-row (duplicate keys / id parse) |
| TestFlight iOS | **2.0.0+60** | CI after push | 2026-07-11 | Retest: scroll list shows all rows; VO Refresh no crash |
| Staging WP plugin | **needs redeploy** | **no** | 2026-07-11 | |
| Staging copy keys | 459 | staging | 2026-07-11 | |

## Open deploy blockers

1. Deploy plugin zip when possible.
2. Device test **+60** against video repro: Showing N must match visible scrollable rows; tap opens detail; VO Refresh no crash.
