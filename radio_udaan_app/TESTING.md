# Testing Radio Udaan (app + API)

**API base (local):** `https://radio/wp-json/radioudaan/v1`  
**Dev OTP:** `123456` when Development OTP is enabled in WP (constant `RADIOUDAAN_APP_API_DEV_OTP` or Admin → Radio Udaan App → Settings).

---

## Device matrix

Run the same manual checklist on each target you ship. Mark pass/fail per row before release.

| Platform | Command / device | Best for | Limitations |
|----------|------------------|----------|-------------|
| **Chrome** | `flutter run -d chrome --web-port=8765 --dart-define=API_BASE_URL=https://radio/wp-json/radioudaan/v1` → http://localhost:8765 | Fast UI review, auth/forms, legal links | No secure storage parity; **no reliable background radio**; canvas limits automation; file uploads may differ from native |
| **macOS** | `flutter run -d macos --dart-define=API_BASE_URL=...` (after `cd macos && pod install`) | Full desktop UX, audio, registration uploads | Requires CocoaPods; not a store target |
| **Android** | `flutter run -d <device_id> --dart-define=API_BASE_URL=...` on emulator or physical device | **Store target** — TalkBack, notifications, background radio, pickers | Use API 35+ release build for Play submission |
| **iOS** | `flutter run -d <device_id> --dart-define=API_BASE_URL=...` on physical iPhone (recommended) | **Store target** — VoiceOver, lock-screen controls, background audio | Simulator OK for smoke; lock-screen / route-change tests need device |

### WordPress prerequisites (all platforms)

In `wp-config.php` (local):

```php
define( 'RADIOUDAAN_APP_API_DEV_OTP', true );
define( 'RADIOUDAAN_APP_API_DEV_CORS', true );
```

Ensure `https://radio/` resolves and the **radioudaan-app-api** plugin is active.

### Suggested test phone numbers

| Use | Phone (app UI: 10 digits after +91) | E.164 |
|-----|--------------------------------------|--------|
| Manual app sign-in (documented) | `9877001122` | `+919877001122` |
| API script default | — | `+919888877766` |

Use a **fresh** number when testing first-time registration; re-use causes HTTP **409** duplicate registration.

---

## Run the app (Cursor / local)

### Chrome (no CocoaPods)

```bash
cd radio_udaan_app
flutter run -d chrome --web-port=8765 \
  --dart-define=API_BASE_URL=https://radio/wp-json/radioudaan/v1
```

Open **http://localhost:8765** in the browser or Cursor browser panel.

### macOS or iPhone (best UX)

```bash
brew install cocoapods   # once
cd radio_udaan_app/macos && pod install && cd ..
flutter run -d macos --dart-define=API_BASE_URL=https://radio/wp-json/radioudaan/v1
```

Connected device example:

```bash
flutter run -d <device_id> \
  --dart-define=API_BASE_URL=https://radio/wp-json/radioudaan/v1
```

List devices: `flutter devices`

---

## Automated tests (real HTTP, not mocks)

### WordPress API (end-to-end registration)

```bash
cd radio-udan-wordpresss-website/wp-content/plugins/radioudaan-app-api/scripts
bash test-api-flow.sh
```

Covers: `GET /config` → OTP request/verify → `GET /auth/me` → uploads → `POST /events/{id}/registrations`.

### Dart API client (same contract as the app)

```bash
cd radio_udaan_app
dart run tool/live_api_check.dart
```

Expect **5/5** checks against `https://radio/wp-json/radioudaan/v1`.

### Widget smoke

```bash
cd radio_udaan_app
flutter test test/widget_test.dart
```

### Static analysis (before release)

```bash
cd radio_udaan_app
flutter analyze
```

---

## E2E registration (manual app)

**Goal:** Prove app-first registration against live WP Forminator schema (not web forms).

**Preconditions:** Signed in; at least one **open** event (e.g. Udaan Idol / `registration-udaan-idol`); dev OTP enabled if not using real SMS.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open **Events** tab | Open events list loads; empty state only if server has none |
| 2 | Tap an open event | Registration screen loads; fields match WP form (sections if present) |
| 3 | Fill required fields | Inline validation on submit if required fields empty |
| 4 | For file fields, tap **Choose file** | System picker opens; upload succeeds; field shows selected file |
| 5 | Tap **Submit registration** | Success message with entry reference; no crash |
| 6 | Submit again for same event + phone | Duplicate handling: user-visible error (API **409**), not silent failure |
| 7 | (Optional) Cross-check WP admin | Forminator entry exists; tagged `source=app` |

**API parity:** Re-run `test-api-flow.sh` after schema changes to confirm payload keys still match (`upload-1`, `upload-2`, etc. depend on the linked form).

---

## Background radio test (Android + iOS)

**Goal:** Store-safe live stream — playback continues when app is backgrounded; controls remain usable.

**Preconditions:** `GET /config` returns a non-empty `stream_url`; use **native** run (not Chrome).

| Step | Action | Expected |
|------|--------|----------|
| 1 | **Live Radio** tab → **Play** | Stream connects; playing state; no “stream missing” error |
| 2 | Background app (Home / app switcher) | Audio **continues** |
| 3 | **Lock device** | Audio continues; lock-screen / notification shows media controls (platform-dependent) |
| 4 | From lock screen or notification: **Pause** | Playback pauses |
| 5 | **Play** again | Resumes |
| 6 | **Stop** in app (foreground) | Playback stops; idle state |
| 7 | Incoming call or other audio interrupt (optional) | App recovers gracefully; no permanent stuck “loading” |
| 8 | Route change: unplug headphones / Bluetooth (optional) | No crash; sensible pause or continue per OS |

**Fail criteria:** Audio stops when backgrounded; no media notification on Android; crash on lock/unlock; unrelated background modes.

---

## OTP resend test

**Goal:** Rate-limited resend works; dev OTP still `123456` when enabled.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Sign out if needed → enter phone → request code | Navigate to OTP screen; countdown shows (default **60s** from config `otp.resend_delay_sec`) |
| 2 | Before countdown ends, tap **Resend code** | Control disabled; label shows `Resend in Ns` |
| 3 | Wait until countdown reaches **0** | **Resend code** enabled |
| 4 | Tap **Resend code** | Loading state; then success: “A new code has been sent…” |
| 5 | Enter OTP `123456` (dev) → verify | Signed in; main tabs visible |
| 6 | (Optional) Rapid double-tap resend | No duplicate errors surfaced to user; second action blocked while `_resending` |

---

## Account deletion test

**Goal:** Apple 5.1.1(v) / Play account-deletion — in-app path removes app login.

**Preconditions:** Signed in.

| Step | Action | Expected |
|------|--------|----------|
| 1 | **More** tab | **Delete account** enabled when signed in |
| 2 | Tap **Delete account** | Dialog: title/body explain login removal; registrations **not** deleted |
| 3 | Tap **Cancel** | Dialog closes; still signed in |
| 4 | Tap **Delete account** → confirm **Delete account** | API `POST /auth/account/delete` succeeds |
| 5 | After success | Redirect to login; profile shows not signed in |
| 6 | Try **Events** registration or authenticated API | Requires sign-in again |
| 7 | Sign in again with same phone + OTP | New session works |
| 8 | (Optional) `curl` old bearer token on `/auth/me` | **401** / unauthorized after deletion |

**Note:** Event registrations already submitted remain in WP (by design — see `AppStrings.deleteAccountConfirmBody`).

---

## Manual app checklist (quick smoke)

1. **Sign in** — phone `9877001122`, OTP `123456` (dev mode).
2. **Live Radio** — Play / Pause / Stop (stream from config).
3. **Events** — open Udaan Idol → form loads → submit (or duplicate message if already registered).
4. **Library** — shows + what's new lists; open item with YouTube URL (stream only, no download).
5. **More** — Privacy Policy / legal links open; sign out; delete account (full test above).

---

## Accessibility (release blocker)

On **Android (TalkBack)** and **iOS (VoiceOver)**, verify at minimum:

- Login, OTP (including resend), main tabs, radio controls, event list + registration submit, library item, More (legal + delete account).
- Errors and success use audible announcements (`liveRegion` / platform equivalent).

---

## IDE browser testing (Flutter web on :8765)

Flutter web renders mostly on `<flutter-view>`; use **click the phone/OTP field first** so the “Enable accessibility” tree exposes `textbox` refs for `browser_fill`.

| Step | How | Pass criteria |
|------|-----|----------------|
| Bootstrap | Open `http://localhost:8765/` | Splash → shell or login |
| Sign in | Fill `9777001122` (or fresh number), **Enter** | OTP screen; dev hint + `123456` prefill |
| Rate limit | Reuse same number quickly | Red error “Please wait … seconds” (API 429) |
| Verify | Click **Verify and continue** (bottom) or API `otp/verify` | Main shell with 4 tabs |
| Tabs | Bottom nav ~y=615: Library x≈380, Events x≈635, More x≈890 | Tab content changes (not `#/events` URL) |
| CORS | `fetch` from page to `https://radio/wp-json/...` | Works when `RADIOUDAAN_APP_API_DEV_CORS` or allowed origins |

**Note:** OTP rate limits apply during repeated runs; rotate test phones (`9888877766`, `9777001122`).

## Known local setup notes

- **macOS** build failed without CocoaPods (plugins: secure storage, audio).
- **Flutter web** automation is limited (canvas); use native run for full UI and background radio.
- Duplicate registration returns HTTP **409** — expected when re-running API flow on the same phone + event.
- Production builds must **not** ship with dev OTP, debug API URL UI, or cleartext HTTP.

---

## Related docs

- **Store submission:** `RELEASE_CHECKLIST.md`
- **Policy source of truth:** `.cursor/memory/store-compliance.md`
