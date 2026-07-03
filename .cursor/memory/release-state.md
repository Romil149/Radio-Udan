# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | (pending push) | — | 2026-07-03 | Live hero from MP3 ICY; radio VoiceOver; build **2.0.0+25** |
| TestFlight iOS | **2.0.0+25** | CI pending | 2026-07-03 | Same commit as `main` push |
| Staging WP plugin | pending | **no** | — | Deploy plugin: live_radio no schedule merge, copy catalog |
| Staging API smoke | 14/14 | — | 2026-06-27 | Re-run after plugin deploy |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+25`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. Upload updated **radioudaan-app-api** plugin to staging (live_radio + copy keys).
