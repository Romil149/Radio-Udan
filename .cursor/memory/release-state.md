# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+63** @ `af217f0` | **yes** | 2026-07-11 | Remove Push diagnostics from Settings |
| TestFlight iOS | **2.0.0+63** | CI after push | 2026-07-11 | Settings no longer has Push diagnostics |
| Staging WP plugin | **needs redeploy** | **no** | 2026-07-11 | |
| Staging copy keys | 459 | staging | 2026-07-11 | |

## Open deploy blockers

1. Deploy plugin zip when ready.
2. Device test **+63**: Settings has no Push diagnostics entry.
