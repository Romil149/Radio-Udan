# Radio Udaan — hands-off cloud operations (message-only)

You want to **manage by messaging** while builds, tests, and fixes run in the cloud. This project uses **three layers**:

| Layer | What it does automatically | You do |
|-------|---------------------------|--------|
| **GitHub Actions** | Build Android APK, daily staging API smoke | Download APK from Artifacts when ready |
| **Cursor Cloud Agents** | Code changes, debugging, WP+Flutter work in a cloud VM | Send instructions in chat (web/mobile Cursor) |
| **Cursor Automations** (optional) | React to GitHub/schedule without you typing | One-time setup in Automations UI |

Repo: **git@github.com:Romil149/Radio-Udan.git**

---

## Part 1 — One-time setup (30 minutes)

### A. GitHub (already partly done)

- [x] Code on `Romil149/Radio-Udan`
- [x] **Build staging APK** workflow — builds on every push to `main`
- [x] **Staging API smoke** workflow — daily + manual run

Enable notifications (optional): GitHub → repo → **Watch** → **Custom** → Actions failures.

### B. Cursor Cloud Agents

1. Open **https://cursor.com/dashboard** → **Cloud Agents** (or **Agents** tab).
2. **Connect GitHub** → authorize **Romil149/Radio-Udan**.
3. Set **default branch**: `main`.
4. Enable **Cloud compute** for agents (billing per Cursor plan).
5. Confirm the agent can read the repo at:
   `/Users/nexus/Documents/Radio Udan` equivalent path in cloud: repo root with `radio_udaan_app/` and `radio-udan-wordpresss-website/`.

### C. Cursor Automations (recommended — open in **Agents Window**)

In Cursor desktop: **Automations** (sidebar) → **New automation**.

Create these **three** automations (copy instructions from Part 2 below).

> **Note:** Automations must be created in the Cursor **Automations editor**. If your chat agent cannot open it, use **Agents Window** (not a simple chat tab) and say: *"Create Cursor Automations from docs/CURSOR_CLOUD_OPERATOR_GUIDE.md Part 2"*.

---

## Part 2 — Automation recipes (paste into Automations editor)

### Automation 1 — `Radio Udan: Fix CI on push`

| Field | Value |
|-------|--------|
| **Trigger** | GitHub → **Checks completed** on repo `Romil149/Radio-Udan`, branch `main` |
| **Tools** | Open/update PRs, Manage check runs |
| **Git config** | Repo: `Romil149/Radio-Udan`, branch: `main` |
| **Instructions** | See below |

**Instructions (prompt):**

```
You are the Radio Udaan release engineer. The GitHub Actions workflow failed on main.

1. Read the failed workflow log (Build staging APK or Staging API smoke).
2. Fix the root cause in the repo (Flutter CI, Gradle wrapper, workflow YAML, or staging-api-smoke script).
3. Run mentally: dart analyze lib must pass; Android build must not require local SDK.
4. Commit with --no-gpg-sign if GPG blocks: git commit --no-gpg-sign -m "fix(ci): ..."
5. Push to main. Do not change product behavior unless CI requires it.
6. Reply with: what failed, what you changed, and link to the new Actions run.

Constraints: app-first registration, no PII in logs, staging API is https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1
```

---

### Automation 2 — `Radio Udan: Build APK on demand`

| Field | Value |
|-------|--------|
| **Trigger** | **Webhook** (you call it when you message "build apk") OR **Manual** in Automations UI |
| **Tools** | Manage check runs |
| **Instructions** | Trigger GitHub Actions workflow `Build staging APK` via gh or workflow_dispatch; report artifact download link when green. |

**Instructions:**

```
User wants a fresh staging Android APK.

1. Ensure latest main is pushed.
2. Trigger workflow "Build staging APK" on branch main (workflow_dispatch).
3. When complete, tell the user: GitHub → Actions → latest run → Artifacts → app-release.apk
4. Remind: install on Android via Drive/WhatsApp; staging OTP 123456 if dev mode on WP.

API baked in: https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1
```

---

### Automation 3 — `Radio Udan: Staging health daily`

| Field | Value |
|-------|--------|
| **Trigger** | Schedule — **Every day 7:00 AM** (your local time — set in editor) |
| **Tools** | (none required; agent reads GitHub Action results) |
| **Instructions** | Check last `Staging API smoke` run; if failed, summarize blockers for staging deploy (plugin version, OTP routes, support/legal config). |

**Instructions:**

```
Check GitHub Actions workflow "Staging API smoke" for Romil149/Radio-Udan.

If failed, produce a short report:
- Which smoke check failed (routes, config, events)
- What devops must fix on https://nexusfleck.com/radioudaan/
- Whether app QA should wait

If passed, one line: "Staging API gate OK."

Do not modify code unless user asked in the same thread.
```

---

## Part 3 — What **you** message (cheat sheet)

Use **Cursor Cloud Agent** (web or app) with the repo connected. Copy-paste:

| You want | Message to send |
|----------|-----------------|
| New test APK | `Build staging APK on main and give me the Artifacts link.` |
| Staging broken | `Run staging-api-smoke.sh logic against nexusfleck; fix WP plugin deploy gaps; report only.` |
| App bug | `Fix [screen]: [expected] vs [actual]. dart analyze must pass. Push to main.` |
| WP API change | `Update radioudaan-app-api for [feature]. php -l + test-more-suite against staging.` |
| Full QA pass | `Run strict pre-staging checklist from STAGING_QA_GUIDE.md Part 0–1; list blockers.` |
| TalkBack issue | `Fix VoiceOver/TalkBack on [screen]; follow accessibility-blind-users rule.` |
| Deploy plugin to staging | `Document exact files to upload to nexusfleck for plugin sync; no secrets in repo.` |

The agent works in the **cloud** — you do not need Android Studio or USB.

---

## Part 4 — What already runs without you messaging

| When | What happens |
|------|----------------|
| Every push to `main` (app or workflow files) | **Build staging APK** |
| Every day ~06:30 UTC | **Staging API smoke** |
| You download APK | GitHub → Actions → green run → **Artifacts** |

---

## Part 5 — Staging server (still manual once)

Cloud agents **cannot** SSH into your WordPress server unless you add that integration. Devops must:

1. Deploy latest `radioudaan-app-api` to https://nexusfleck.com/radioudaan/
2. WP Admin: Dev OTP, support email, privacy URL, stream URL, YouTube key, FCM JSON
3. Until `bash scripts/staging-api-smoke.sh` passes, APK installs will fail at login/API

Message your agent: *"Staging smoke failed — give me a deploy checklist for nexusfleck."*

---

## Part 6 — iPhone without $99

Cloud APK is **Android only**. For iPhone without Xcode/$99, message:

`Build Flutter web for staging API and tell me how to host on nexusfleck for Safari testing.`

---

## Related files

- `scripts/CLOUD_APK_BUILD.md` — APK download steps
- `STAGING_QA_GUIDE.md` — team QA A→Z
- `.github/workflows/build-staging-apk.yml`
- `.github/workflows/staging-api-smoke.yml`
