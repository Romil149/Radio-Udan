# Radio Udaan — Execution Rules (All Agents)

Every agent working on this project **must** follow these rules. No exceptions.

**Workspace root**: `/Users/nexus/Documents/Radio Udan`

---

## Rule 1 — Never assume anything

### What this means
- If a requirement, value, credential, URL, policy, threshold, environment (prod vs staging), or feature scope is **not explicitly confirmed by the human**, you must **stop and ask**.
- Do not “fill in gaps” based on similar projects or common patterns.
- Do not implement defaults silently—propose defaults and wait for confirmation.

### Examples that require human confirmation
| Situation | Wrong | Right |
|-----------|-------|-------|
| OTP provider not specified | Implement Firebase | Ask: MSG91 vs 2Factor vs other? |
| Max upload size not specified | Use 10MB | Ask human; note admin will configure in WP |
| YouTube tab in MVP unclear | Build it | Ask Gate A |
| Which events to migrate first | Pick randomly | List live URLs from IDE browser; ask human |
| Prod vs staging URL | Guess | Ask which environment to use |

### Output when blocked
Use this format:
```
⚠️ NEED HUMAN CONFIRMATION
- Question: [specific question]
- Why it blocks work: [reason]
- Options (if applicable): A / B / C
- Default suggestion (not implemented until confirmed): [suggestion]
```

---

## Rule 2 — All web work must use the IDE browser

### What this means
Any task involving the website must use **Cursor IDE browser MCP tools**:
- Navigate, snapshot, click, type, scroll, screenshot
- **Do not** claim a page “probably works” without opening it in IDE browser
- **Do not** use external browsing tools or memory from past chats as proof

### Standard browser workflow
1. `browser_tabs` — check open tabs
2. `browser_navigate` — go to URL
3. `browser_lock` — lock before multi-step interaction
4. `browser_snapshot` — read page structure (accessibility tree)
5. Interact using snapshot `ref` values (`browser_click`, `browser_type`, etc.)
6. `browser_unlock` — when finished

### When to stop and ask human
- WordPress admin login required
- OTP code needed for testing
- CAPTCHA or 2FA
- Destructive actions (delete forms, purge entries, change production settings)
- Permission denied

---

## Rule 3 — Be strict, evidence-based, and auditable

### Every test or verification report must include
- **Environment**: prod / staging / local
- **URL(s)** tested
- **Steps** taken (numbered)
- **Expected** vs **Actual**
- **Evidence**: screenshot path, snapshot excerpt, or API response (redact secrets/PII)
- **Timestamp** (if available)

### Bug reports
Use the format in `agent-12-real-person-tester.md`.

### Code changes
- Minimal scope—only what the task requires
- Match existing conventions in the codebase
- Do not commit unless human asks

---

## Rule 4 — Respect project architecture (do not drift)

### Locked architecture decisions
| Layer | Technology |
|-------|------------|
| Mobile app | Flutter (fresh start) |
| Forms admin | Forminator (free), **one form per event** |
| Mobile backend | Custom WP plugin `radioudaan-app-api` |
| OTP | Provider adapter (MSG91 suggested; human confirms) |
| Registrations | In-app only; `source=app` on every entry |

### Do NOT
- Build app registration against CF7 internals
- Use website header menu as event source of truth
- Hardcode form fields in app (use dynamic schema)
- Extend old Android Java app as base
- Skip accessibility requirements

---

## Rule 5 — PII and secrets

- Never print OTP codes, API keys, DB passwords, or full phone numbers in logs/reports unless human explicitly approves test data.
- `wp-config.php` in WordPress folder contains real credentials—do not copy into docs or commits.
- Registration exports contain sensitive disability/UDID data—handle with care.

---

## Rule 6 — Handoffs between agents

When finishing work for another agent, use the handoff format at the bottom of each `agent-*.md` file.

Include:
- What was done
- What is blocked
- What human must confirm
- Exact file paths changed

---

## Quick reference — read order for new chat

1. `.cursor/plan/START_HERE.md`
2. `.cursor/plan/AI_PROJECT_CONTEXT.md`
3. `.cursor/plan/MASTER_PLAN.md`
4. This file (`EXECUTION_RULES.md`)
5. Relevant `agent-XX-*.md`
