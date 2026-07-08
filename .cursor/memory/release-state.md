# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+36** @ `68d0b05` | pushed | 2026-07-08 | Push diagnostics screen + step-by-step registration logging |
| TestFlight iOS | **2.0.0+36** | CI pending | 2026-07-08 | Triggered by push to `main` |
| Staging WP plugin | partial | **yes** | 2026-07-08 | API smoke 19/19; redeploy full zip if `class-admin-donations.php` missing on server |
| Staging API smoke | 19/19 | — | 2026-07-08 | Includes `/donate/*` routes + `info_hub.donate.razorpay` |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+` (e.g. `2.0.0+33`)
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

Never push app code to `main` without bumping the build if the last build is already on App Store Connect.

## Open deploy blockers

1. **Razorpay keys** — WP Admin: enable Razorpay + paste test/live Key ID, Secret, Webhook secret before Pay Online works on device.
2. **Plugin zip** — If donate admin fatal on server, upload `dist/radioudaan-app-api-staging.zip` (full folder replace).
3. User device QA — Donate Pay Online (Android native + iOS Safari), 80G + PAN, What's New, TalkBack/VoiceOver.
