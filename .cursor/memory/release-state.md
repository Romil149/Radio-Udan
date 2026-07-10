# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+42** (this push) | pushing | 2026-07-10 | A11y + Library player + What's New community + Events keyboard/unlock |
| TestFlight iOS | **2.0.0+42** | CI after push | 2026-07-10 | Device QA: YouTube play/pause, Events fields, schedule Close |
| Staging WP plugin | local zip needed | **no** (redeploy) | 2026-07-10 | Must deploy for `latestcommunitynews` What's New feed |
| Staging API smoke | — | — | — | Re-run after plugin deploy |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+33`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. **Razorpay keys** — WP Admin: enable Razorpay + paste test/live Key ID, Secret, Webhook secret before Pay Online works on device.
2. **Plugin zip** — Redeploy full App API plugin so What's New uses `whats-new` + `latestcommunitynews` (not in-news).
3. User device QA — Library YouTube play/pause, Events registration keyboard/choices, Radio schedule Close, TalkBack/VoiceOver.
