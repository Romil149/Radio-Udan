# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **Android 3.0.0+76** / **iOS 2.0.0+72** | pending push | 2026-07-21 | ASC 90189: +71 already uploaded — iOS build bumped only |
| TestFlight iOS | **2.0.0+72** | CI after push | 2026-07-21 | Marketing version still **2.0.0**; build **72** |
| Android Play | **3.0.0+76** | internal + prod rollout in progress | 2026-07-21 | AAB `Radio-Udaan-play.aab` |
| **Production WP** (`radioudaan.com`) | secrets imported | **yes** | 2026-07-11 | Redeploy plugin for Safari URL + copy keys |
| Production copy keys | **472+** | prod | 2026-07-15 | Redeploy for `donate_safari_*` + `ios_safari_payment_url` |

## App Store Connect metadata

- **ASC paste package**: `.cursor/memory/app-store-connect-submission.md` — use build **2.0.0 (72)** for next TestFlight/ASC upload.
- **2026-07-21**: Android Play advanced to **3.0.0+76**; iOS marketing stays **2.0.0**, build **72** (ASC rejected redundant **+71**).
- **2026-07-15**: iPad blank-page fix local **+71** (Firebase timeout, splash offline UI, no MaterialApp remount, dark launch).
- **2026-07-15**: iOS donate is Safari link-out only (`https://rzp.io/rzp/dswNW5g`). Use `app-review-donations.md` for Review Notes.

## Open deploy blockers

1. Complete Play Production rollout / policy (sign-in details) if still pending.
2. Device QA on iOS **+72** after TestFlight processes the new IPA.
3. Add `radioudaan.com` app/universal links (currently nexusfleck only).
4. Human: ASC resubmit with iOS **2.0.0 (72)** when ready; App Privacy / Data safety.
5. Re-upload logo / donate QR on prod if missing.
