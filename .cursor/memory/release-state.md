# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+57** @ `30d15ca` | **yes** | 2026-07-11 | Fix ShareLargeSheet `prefersPageSizing` iOS 17 guard |
| TestFlight iOS | **2.0.0+57** | CI after push | 2026-07-11 | Rebuild after +56 Swift compile failure |
| Staging WP plugin | **zip ready** `dist/radioudaan-app-api-staging.zip` | **no** | 2026-07-11 | Redeploy for Open-in-app removal + new inbox copy keys |
| Staging API smoke | 19/19 | local | 2026-07-11 | verify-wp 7/7; copy keys **459** staging (local catalog 471) |
| Staging copy keys | 459 | staging | 2026-07-11 | ≥300 gate PASS; redeploy for new keys |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+33`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. **Deploy App API plugin zip to staging** — Open-in-app removed + 12 new inbox copy keys (local catalog 471; staging still 459).
2. **Device test on +57** — More inbox a11y flow after TestFlight lands; confirm share sheet still full screen.
