# Radio Udaan — cloud operations (message-only workflow)

Use this so you **only message** Cursor Cloud Agents; agents handle code, CI, APK, and staging checks.

**Repo:** https://github.com/Romil149/Radio-Udan  
**Staging:** https://nexusfleck.com/radioudaan/

---

## Part A — One-time dashboard setup (15 minutes)

Do these once in the browser (logged into Cursor).

### 1. Connect GitHub

1. Open https://cursor.com/dashboard?tab=integrations
2. **GitHub → Connect**
3. Install Cursor GitHub App on **Romil149/Radio-Udan** (read + write for PRs)

### 2. Default cloud agent repo

1. Open https://cursor.com/dashboard?tab=cloud-agents
2. Set **default repository** = `Romil149/Radio-Udan`
3. **Base branch** = `main`

### 3. Cloud environment

1. Same page → **Environments → Create**
2. Choose **Agent-driven setup** (recommended first time)
3. Prompt for setup agent:

   ```
   Install Flutter stable, Dart, and PHP CLI on this Ubuntu VM.
   Run: cd radio_udaan_app && flutter pub get && dart analyze lib
   Verify php -l works on the radioudaan-app-api plugin.
   Save snapshot when green.
   ```

4. **Secrets** (Environment tab) — add only if needed later; never commit these:
   - `STAGING_API_BASE` = `https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1`
   - FCM / MSG91 keys only if agent must send real OTP (usually not)

### 4. Network allowlist (if enabled)

Allow outbound HTTPS to:

- `nexusfleck.com`
- `github.com`
- `pub.dev`

### 5. Spend limit

Set a monthly cloud agent spend cap when prompted (Dashboard → Cloud Agents).

---

## Part B — How you work day-to-day (message only)

### Option 1 — Cursor web / desktop (main)

1. https://cursor.com/agents → **New agent**
2. Repo: **Romil149/Radio-Udan**
3. Paste a task, for example:

   ```
   Fix the latest GitHub Actions failure, push to main, confirm APK artifact builds.
   Read AGENTS.md and .cursor/memory/ first.
   ```

4. Agent clones repo, edits, runs checks, opens PR or pushes (per your settings).

### Option 2 — Phone (PWA)

Safari/Chrome → https://cursor.com/agents → **Add to Home Screen** → message agents like chat.

### Option 3 — Slack (optional)

Integrations → Slack → in channel: `@cursor fix staging API smoke failures`

---

## Part C — Automations (hands-off)

Create at https://cursor.com/automations/new

Copy these three automations:

### Automation 1 — PR quality gate

| Field | Value |
|-------|--------|
| **Name** | Radio Udaan — PR analyze |
| **Trigger** | GitHub → Pull request opened (repo: Romil149/Radio-Udan) |
| **Tools** | Comment on PR, Manage check runs |
| **Prompt** | Run `dart analyze lib` in radio_udaan_app. If PHP changed in radioudaan-app-api, run php -l on touched files. Comment on PR with pass/fail. Do not merge. |

### Automation 2 — APK reminder after merge

| Field | Value |
|-------|--------|
| **Name** | Radio Udaan — post-merge APK |
| **Trigger** | GitHub → Pull request merged (main) |
| **Tools** | Comment on PR |
| **Prompt** | Confirm GitHub Actions "Build staging APK" ran on main. Tell user where to download artifact: Actions → latest run → Artifacts → app-release.apk. |

### Automation 3 — Weekly staging health

| Field | Value |
|-------|--------|
| **Name** | Radio Udaan — staging smoke |
| **Trigger** | Schedule → Every Monday 9:00 |
| **Tools** | Open or update PR |
| **Prompt** | Run scripts/staging-api-smoke.sh against staging. If fail, open a PR or issue summary with missing routes/config from STAGING_QA_GUIDE.md Part 1. |

---

## Part D — What runs automatically without Cursor

| System | Trigger | Output |
|--------|---------|--------|
| **GitHub Actions** | Push to `main` (app changes) | Staging APK artifact |
| **GitHub Actions** | Manual "Run workflow" | Fresh APK |

Download APK: https://github.com/Romil149/Radio-Udan/actions → **Build staging APK** → Artifacts.

---

## Part E — Message templates (copy-paste to agents)

**Build & ship test APK**
```
Trigger or verify GitHub Actions APK build for main. If failed, fix and push.
Tell me the Actions URL and artifact name when green.
```

**Staging not working**
```
Run scripts/staging-api-smoke.sh. Compare staging routes to local plugin.
List blockers from STAGING_QA_GUIDE Part 1. Fix plugin deploy checklist if code is fine.
```

**Full feature**
```
[Describe feature]. Follow AGENTS.md. Flutter + WP plugin if needed.
dart analyze lib must pass. Update .cursor/memory/task-history.md.
```

**QA guide for team**
```
Update STAGING_QA_GUIDE.md section [X] based on latest API behavior.
```

---

## Part F — Checklist: “am I fully set up?”

- [ ] GitHub connected to Romil149/Radio-Udan
- [ ] Cloud environment snapshot saved (flutter pub get OK)
- [ ] AGENTS.md + .cursor/environment.json on `main`
- [ ] GitHub Actions **Build staging APK** green
- [ ] `staging-api-smoke.sh` passes (staging server ready)
- [ ] At least one test Automation created (optional)
- [ ] You can open cursor.com/agents on phone and send one message

When all checked, you only **message** — agents + Actions do the rest.
