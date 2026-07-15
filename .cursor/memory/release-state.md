# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+71** @ `a4f44b2` **yes** 2026-07-15 | iPad cold-launch blank fix (ASC 2.1a) |
| TestFlight iOS | **2.0.0+71** | CI after push | 2026-07-15 | Verify iPhone + iPad Simulator before ASC |
| Android APK | **2.0.0+71** | CI after push | 2026-07-15 | Production API |
| **Production WP** (`radioudaan.com`) | secrets imported | **yes** | 2026-07-11 | Redeploy plugin for Safari URL + copy keys |
| Production copy keys | **472+** | prod | 2026-07-15 | Redeploy for `donate_safari_*` + `ios_safari_payment_url` |

## App Store Connect metadata

- **ASC paste package**: `.cursor/memory/app-store-connect-submission.md` — update build to **2.0.0 (71)** before resubmit.
- **2026-07-15**: iPad blank-page fix local **+71** (Firebase timeout, splash offline UI, no MaterialApp remount, dark launch).
- **2026-07-15**: iOS donate is Safari link-out only (`https://rzp.io/rzp/dswNW5g`). Use `app-review-donations.md` for Review Notes.
- **Still awaiting human:** Ship TestFlight **+71**, verify cold launch on iPad, reply to App Review / resubmit.

## Open deploy blockers

1. Device QA on **+69** (VoiceOver: Safari donate card) against radioudaan.com.
2. Android **release keystore** before Play upload.
3. Add `radioudaan.com` app/universal links (currently nexusfleck only).
4. Human: ASC resubmit with build **69** + demo credentials; App Privacy / Data safety; confirm MSG91 OTP SMS on prod.
5. Re-upload logo / donate QR on prod if missing.
6. Confirm production WP plugin redeploy includes Safari donate fields.
