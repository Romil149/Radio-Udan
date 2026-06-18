# Radio Udaan — Staging QA Guide (A → Z)

**Staging site:** https://nexusfleck.com/radioudaan/  
**Staging API:** https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1  
**Audience:** QA, devops, and product — complete before calling staging “ready for testers.”

---

## Part 0 — Strict re-test results (last run)

**Latest post-deploy gate (13 June 2026):** With App settings filled (`support` email + helpline, `privacy_policy_url`), `bash scripts/staging-post-deploy-verify.sh` reports **smoke 14/14**, **34 routes**, and **OVERALL: PASS**. Use that script after every FTP/cPanel plugin upload; `bash scripts/load-test-registration-plan.sh` is plan-only (no load).

Run date: **5 June 2026** (automated + API comparison local vs staging).

### Flutter app (local codebase)

| Check | Result |
|-------|--------|
| `dart analyze lib` | **PASS** — no issues |
| `flutter test` | **FAIL** — stale `test/widget_test.dart` (bootstrap UI changed; not a product bug) |
| TalkBack / VoiceOver code audit | **DONE** — fixes merged in prior session |

### WordPress API — **local** (`https://radio/wp-json/radioudaan/v1`)

| Check | Result |
|-------|--------|
| `test-more-suite.sh` | **14/14 PASS** |
| `test-youtube-library.sh` | **PASS** |
| `GET /health`, `GET /config` | **PASS** |
| Registered routes | **34 routes** (full plugin) |
| `dart run tool/live_api_check.dart` | **2/4** — OTP login test phone has no account (403 `account_inactive`). Use `test-more-suite.sh` for auth instead. |

### WordPress API — **staging** (`https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1`)

| Check | Result | Action required |
|-------|--------|-----------------|
| `GET /health` | **PASS** | — |
| `GET /config` | **PARTIAL** | `support` and `legal` are **null** — configure in WP Admin |
| Registered routes | **19 routes** (old plugin) | **Deploy latest `radioudaan-app-api` plugin** |
| `POST /auth/otp/request` | **404** | Plugin deploy + flush permalinks |
| YouTube library (`/library/youtube/*`) | **404** | Plugin deploy |
| `devices/register` (push) | **Missing** | Plugin deploy |
| `auth/notification-preferences` | **Missing** | Plugin deploy |
| `auth/change-password` | **Missing** | Plugin deploy |
| `test-more-suite.sh` | **FAIL** at step 1 | Fix config + plugin |
| Open events | **3 events** | OK — use `event_id` field in API |

**Conclusion:** Do **not** start full manual app QA on staging until **Part 1** is complete. Health/config alone are not enough.

Re-run automated staging gate:

```bash
bash scripts/staging-api-smoke.sh
```

Exit code **0** = safe to begin Part 4 manual QA.

---

## Part 1 — Deploy checklist (devops / backend)

Complete in order. Check each box before handing to QA.

### 1.1 Sync code to staging server

- [ ] Upload/sync entire WordPress site OR at minimum:
  - `wp-content/plugins/radioudaan-app-api/` (full latest from repo)
  - `wp-content/themes/hello-elementor-child/` (if RJ/show templates changed)
- [ ] In WP Admin → **Plugins**, confirm **Radio Udaan App API** is **Active**
- [ ] Plugin version on staging should expose **34 REST routes** (compare with local):
  ```bash
  curl -sS "https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1/" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('routes',{})))"
  ```
  Expected: **≥ 30** routes.

### 1.2 Permalinks & HTTPS

- [ ] WP Admin → **Settings → Permalinks** → Save (flush rewrite rules)
- [ ] Site URL and Home URL use **HTTPS** (`https://nexusfleck.com/radioudaan`)
- [ ] Test: `curl -sS https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1/health`

### 1.3 WordPress Admin — App settings

WP Admin → **Radio Udaan App** (hub + settings):

| Setting | Required for QA |
|---------|-----------------|
| **Development OTP** (`123456`) | **ON for staging QA only** (never production store build) |
| **Stream URL** | Non-empty (e.g. `https://stream.radioudaan.com/...`) |
| **Support helpline + email** | Filled — app Help & Contact uses these |
| **Privacy Policy URL** | Public HTTPS URL — store compliance + More tab |
| **Terms URL** (if used) | Public HTTPS URL |
| **MSG91 / OTP provider** | Configured OR dev OTP on for testers |
| **FCM service account JSON** | Uploaded for push notification tests |
| **YouTube API key** | Set for Library tab |
| **Upload limits** | Match expected registration forms (size/MIME) |
| **Branding** (logo, app name) | Visible on app bootstrap |

### 1.4 Content on staging

- [ ] At least **1 open event** linked to a Forminator form (1:1 mapping)
- [ ] Forminator form fields match what app expects (test one full registration)
- [ ] Radio schedule populated (if schedule UI is in scope)
- [ ] YouTube playlists configured (Library tab)

### 1.5 Database

- [ ] Use **live staging DB** after migration — not the archived `nexusfle_radio.sql` dump
- [ ] Spot-check: open event `event_id`, `form_id`, and Forminator form ID align

### 1.6 Automated gate (must pass)

```bash
# From repo root
bash scripts/staging-api-smoke.sh

# Full API regression (creates temp user)
cd radio-udan-wordpresss-website/wp-content/plugins/radioudaan-app-api/scripts
API_BASE=https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1 bash test-more-suite.sh

API_BASE=https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1 bash test-youtube-library.sh
```

All must exit **0**.

---

## Part 2 — Tester environment setup

### 2.1 Build / run app against staging

**Android — cloud build (no Android Studio / USB on your Mac):**

See **`scripts/CLOUD_APK_BUILD.md`**. Summary:

1. Push repo to GitHub
2. **Actions → Build staging APK → Run workflow**
3. Download **Artifacts** → `app-release.apk`
4. Share APK to phone (Drive / WhatsApp) → install

**Android — local build (only if Android SDK installed):**

```bash
cd radio_udaan_app
flutter devices
flutter run -d <android_device_id> \
  --dart-define=API_BASE_URL=https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1
```

**iOS (VoiceOver):**

```bash
cd radio_udaan_app/ios && pod install && cd ..
flutter run -d <iphone_id> \
  --dart-define=API_BASE_URL=https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1
```

**Release-style build (final sign-off):**

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1
```

### 2.2 Test accounts

| Purpose | Phone (UI: 10 digits) | E.164 | OTP (staging dev mode) |
|---------|----------------------|-------|-------------------------|
| Primary QA | `9877001122` | `+919877001122` | `123456` |
| Fresh registration | Use new number each run | `+919XXXXXXXXX` | `123456` |

**Rules:**

- Reusing a number for **new** registration → expect **409** duplicate (correct behaviour).
- Use a **fresh number** for first-time register tests.
- Document numbers your team uses in a shared sheet (avoid collisions).

### 2.3 What to record per test

For each step: **Pass / Fail / Blocked**, device (Android/iOS), build command, screenshot or screen recording for failures, and API error text if shown.

---

## Part 3 — Automated test reference

| Script | Command | Expect |
|--------|---------|--------|
| Staging smoke gate | `bash scripts/staging-api-smoke.sh` | 0 failures |
| More + settings APIs | `API_BASE=https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1 bash test-more-suite.sh` | 14/14 |
| YouTube library | `API_BASE=... bash test-youtube-library.sh` | All pass |
| Registration E2E (API) | `API_BASE=... PHONE=+919... bash e2e-registration.sh` | Schema + auth OK |
| Full registration + upload | `API_BASE=... bash test-api-flow.sh` | End-to-end entry in Forminator |
| Flutter analyze | `cd radio_udaan_app && dart analyze lib` | No issues |

---

## Part 4 — Manual QA A → Z (app on staging)

Use **physical devices** for final sign-off. Chrome is OK for quick UI only — not for radio background, push, or TalkBack.

### A — Bootstrap & shell

| # | Steps | Expected |
|---|--------|----------|
| A1 | Cold start app (kill + reopen) | Splash → loads branding from `/config`; no infinite spinner |
| A2 | Wait for bootstrap | Main shell **or** login screen; status message readable |
| A3 | Offline / bad API (optional) | Clear error + Retry; TalkBack announces error |
| A4 | Bottom navigation | 4 tabs: Radio, Library, Events, More — each announces on select |

### B — Registration (new user)

| # | Steps | Expected |
|---|--------|----------|
| B1 | Login screen → **Create account** | Register screen loads |
| B2 | Leave fields empty → Submit | Validation error announced + visible |
| B3 | Register with **fresh phone** + valid email/password | Success → OTP or verify flow |
| B4 | Complete phone OTP (`123456` dev) | Account verified |
| B5 | Land on main shell | Signed in; More shows profile |

### C — Login (existing user)

| # | Steps | Expected |
|---|--------|----------|
| C1 | Sign out → Login with phone + password | Success → shell |
| C2 | Wrong password | Error announced + live region |
| C3 | **Email login** path (if enabled) | Works with verified email |
| C4 | Forgot password → reset flow | Email/SMS per WP config; new password works |

### D — OTP flows

| # | Steps | Expected |
|---|--------|----------|
| D1 | Request OTP | Countdown visible; Resend disabled until 0 |
| D2 | Wait → Resend | “New code sent” announced |
| D3 | Wrong OTP | Error announced; no crash |
| D4 | Correct OTP `123456` | Signed in |

### E — Live Radio tab

| # | Steps | Expected |
|---|--------|----------|
| E1 | Tap **Play** | Stream connects; “playing” announced (TalkBack) |
| E2 | **Pause / Stop** | State updates; announced |
| E3 | Background app | Audio continues |
| E4 | Lock screen | Controls available (platform-dependent) |
| E5 | Volume slider | Percent spoken |
| E6 | Schedule sheet | Segments readable; favorite add/remove announced |
| E7 | Share | Copy link announced on success |

### F — Library tab

| # | Steps | Expected |
|---|--------|----------|
| F1 | Featured / playlists load | No empty error if WP configured |
| F2 | Search videos | Results or empty message announced |
| F3 | Open video → **Tap to play** | YouTube player loads; “Playing …” announced |
| F4 | **Save** video | Save/unsave announced; 56dp target |
| F5 | No download | No save-to-device of YouTube file (stream only) |

### G — Events tab

| # | Steps | Expected |
|---|--------|----------|
| G1 | Open events list | ≥1 event; card speaks title + schedule |
| G2 | Tap **Register Now** | Registration form loads |
| G3 | Title shows **event name only** (not long intro sentence) | Correct subtitle |
| G4 | Account name/phone pre-filled | **Read-only** + lock semantics |
| G5 | Dropdown fields (e.g. disability type) | **No horizontal overflow**; tappable rows |
| G6 | Select / radio / checkbox | Option + field context spoken |
| G7 | Date / time pickers | System picker opens; value shown |
| G8 | File upload | Picker → progress % announced → filename on success |
| G9 | Submit empty required field | First field error + scroll + announcement |
| G10 | Submit valid form | Success with entry ID; Forminator entry `source=app` in WP |
| G11 | Submit duplicate (same user + event) | User-visible **409** message |

### H — More tab (signed in)

| # | Steps | Expected |
|---|--------|----------|
| H1 | Profile hero | Name / phone / email shown |
| H2 | **Edit profile** | Mobile locked; email editable |
| H3 | Change email | Verification email flow triggered |
| H4 | Avatar upload | Photo updates |
| H5 | **Notifications** | List loads; unread filter; mark read |
| H6 | **Settings** | Toggles preview live; Save persists; back without save reverts |
| H7 | Accessibility: text size, bold, high contrast, reduce motion | Each affects UI (see prior a11y session) |
| H8 | **Change password** | Requirements spoken met/not met; success re-login |
| H9 | **Help & Contact** | Form submits; helpline/email from config work |
| H10 | Privacy / Terms links | Open in browser |
| H11 | **Logout** | Announced; returns to login |
| H12 | **Delete account** | Confirm dialog; account removed; login required again |

### I — Push notifications (physical device)

| # | Steps | Expected |
|---|--------|----------|
| I1 | Login on **real Android/iOS** (not Chrome) | FCM token registered |
| I2 | WP Admin → Send notification → single user | Received on device |
| I3 | Broadcast (careful on staging) | Respects user notification prefs |
| I4 | Tap notification | Opens sensible screen |

### J — Accessibility sign-off (release blocker)

**Android TalkBack ON** and **iOS VoiceOver ON** — minimum paths:

| # | Path |
|---|------|
| J1 | Login → OTP → main shell |
| J2 | Settings: all 4 accessibility toggles |
| J3 | Event registration full form |
| J4 | Radio play/stop |
| J5 | Library play + save |
| J6 | More: delete account dialog |

**Fail if:** icon-only control with no label, error only by color, field without spoken “required”, or silent playback state change.

---

## Part 5 — WordPress admin verification (after app tests)

| # | Check | Where |
|---|--------|-------|
| W1 | Forminator entry exists after app registration | Entries → correct form |
| W2 | Entry meta `source=app` | Entry detail / custom fields |
| W3 | Uploaded files in media | Correct MIME/size |
| W4 | App user record | Users / app users table per plugin |
| W5 | Notification log | After send test |
| W6 | OTP / API logs | No PII (phone/OTP) in production logs |

---

## Part 6 — Staging → production differences

| Item | Staging | Production store build |
|------|---------|------------------------|
| Dev OTP `123456` | Allowed for QA | **MUST be OFF** |
| API URL | `nexusfleck.com/radioudaan/...` | Production domain |
| Debug API override UI | `kDebugMode` only | Must not appear |
| FCM | Staging Firebase project OK | Production Firebase + APNs key (iOS) |

---

## Part 7 — Sign-off sheet

**Staging URL:** https://nexusfleck.com/radioudaan/  
**API:** https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1  
**App build:** `version ___` / `git commit ___`  
**Plugin deploy date:** ___

| Section | Tester | Date | Pass/Fail | Notes |
|---------|--------|------|-----------|-------|
| Part 1 Deploy checklist | | | | |
| `staging-api-smoke.sh` | | | | |
| `test-more-suite.sh` | | | | |
| `test-youtube-library.sh` | | | | |
| A Bootstrap | | | | |
| B Registration | | | | |
| C Login | | | | |
| D OTP | | | | |
| E Radio | | | | |
| F Library | | | | |
| G Events | | | | |
| H More | | | | |
| I Push | | | | |
| J TalkBack | | | | |
| J VoiceOver | | | | |
| W WP Admin | | | | |

**Approved for wider QA / UAT:** ☐ Yes ☐ No  
**Approver:** _______________

---

## Quick troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| OTP 404 | Old plugin on staging | Deploy plugin + flush permalinks |
| Library empty 404 | YouTube routes missing | Deploy plugin + YouTube API key |
| `support` null in config | Admin not configured | Radio Udaan App → Settings |
| Registration form empty | Event has no `form_id` | Link event to Forminator form |
| OTP 403 inactive | Login OTP without register | Register first or use login password |
| Push not received | No device token / FCM | Physical device login + FCM JSON |
| CORS on web only | Staging CORS | Dev CORS constant or allowed origins |

---

## Related docs

- `radio_udaan_app/TESTING.md` — local dev commands
- `radio_udaan_app/RELEASE_CHECKLIST.md` — store submission
- `.cursor/rules/accessibility-blind-users.mdc` — a11y rules
- `.cursor/memory/store-compliance.md` — Play / App Store policies
