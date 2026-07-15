# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+68** @ `c610c14` **yes** 2026-07-11 | AppEnv production-only bootstrap |
| Local app (uncommitted) | **2.0.0+69** | **no** | 2026-07-14 | iOS Safari-only donate (3.1.1) |
| TestFlight iOS | **2.0.0+68** | CI after push | 2026-07-11 | Production API — bump to +69 when shipping Safari donate |
| Android APK | **2.0.0+68** | CI after push | 2026-07-11 | Production API |
| **Production WP** (`radioudaan.com`) | secrets imported | **yes** | 2026-07-11 | FCM match; copy **472** |
| Production copy keys | **472** | prod | 2026-07-11 | Full catalog; +4 Safari keys pending deploy |

## App Store Connect metadata

- **ASC paste package ready** (2026-07-11): `.cursor/memory/app-store-connect-submission.md` — description, 4+ age guidance, keywords, What’s New 2.0.0, Review Notes, build **2.0.0 (68)**.
- **2026-07-14**: iOS donate is Safari link-out only (build **+69** local). Update Review Notes / `app-review-donations.md` before next TestFlight submit.
- **Still awaiting human:** Submit for Review + demo phone/OTP credentials in Review Notes; confirm screenshots + App Privacy labels.

## Open deploy blockers

1. **CONDITIONAL GO** (Alex review 2026-07-11): code + prod API ready; not full store-submit until items below.
2. Device QA on **+69** (VoiceOver: Safari donate card) against radioudaan.com; prior +68 TalkBack still pending.
3. Android **release keystore** (still debug signing in `build.gradle.kts`) before Play upload.
4. Add `radioudaan.com` app/universal links (currently nexusfleck only).
5. Human: ASC Submit + demo credentials (package ready); age rating 4+ questionnaire; App Privacy / Data safety; confirm MSG91 OTP SMS on prod.
6. Re-upload logo / donate QR on prod if missing.
7. Deploy WP copy catalog (+ `donate_safari_*` keys) when shipping +69.
