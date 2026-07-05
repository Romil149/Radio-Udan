# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+32** (form field a11y + AzuraCast direct fetch) | pending push | 2026-07-05 | Build 32 — VoiceOver form fixes app-wide |
| TestFlight iOS | **2.0.0+32** | pending CI | 2026-07-05 | User retest after TestFlight install |
| Staging WP plugin | pending | **no** | — | Deploy plugin: `now_playing_api_url`, live_radio cleanup |
| Staging API smoke | 14/14 | — | 2026-07-05 | Local verify |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+32`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. Upload updated **radioudaan-app-api** plugin to staging (`now_playing_api_url`, no show_title in live_radio).
2. User device QA on TestFlight build 32 — all form fields per FORMS-AUDIT-MASTER.md.
