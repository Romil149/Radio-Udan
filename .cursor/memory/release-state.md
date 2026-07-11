# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+66** @ `f132462` | pending push | 2026-07-11 | Production API baked into CI |
| TestFlight iOS | **2.0.0+66** | CI after push | 2026-07-11 | Points at radioudaan.com |
| Android APK | **2.0.0+66** | CI after push | 2026-07-11 | Production API; tag `release-apk` |
| Staging WP plugin | live (nexusfleck) | yes | 2026-07-11 | FCM `radio-udaan-72232` |
| **Production WP** (`radioudaan.com`) | secrets imported | **yes** | 2026-07-11 | FCM match; api_base prod; copy **472**; Razorpay live |
| Production copy keys | **472** | prod | 2026-07-11 | Full catalog |

## Open deploy blockers

1. After CI: submit TestFlight build for external/App Store review when ready; upload Play AAB/APK via Play Console (human).
2. Re-upload logo / donate QR on prod if missing (attachment IDs not transferred).
3. Prod push devices = 0 until production app registers FCM.
4. Device QA on **+66**: OTP, donate, push, library against radioudaan.com.
