# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+43** | pushing | 2026-07-10 | About Us info_hub, YouTube optimistic loader, OS share, settings Save fix |
| TestFlight iOS | **2.0.0+43** | CI after push | 2026-07-10 | Device QA: About Us, YouTube loader, share sheet |
| Staging WP plugin | local zip needed | **no** (redeploy) | 2026-07-10 | Deploy for `info_hub.about` + settings Save (BUG-022) + community What's New |
| Staging API smoke | 19/19 | yes (routes) | 2026-07-10 | Staging still missing `info_hub.about` until plugin zip |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+33`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. **Razorpay keys** — WP Admin: enable Razorpay + paste test/live Key ID, Secret, Webhook secret before Pay Online works on device.
2. **Plugin zip** — Redeploy full App API plugin for What's New (`latestcommunitynews`) + About Us (`info_hub.about`) + **settings Save fix (BUG-022)**. Then fill Settings → About tab → About Us.
3. User device QA — Library YouTube loader, About Us content, Radio OS share, TalkBack/VoiceOver.
