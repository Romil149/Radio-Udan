# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **Android 3.0.0+76** / **iOS pinned 2.0.0+71** | pending push | 2026-07-21 | YouTube native controls; Play package `bane.kjsdev.radioudaan` |
| TestFlight iOS | **2.0.0+71** (unchanged) | — | 2026-07-15 | iOS `FLUTTER_BUILD_*` locked in Debug/Release.xcconfig |
| Android Play | **3.0.0+76** | internal + prod rollout in progress | 2026-07-21 | AAB `Radio-Udaan-play.aab` |
| **Production WP** (`radioudaan.com`) | secrets imported | **yes** | 2026-07-11 | Redeploy plugin for Safari URL + copy keys |
| Production copy keys | **472+** | prod | 2026-07-15 | Redeploy for `donate_safari_*` + `ios_safari_payment_url` |

## App Store Connect metadata

- **ASC paste package**: `.cursor/memory/app-store-connect-submission.md` — keep build **2.0.0 (71)** for iOS until a dedicated iOS bump.
- **2026-07-21**: Android Play advanced to **3.0.0+76**; iOS intentionally remains **2.0.0+71** via xcconfig overrides (do not inherit Android pubspec for IPA).
- **2026-07-15**: iPad blank-page fix local **+71** (Firebase timeout, splash offline UI, no MaterialApp remount, dark launch).
- **2026-07-15**: iOS donate is Safari link-out only (`https://rzp.io/rzp/dswNW5g`). Use `app-review-donations.md` for Review Notes.

## Open deploy blockers

1. Complete Play Production rollout / policy (sign-in details) if still pending.
2. Device QA on iOS **+71** before any iOS version bump.
3. Add `radioudaan.com` app/universal links (currently nexusfleck only).
4. Human: ASC resubmit with iOS **2.0.0 (71)** when ready; App Privacy / Data safety.
5. Re-upload logo / donate QR on prod if missing.
