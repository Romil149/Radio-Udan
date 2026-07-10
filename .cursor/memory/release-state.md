# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+50** @ `bf64868` | **yes** | 2026-07-10 | Notification detail TalkBack fix + load more; iOS foreground push presentation; App Users soft-delete; FCM iOS/Android breakdown |
| TestFlight iOS | **2.0.0+50** | CI after push | 2026-07-10 | Use +50; skip +47/+48 if crash |
| Staging WP plugin | local zip needed | **no** | 2026-07-10 | **Must redeploy** — App Users BUG-025/026 + FCM platform stats |
| Staging API smoke | verify-wp 7/7 | local | 2026-07-10 | Copy catalog 447 keys |
| Staging copy keys | 444+ | staging | 2026-07-10 | ≥300 gate PASS |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+33`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. **Deploy full App API plugin zip to staging** — App Users Pause/Delete + soft-delete tombstones + FCM iOS/Android stats.
2. **Firebase APNs key** — keys show in Console but send returns `THIRD_PARTY_AUTH_ERROR`; verify Key `2LBVNRUSS7` is a real **APNs** key (not App Store Connect API) or create a new APNs key and re-upload.
3. **Device register** — TestFlight **+50**; confirm APNs + FCM + server accept in diagnostics.
