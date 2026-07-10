# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+47** (this commit) | pushing | 2026-07-10 | iOS classic AppDelegate (no UIScene) + APNs; Razorpay Payment Link fixes |
| TestFlight iOS | **2.0.0+47** | CI after push | 2026-07-10 | Retest APNs token after install |
| Staging WP plugin | local zip needed | **no** (redeploy) | 2026-07-10 | Razorpay Payment Link + FCM SA `72232` still need deploy |
| Staging API smoke | 19/19 | yes (routes) | 2026-07-10 | Health previously `cbfdc` + 0 devices |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+33`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. **WP FCM** — paste service account from Firebase **`radio-udaan-72232`** (not `cbfdc`); Test FCM; deploy plugin zip.
2. **Device register** — install **+47** (not +46), allow notifications, confirm diagnostics show APNs token + `push_devices_registered` ≥ 1.
3. Firebase production APNs key — **done**.
4. **iOS APNs** — +46 AppDelegate handoff insufficient under UIScene; +47 reverts to classic AppDelegate (no `UIApplicationSceneManifest`).
