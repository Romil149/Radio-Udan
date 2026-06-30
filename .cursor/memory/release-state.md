# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | `469ab22` | yes | 2026-06-30 | Playlists auto top-5, live radio, a11y; build **2.0.0+24** |
| TestFlight iOS | **2.0.0+24** | CI pending | 2026-06-30 | Push `469ab22` → **Build iOS IPA** (build 23 already on ASC — 90189) |
| Staging WP plugin | `cef9ba7` plugin files | **no** | — | Deploy `radioudaan-app-api` for playlists + live_radio API changes |
| Staging API smoke | 14/14 | — | 2026-06-27 | Re-run after plugin deploy |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+24`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. Upload updated **radioudaan-app-api** plugin to staging (auto playlists, live radio on-air fix).
