# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+51** @ `0d2c0a8` | **yes** | 2026-07-11 | iOS large share sheet; Library Clear a11y; Pay Online TalkBack; iOS Razorpay no callback_url |
| TestFlight iOS | **2.0.0+51** | CI after push | 2026-07-11 | Use +51; skip +47/+48 if crash |
| Staging WP plugin | **zip ready** `dist/radioudaan-app-api-staging.zip` | **no** | 2026-07-11 | Deploy for Payment Link + copy keys + App Users + FCM stats |
| Staging API smoke | 19/19 | local | 2026-07-11 | verify-wp 7/7; copy catalog 455 local |
| Staging copy keys | 447 | staging | 2026-07-11 | ≥300 gate PASS; redeploy for new keys |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+33`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. **Deploy full App API plugin zip to staging** — Payment Link (no callback_url) + App Users + FCM stats + new copy keys.
2. **Firebase APNs key** — **DONE 2026-07-11** Key `UKUT4P22CH`; user confirmed iOS push banner works.
3. **Device register** — TestFlight **+51**; confirm share sheet + Library Clear on device.
