# Radio Udaan — instructions for Cursor Cloud Agents

You work on **Radio Udaan**: Flutter app + WordPress App API. The user delegates via chat; you implement, verify, and open PRs without asking for local Android SDK or Xcode.

## Repository layout

| Path | What |
|------|------|
| `radio_udaan_app/` | Flutter app (Android + iOS) |
| `radio-udan-wordpresss-website/wp-content/plugins/radioudaan-app-api/` | WordPress App API plugin |
| `.cursor/rules/` | Project rules (always read) |
| `.cursor/memory/` | Task history, decisions, bugs — read before work, update after |
| `scripts/staging-api-smoke.sh` | Staging API gate |
| `.github/workflows/build-staging-apk.yml` | Cloud APK build (GitHub Actions) |
| `.github/workflows/build-ios-testflight.yml` | Cloud iOS IPA → TestFlight (GitHub Actions) |
| `scripts/ios-github-secrets-setup.sh` | One-time iOS signing secrets for GitHub |

## Non-negotiables

- **App-first registration** — no web forms for event signup.
- **One Forminator form per event** (1:1).
- Every app registration entry: **`source=app`**.
- **No PII in logs** (phone, OTP, file paths with identity docs).
- **No READ_SMS** on Android; manual OTP only.
- **TalkBack / VoiceOver** quality is a release blocker.
- Data truth: live WP DB — not archived SQL dumps.

## Environments

| Environment | API base |
|-------------|----------|
| **Production (app default)** | `https://radioudaan.com/wp-json/radioudaan/v1` |
| Staging (optional QA only) | `https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1` |

Flutter `AppEnv` bootstraps **production** only (optional `--dart-define=API_BASE_URL=...` override). CI release builds bake production. Staging remains for optional `workflow_dispatch` QA.

Production site: https://radioudaan.com/  
Staging site: https://nexusfleck.com/radioudaan/

## Cursor Cloud specific instructions

### VM toolchain (after snapshot / first boot)

| Tool | Location / version |
|------|-------------------|
| Flutter | `~/flutter` (stable **3.44.1**, matches CI) — use `$HOME/flutter/bin/flutter` or ensure `~/flutter/bin` is on `PATH` |
| PHP | `php` CLI **8.3** (plugin `php -l` only; no local WordPress on the VM) |
| Chrome | `/usr/local/bin/google-chrome` — use `flutter run -d chrome` for UI smoke |

WordPress does **not** run on the VM. Use **staging** for live API: `https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1`.

### Run the Flutter app (web UI smoke)

```bash
cd radio_udaan_app
flutter run -d chrome --web-port=8765 --web-hostname=0.0.0.0 \
  --dart-define=API_BASE_URL=https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1
```

Open http://127.0.0.1:8765/ — bootstrap should load staging branding, then login/register screens.

HTTP-only API smoke (no Flutter UI):

```bash
cd radio_udaan_app
API_BASE_URL=https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1 dart run tool/live_api_check.dart
```

### Before every PR

```bash
cd radio_udaan_app && dart analyze lib
bash scripts/verify-wp-plugin.sh
bash scripts/staging-api-smoke.sh
```

For touched PHP plugin files:

```bash
php -l path/to/file.php
```

**Mandatory gate:** see `.cursor/rules/verification-gate.mdc` — no task is done without the PASS/FAIL table and command evidence.

### Staging API health (needs network)

```bash
bash scripts/staging-api-smoke.sh
```

Must exit **0** before telling the user staging is ready for QA. A common failure is missing support helpline/email in WP Admin → **Radio Udaan App** (app still runs; smoke gate fails until fixed).

### Known VM caveats

- `flutter test test/widget_test.dart` may fail if bootstrap copy changed (CI runs `dart analyze lib` as the primary gate).
- OTP E2E on staging needs an active test account; dev OTP `123456` only when enabled in WP.
- Android APK builds need GitHub Actions (no Android SDK on the VM).

### APK for testers (no local Android SDK)

Do **not** rely on local `flutter build apk`. Use GitHub Actions:

- Workflow: **Build staging APK** (`.github/workflows/build-staging-apk.yml`) — filename kept; bakes **production** by default
- Trigger: push to `main` or manual **Run workflow**
- Artifact: `app-release.apk` with production API baked in
- Optional QA: set `api_base_url` to staging via workflow_dispatch

### iOS IPA → TestFlight (GitHub Actions)

After one-time GitHub signing secrets (`bash scripts/ios-github-secrets-setup.sh`):

- Workflow: **Build iOS IPA** (`.github/workflows/build-ios-testflight.yml`)
- Auto-upload when `APP_STORE_CONNECT_*` secrets are set; else download `.ipa` from **Artifacts** → Transporter
- Bundle ID: `org.reactjs.native.example.Radio`

**Before every push to `main` that changes `radio_udaan_app/**` for TestFlight**, bump in the **same commit**:

1. `radio_udaan_app/pubspec.yaml` — increment the number after `+` (build string)
2. `.cursor/memory/release-state.md` — TestFlight row + commit hash

If CI fails with **90189 Redundant Binary Upload**, increment build again and push (build already exists on App Store Connect).

### Typical user requests → your actions

| User says | You do |
|-----------|--------|
| Fix bug / add feature | Implement, analyze, push branch or PR |
| Test staging | Run smoke script, report pass/fail with evidence |
| Build APK | Trigger or confirm GitHub Actions artifact |
| Deploy plugin to staging | Document WP admin steps; never commit secrets |
| Accessibility | Follow `.cursor/rules/accessibility-blind-users.mdc` |
| Store release | Read `.cursor/memory/store-compliance.md` |

### Delegation

For multi-file work, use focused sub-agents (WP, Flutter, QA, security) per `.cursor/rules/specialist-agents.mdc`.

### Git

- Commit only when user asks.
- If GPG signing fails: `git commit --no-gpg-sign -m "..."`
- Remote: `git@github.com:Romil149/Radio-Udan.git`

### Do not

- Commit `wp-config.php`, FCM service account JSON, or `.env` secrets.
- Force-push `main`.
- Ship placeholder “coming soon” on user-facing paths.
