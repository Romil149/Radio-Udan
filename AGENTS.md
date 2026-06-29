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
| **Staging** | `https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1` |
| **Local dev** | `https://radio/wp-json/radioudaan/v1` |

Staging site: https://nexusfleck.com/radioudaan/

## Cursor Cloud specific instructions

### VM toolchain (one-time snapshot)

| Tool | Version / path | Notes |
|------|----------------|-------|
| Flutter | **3.44.1** stable at `$HOME/flutter` | `export PATH="$HOME/flutter/bin:$PATH"` (also in `~/.bashrc`) |
| Dart | 3.12.1 (bundled with Flutter) | Matches `pubspec.yaml` `sdk: ^3.12.1` |
| PHP CLI | 8.3+ (`php-cli` apt) | Plugin lint only — no local WordPress in repo |
| Python 3 + curl | system | Used by `scripts/staging-api-smoke.sh` |

There is **no Docker** and **no local WordPress** in this repo. Cloud agents use the **hosted staging API** for E2E.

### Run the Flutter app (Chrome — preferred on Cloud VM)

Use **tmux** for long-running `flutter run` (do not background a one-shot shell):

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd radio_udaan_app
flutter run -d chrome --web-port=8765 \
  --dart-define=API_BASE_URL=https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1
```

Open **http://localhost:8765**. First compile can take ~2 minutes.

### PHP plugin lint (all files)

```bash
PLUGIN="radio-udan-wordpresss-website/wp-content/plugins/radioudaan-app-api"
find "$PLUGIN" -name '*.php' -print0 | while IFS= read -r -d '' f; do php -l "$f" >/dev/null; done
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

Must exit **0** before telling the user staging is ready for QA.

### APK for testers (no local Android SDK)

Do **not** rely on local `flutter build apk`. Use GitHub Actions:

- Workflow: **Build staging APK** (`.github/workflows/build-staging-apk.yml`)
- Trigger: push to `main` or manual **Run workflow**
- Artifact: `app-release.apk` with staging API baked in

### iOS IPA (GitHub build, manual TestFlight upload)

After one-time GitHub signing secrets (`bash scripts/ios-github-secrets-setup.sh`):

- Workflow: **Build iOS IPA** (`.github/workflows/build-ios-testflight.yml`)
- Download `.ipa` from Actions **Artifacts**
- Upload with **Transporter** on Mac → App Store Connect → **TestFlight**
- Bundle ID: `org.reactjs.native.example.Radio`

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
