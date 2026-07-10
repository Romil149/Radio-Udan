# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+44** @ `bcdc2c5` | **yes** | 2026-07-10 | Push: iOS APNs AppDelegate handoff, Android Firebase init diagnostics, FCM project mismatch guards |
| TestFlight iOS | **2.0.0+44** | CI after push | 2026-07-10 | Device QA: push diagnostics after production APNs key uploaded |
| Staging WP plugin | local zip needed | **no** (redeploy) | 2026-07-10 | Deploy for FCM project match warnings + About Us + Save fix; paste `radio-udaan-72232` SA |
| Staging API smoke | 19/19 | yes (routes) | 2026-07-10 | Health still showed `cbfdc` + 0 devices before SA fix |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+33`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. **WP FCM** — paste service account from Firebase **`radio-udaan-72232`** (not `cbfdc`); Test FCM; deploy plugin zip.
2. **Device register** — install +44, allow notifications, confirm `push_devices_registered` ≥ 1.
3. Firebase production APNs key — **done** (same Key ID as development).
