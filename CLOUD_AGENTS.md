# Radio Udaan — Cloud agents (GitHub Actions)

Your **cloud agents** are automated workflows on GitHub. They run on GitHub’s servers — **no Android Studio, no USB, no local SDK** on your Mac.

**Repository:** https://github.com/Romil149/Radio-Udan  
**Actions dashboard:** https://github.com/Romil149/Radio-Udan/actions

---

## Agent roster

| Workflow | When it runs | What it does | Output |
|----------|--------------|--------------|--------|
| **Cloud — Full staging pipeline** | Manual only | Analyze + PHP lint + staging API + **APK build** | `app-release.apk` artifact |
| **Build staging APK** | Push to `main` (app changes) or manual | Builds Android APK with staging API URL | `app-release.apk` |
| **Build staging Web** | Manual or push (app changes) | Flutter web for **iPhone Safari** testing | `build/web/` zip |
| **CI — Flutter analyze** | Every push/PR (app changes) | `dart analyze lib` — blocks bad code early | Pass/fail |
| **CI — WP plugin PHP lint** | Every push/PR (plugin changes) | `php -l` on all plugin files | Pass/fail |
| **Staging API health** | Daily 06:00 & 18:00 UTC + manual | `staging-api-smoke.sh` against nexusfleck | Pass/fail |

---

## One-click: do everything (recommended)

1. Open https://github.com/Romil149/Radio-Udan/actions  
2. Click **Cloud — Full staging pipeline**  
3. **Run workflow** → branch `main` → **Run workflow**  
4. Wait ~15–20 minutes  
5. Download artifact **`radio-udan-full-pipeline-<sha>`** → `app-release.apk`  
6. Share APK to Android phones (Drive / WhatsApp)

This agent runs: Flutter analyze → PHP lint → staging API check → APK build.

---

## Automatic agents (no click needed)

| You do this | Cloud agent responds |
|-------------|----------------------|
| Push Flutter code to `main` | **CI — Flutter analyze** + **Build staging APK** |
| Push WP plugin code to `main` | **CI — WP plugin PHP lint** |
| Every day | **Staging API health** checks `https://nexusfleck.com/radioudaan/...` |

---

## Staging URLs (baked into builds)

| Build | API URL |
|-------|---------|
| APK / Web (staging workflows) | `https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1` |

---

## Install APK on phone (testers)

1. Download artifact from Actions  
2. Unzip → `app-release.apk`  
3. Upload to Google Drive or WhatsApp  
4. Install on Android (allow “unknown apps” for that source)  
5. OTP on staging: **`123456`** if WP Admin → Development OTP is ON  

No USB cable required.

---

## iPhone testing (no $99, no Xcode)

Run **Build staging Web** → download web artifact → host on Netlify/Firebase/static folder → open URL in **iPhone Safari**.

Limited vs native app (no background radio, weak push). Good for UI smoke only.

---

## If an agent fails

| Failed workflow | Likely fix |
|-----------------|------------|
| **Flutter analyze** | Fix errors: `cd radio_udaan_app && dart analyze lib` |
| **Build staging APK** | Open failed step log; often Gradle/licenses (already fixed in workflow) |
| **Staging API health** | Deploy latest plugin to nexusfleck; WP Admin settings; see `STAGING_QA_GUIDE.md` Part 1 |
| **PHP lint** | Fix syntax in `radioudaan-app-api` |

Paste the red error from the Actions log into Cursor for a fix.

---

## Enable agents (one-time)

Repo → **Settings → Actions → General** → **Allow all actions**.

---

## Related docs

- `scripts/CLOUD_APK_BUILD.md` — APK install details  
- `STAGING_QA_GUIDE.md` — full A→Z manual QA for your team  
- `scripts/staging-api-smoke.sh` — local copy of staging API agent  
