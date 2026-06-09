# Build APK in the cloud (no Android Studio on your Mac)

Use **GitHub Actions** to build the staging APK. Your phone only needs the downloaded APK — no USB, no local SDK.

**Staging API baked into the build:**
`https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1`

---

## One-time setup

### 1. Create a GitHub repository

**Repository:** `git@github.com:Romil149/Radio-Udan.git`  
(GitHub: https://github.com/Romil149/Radio-Udan )

### 2. Push this project from your Mac

```bash
cd "/Users/nexus/Documents/Radio Udan"

git init
git remote add origin git@github.com:Romil149/Radio-Udan.git

git add .gitignore .github/ scripts/ STAGING_QA_GUIDE.md
git add radio_udaan_app/
git add radio-udan-wordpresss-website/wp-content/plugins/radioudaan-app-api/

git commit -m "Radio Udaan: Flutter app, WP App API plugin, cloud APK workflow"

git branch -M main
git push -u origin main
```

If `origin` already exists: `git remote set-url origin git@github.com:Romil149/Radio-Udan.git`

**Important:** Do not commit `wp-config.php` passwords, FCM service account JSON, or `.env` files with secrets. `google-services.json` is OK (already in the app repo for team builds).

### 3. Enable GitHub Actions

Repo → **Settings → Actions → General** → allow actions.

---

## Build an APK (every time you need a new test build)

### Option A — Manual (recommended)

1. GitHub → your repo → **Actions**
2. Open **Build staging APK**
3. Click **Run workflow** → branch `main` → **Run workflow**
4. Wait ~10–15 minutes (first run may be slower)
5. Open the completed run → **Artifacts** → download `radio-udan-staging-<sha>.zip`
6. Unzip → `app-release.apk`

### Option B — Automatic

Any push to `main`, `master`, or `staging` that changes `radio_udaan_app/**` triggers a new build.

---

## Install on Android phone (no USB)

1. Upload `app-release.apk` to **Google Drive** or send via **WhatsApp**
2. On the phone: allow install from that app (Settings → Security)
3. Open the APK → **Install**
4. Test with staging OTP **`123456`** if WP Admin has **Development OTP** enabled

---

## Before testers use the APK

Staging server must be ready:

```bash
bash scripts/staging-api-smoke.sh
```

Must exit **0**. See `STAGING_QA_GUIDE.md` Part 1.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Workflow not visible | Push `.github/workflows/build-staging-apk.yml` to GitHub |
| Build fails on `dart analyze` | Fix analyzer errors locally: `cd radio_udaan_app && dart analyze lib` |
| App shows connection error | Staging API down or plugin not deployed — run smoke script |
| Push notifications fail | Expected on debug-signed APK for some devices; login + core flows still testable |

---

## Production builds later

- Add a release keystore (GitHub Secrets) before Play Store submission
- Use a separate workflow with production `API_BASE_URL`
- Turn **off** Development OTP on production WP
