# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| GitHub `main` | **2.0.0+58** @ `2d05611` | **yes** | 2026-07-11 | Panel tap → detail retry; VoiceOver Refresh crash fix; FCM data title/body |
| TestFlight iOS | **2.0.0+58** | CI after push | 2026-07-11 | Retest notification panel + VO Refresh swipe |
| Staging WP plugin | **needs redeploy** | **no** | 2026-07-11 | FCM data title/body + Open-in-app removal + copy keys |
| Staging API smoke | 19/19 | local | 2026-07-11 | verify-wp 7/7 |
| Staging copy keys | 459 | staging | 2026-07-11 | Redeploy for new keys |

## TestFlight build bump (mandatory — same commit)

When shipping Flutter changes to TestFlight, **always in one commit**:

1. `radio_udaan_app/pubspec.yaml` — increment build after `+`
2. `.cursor/memory/release-state.md` — update TestFlight row + `main` commit

## Open deploy blockers

1. **Deploy App API plugin zip to staging** — FCM title/body in data + Open-in-app removal + inbox copy keys.
2. **Device test on +58** — system notification panel → detail; VoiceOver Refresh then swipe (no crash).
