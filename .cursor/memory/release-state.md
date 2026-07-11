# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+64** (pushing) | **pending** | 2026-07-11 | Library search Clear: Actions rotor + fixed X semantics |
| TestFlight iOS | **2.0.0+64** | CI after push | 2026-07-11 | Retest Library search Clear with VoiceOver |
| Staging WP plugin | **needs redeploy** | **no** | 2026-07-11 | |
| Staging copy keys | 459 | staging | 2026-07-11 | |

## Open deploy blockers

1. Deploy plugin zip when ready.
2. Device test **+64**: Library search → type → VoiceOver Actions “Clear search”; swipe to X button.
