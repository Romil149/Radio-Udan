# Radio Udaan (Flutter)

Accessibility-first Android + iOS app for Radio Udaan. Consumes the WordPress **radioudaan-app-api** plugin (`/wp-json/radioudaan/v1`).

## Prerequisites

- Flutter SDK 3.44+ (`brew install --cask flutter`)
- Local API running at `https://radio/wp-json/radioudaan/v1` (or override below)
- Xcode 26+ / iOS 26 SDK for App Store builds (see `.cursor/memory/store-compliance.md`)

## See & test the app

- **[TESTING.md](TESTING.md)** — Chrome side-by-side, macOS/iPhone, API smoke tests, manual QA matrix
- **[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)** — pre-submission checklist for App Store / Play Console

Quick start (Chrome in browser):

```bash
flutter run -d chrome --web-port=8765 \
  --dart-define=API_BASE_URL=https://radio/wp-json/radioudaan/v1
```

Open http://localhost:8765 — dev OTP is `123456` when enabled in WP.

## Run (dev)

```bash
cd radio_udaan_app
flutter pub get
flutter run --dart-define=API_BASE_URL=https://radio/wp-json/radioudaan/v1
```

If your Mac trusts the local `radio` host and WP has **dev OTP** enabled, the verify screen may prefill the code from the API response.

## Branding (WordPress-controlled)

Colors, logo, app name, tagline, tab labels, and key on-screen messages come from **`GET /config`** (`branding` + `copy`). Configure in WP Admin → **Radio Udaan App → Settings → App branding & appearance**. The app uses website defaults (orange `#ff6b00`) until you save custom values.

## Code style

Production conventions are documented in `.cursor/rules/coding-standards.mdc` (human-written tone, restrained comments, centralised strings, no debug UI in release builds).

## Project layout

```
lib/
├── main.dart, app.dart
├── core/          # API, auth storage, config, router, theme
└── features/      # bootstrap, auth, shell (4 tabs), events, …
```

## Implemented (v0.1)

- Bootstrap: `GET /config`, session restore, optional API URL override storage
- OTP login: request + verify (manual SMS entry — no `READ_SMS`); **OTP resend** with server-driven cooldown
- Main shell: **Live Radio**, **Library**, **Events**, **More**
- **Live Radio** — `just_audio` + **`audio_service`** (lock-screen / background playback, Android foreground notification)
- **Events** — list + dynamic form + file upload with **progress** + registration submit; **draft save** (debounced, per event)
- **Library** — shows + what's new from `GET /library/*`, in-app YouTube player
- **More** — About, Contact, Privacy, **in-app account deletion** (`POST /auth/account/delete`)
- Sign out → `POST /auth/logout` + clear secure token
- Android `targetSdk` / `compileSdk` **35**

## Next (release blockers)

1. **MSG91** — production OTP provider configured and verified on real devices (not dev OTP)
2. **Device E2E** — complete manual matrix in [TESTING.md](TESTING.md) on Android + iPhone (TalkBack / VoiceOver included)
3. **Store submit** — all items in [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) before App Store Connect / Play Console upload

## Compliance

See `/Users/nexus/Documents/Radio Udan/.cursor/memory/store-compliance.md` before every release.
