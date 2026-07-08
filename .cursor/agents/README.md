# Radio Udaan — AI Agent Team

This folder contains **ready-to-run prompts** for a dedicated AI agent team to deliver the **Radio Udaan cross‑platform app + WordPress backend**.

> **New chat?** Read first: `.cursor/plan/START_HERE.md` → `.cursor/plan/AI_PROJECT_CONTEXT.md` → `.cursor/plan/MASTER_PLAN.md` → `.cursor/agents/EXECUTION_RULES.md`

## How to use
- Pick the relevant agent prompt file (e.g. `agent-03-wp-app-api-engineer.md`).
- Start a new agent/chat and paste the prompt content.
- Keep agents aligned using the handoff format at the bottom of each prompt.
- All agents must follow `.cursor/agents/EXECUTION_RULES.md`.

## Team (max coverage, minimal overlap)
1. **Agent 01 — Product Planner**: locks requirements, MVP, acceptance criteria (accessibility-first).
2. **Agent 02 — WordPress Events & Forms Architect**: defines WP event model, Forminator “one form per event” conventions, admin workflows.
3. **Agent 03 — WordPress App API Engineer**: implements WP plugin endpoints (events, schema, registrations, uploads, OTP façade).
4. **Agent 04 — Security & Privacy Auditor**: threat model, rate-limit/abuse controls, PII handling, upload hardening, GDPR-ish hygiene.
5. **Agent 05 — Flutter App Architect**: app structure, routing, state, networking, offline/error strategy.
6. **Agent 06 — Flutter Accessibility Specialist**: TalkBack/VoiceOver correctness, semantics/focus, testing scripts.
7. **Agent 07 — Flutter Audio/Media Engineer**: streaming, background audio, interruptions, lockscreen controls.
8. **Agent 08 — Dynamic Form Renderer Engineer**: renders app forms from server schema + uploads + validation.
9. **Agent 09 — QA & Release Manager**: test matrix, regression, store checklists, rollout plan.
10. **Agent 10 — DevOps/CI Engineer**: CI for WP plugin + Flutter, environments, build signing hygiene.
11. **Agent 11 — Request Clarifier**: turns short requests into precise specs; asks for human confirmation on all ambiguities.
12. **Agent 12 — “Real Person” Tester**: end-to-end tests via browser/builds; stops for human login/OTP/admin steps.
16. **Agent 16 — TalkBack / VoiceOver Device Tester**: physical-device screen-reader QA; expert KB at `.cursor/memory/accessibility-kb/`; invoke `@agent-16-talkback-voiceover`.
13. **Agent 14 — Legal/Policy Packager**: App Store/Play compliance (Privacy Policy, Terms, data disclosure for OTP+uploads, retention).
14. **Agent 15 — Observability/Monitoring**: crash reporting, API error logs, registration failure alerts, stream uptime monitoring.

## Global non-negotiables
- **All registrations happen inside the app** (app-first).
- **One Forminator form per event** in WordPress.
- App consumes **dynamic form schemas** from the WP App API to reduce app updates.
- Every submission is tagged with **source=app** (and optionally `source=web` for web).
- Accessibility is a **first-class requirement** (TalkBack + VoiceOver).
- **No assumptions**: if something is unclear, the agent must ask for **human confirmation** before proceeding.
- **Browser work**: any website/admin verification must be done via the **IDE browser** (not guessed).

