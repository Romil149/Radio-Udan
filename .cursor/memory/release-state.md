# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+68** @ `c610c14` **yes** 2026-07-11 | AppEnv production-only bootstrap |
| TestFlight iOS | **2.0.0+68** | CI after push | 2026-07-11 | Production API |
| Android APK | **2.0.0+68** | CI after push | 2026-07-11 | Production API |
| **Production WP** (`radioudaan.com`) | secrets imported | **yes** | 2026-07-11 | FCM match; copy **472** |
| Production copy keys | **472** | prod | 2026-07-11 | Full catalog |

## Open deploy blockers

1. Device QA on **+68** against radioudaan.com.
2. Re-upload logo / donate QR on prod if missing.
3. App Store / Play submit is human after QA.
