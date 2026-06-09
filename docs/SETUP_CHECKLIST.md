# Radio Udaan — setup checklist

Use this once to confirm everything is wired. Check boxes as you complete each item.

---

## Already done in the repo

- [x] GitHub repo: `Romil149/Radio-Udan`
- [x] Cloud APK workflow (`Build staging APK`)
- [x] Full pipeline workflow (`Cloud — Full staging pipeline`)
- [x] Flutter / PHP CI workflows
- [x] Daily staging API smoke (`Staging API smoke`)
- [x] Staging web build (iPhone Safari)
- [x] Operator guide + QA guide + smoke script
- [x] Staging plugin deployed on nexusfleck (34 routes, OTP, YouTube, devices)

---

## You complete (≈15 minutes)

### GitHub

- [ ] **Watch** repo → Custom → Actions failures (optional notifications)
- [ ] Run **Cloud — Full staging pipeline** once and confirm green APK artifact  
  https://github.com/Romil149/Radio-Udan/actions/workflows/cloud-orchestrator.yml

### WordPress staging (nexusfleck)

- [ ] WP Admin → **Radio Udaan App** → set **Support email** or **Helpline phone** (required for smoke + store)
- [ ] Confirm Dev OTP enabled for testers (`123456` if dev mode)
- [ ] Run locally: `bash scripts/staging-api-smoke.sh` → must exit **0**

### Cursor Cloud Agent

- [ ] https://cursor.com/dashboard → **Cloud Agents** → connect **Romil149/Radio-Udan**, branch `main`

### Cursor Automations (optional — Agents Window only)

Open **Automations** in Cursor desktop and create three automations from  
`docs/CURSOR_CLOUD_OPERATOR_GUIDE.md` Part 2:

1. Fix CI on push (GitHub checks failed)
2. Build APK on demand (manual / webhook)
3. Staging health daily (schedule 7:00 AM your time)

> Chat agents cannot open the Automations editor unless you use the **Agents Window**.

---

## Verify end-to-end

```bash
# 1. Staging API
bash scripts/staging-api-smoke.sh

# 2. Flutter static analysis (local)
cd radio_udaan_app && dart analyze lib
```

Then download APK from Actions, install on Android, login with staging OTP, test Radio + Events + More.

---

## Current staging blockers (if smoke fails)

| Check | Fix |
|-------|-----|
| Support email/helpline empty | WP Admin → Radio Udaan App → Support |
| Route missing | Re-upload `radioudaan-app-api` plugin, flush permalinks |
| `/health` 404 | Activate plugin; Settings → Permalinks → Save |

Message your Cursor agent: *"Staging smoke failed — give me exact WP Admin steps."*
