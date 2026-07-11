# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+53** | **yes** (after push) | 2026-07-11 | Donate a11y: summary strip excluded from TalkBack swipe order |
| TestFlight iOS | **2.0.0+53** | CI after push | 2026-07-11 | Donate TalkBack fix |
| Staging WP plugin | **zip ready** `dist/radioudaan-app-api-staging.zip` | **no** | 2026-07-11 | Deploy for notifications API + compose + copy keys |
| Staging API smoke | 19/19 | local | 2026-07-11 | verify-wp 7/7; copy catalog 459 local |
| Staging copy keys | 455 | staging | 2026-07-11 | ≥300 gate PASS; redeploy for notification Open copy keys |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+33`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. **Deploy full App API plugin zip to staging** — notifications GET by id, unread filter, admin Open in app, copy keys.
2. **Device test** — TestFlight **+52**; send 3 admin notifications; tap detail + Open destination.
