# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+27** (splash hang fix) | pending push | 2026-07-03 | Defer FCM off bootstrap; build 26 could hang on READY TO LAUNCH |
| TestFlight iOS | **2.0.0+27** | CI pending | 2026-07-03 | Replace build 26 if users stuck on splash |
| Staging WP plugin | pending | **no** | — | Deploy plugin: live_radio no schedule merge, copy catalog |
| Staging API smoke | 14/14 | — | 2026-06-27 | Re-run after plugin deploy |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+26`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. Upload updated **radioudaan-app-api** plugin to staging (live_radio + copy keys).
