# Radio Udaan

Flutter mobile app + WordPress App API for community radio (accessibility-first).

**Staging:** https://nexusfleck.com/radioudaan/  
**GitHub:** https://github.com/Romil149/Radio-Udan  
**Actions (cloud builds):** https://github.com/Romil149/Radio-Udan/actions

---

## Quick start (message-only ops)

You do **not** need Android Studio or USB on your Mac.

| Step | What to do |
|------|------------|
| 1 | Open [Actions → Cloud — Full staging pipeline](https://github.com/Romil149/Radio-Udan/actions/workflows/cloud-orchestrator.yml) → **Run workflow** |
| 2 | When green, download **Artifacts** → `app-release.apk` |
| 3 | Send APK to Android phones (Drive / WhatsApp) and install |
| 4 | Before QA, staging API must pass: `bash scripts/staging-api-smoke.sh` |

Send instructions to **Cursor Cloud Agent** (repo connected) — see `docs/CURSOR_CLOUD_OPERATOR_GUIDE.md`.

---

## Repository layout

| Path | Purpose |
|------|---------|
| `radio_udaan_app/` | Flutter app (Android + iOS) |
| `radio-udan-wordpresss-website/wp-content/plugins/radioudaan-app-api/` | WordPress REST plugin |
| `.github/workflows/` | Cloud CI, APK, web, staging smoke |
| `scripts/staging-api-smoke.sh` | Staging deploy gate |
| `STAGING_QA_GUIDE.md` | Team QA checklist A→Z |
| `CLOUD_AGENTS.md` | GitHub Actions agent roster |
| `docs/CURSOR_CLOUD_OPERATOR_GUIDE.md` | Cursor Cloud + Automations setup |

---

## Cloud agents (GitHub Actions)

| Workflow | Trigger | Output |
|----------|---------|--------|
| **Cloud — Full staging pipeline** | Manual | Analyze + PHP lint + smoke + APK |
| **Build staging APK** | Push to `main` (app) / manual | `app-release.apk` |
| **Build staging Web** | Manual / push | Safari test build |
| **CI — Flutter analyze** | Push / PR | `dart analyze lib` |
| **CI — WP plugin PHP lint** | Push / PR (plugin) | `php -l` |
| **Staging API smoke** | Daily 06:30 UTC / manual | nexusfleck health |

Details: `CLOUD_AGENTS.md` and `scripts/CLOUD_APK_BUILD.md`.

---

## Staging server (one-time devops)

Cloud agents **cannot** SSH into WordPress. After uploading the latest plugin:

1. WP Admin → **Settings → Permalinks** → Save (flush routes)
2. **Radio Udaan App** settings: Dev OTP, support email/helpline, stream URL, YouTube, FCM
3. Run `bash scripts/staging-api-smoke.sh` until exit **0**

See `STAGING_QA_GUIDE.md` Part 1.

---

## Local development (optional)

```bash
cd radio_udaan_app && flutter pub get && dart analyze lib
```

APK builds run in GitHub Actions (no local Android SDK required on this Mac).

---

## Store compliance

Read `.cursor/memory/store-compliance.md` before release builds. No `READ_SMS`; manual OTP only; in-app account deletion; background audio for radio.
