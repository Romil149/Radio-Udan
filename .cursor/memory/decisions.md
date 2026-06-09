# Architecture Decisions Log
<!-- When a design choice is made, document it here so we don't re-debate it. -->

### 2026-06-05 — FCM HTTP v1 (service account) for server push
**Context**: Legacy FCM server key API is deprecated/shut down; plugin had credentials fields but no sender.
**Options Considered**: Legacy `fcm/send` + server key; FCM HTTP v1 + service account JSON; third-party push gateway.
**Decision**: **FCM HTTP v1** with Firebase service account JSON stored in WP admin (or wp-config constants). OAuth2 JWT signed with OpenSSL; cached access token in transient.
**Reasoning**: Google-supported path; no extra dependencies; aligns with Firebase project used by Flutter `firebase_messaging`.
**Consequences**: Admin must upload service account from Firebase Console (IAM → service accounts → generate key). Invalid device tokens are pruned from `ru_app_devices`. Push fires when notifications are created in DB.

### 2026-06-03 — App auth: OTP at login only; bearer for forms
**Context**: Clarify when OTP vs session token is required for the Flutter app.
**Options Considered**: OTP on every registration submit; OTP only at app login; WordPress cookies.
**Decision**: OTP only for `POST /auth/otp/*` (register/login). Uploads and `POST /events/{id}/registrations` require `Authorization: Bearer` from verify. No second OTP on form submit.
**Reasoning**: Matches app-first UX: gate the app until logged in, then reuse token for all event actions.
**Consequences**: Flutter stores token securely; WP plugin must not add OTP middleware on registration routes.

### 2026-06-03 — `ru_event` CPT as API event source
**Context**: Events were hardcoded in `class-event-registry.php` with `event_id` = registration page ID.
**Options Considered**: Keep page IDs forever; full CPT with admin UI; external CMS.
**Decision**: `ru_event` CPT (`ru_event_code`, `ru_forminator_form_id`, `ru_registration_page_id`, `ru_event_status`). API `event_id` = CPT post ID. Legacy page IDs still resolve via `get_event()` fallback. Auto-sync from registry on plugin version bump + manual sync on Tools → RU Form Migration.
**Reasoning**: Admin can open/close events and edit success copy without code deploys; aligns with MASTER_PLAN §4.
**Consequences**: Flutter must use `event_id` from `GET /events` (e.g. 1214 for Udaan Idol), not page id 825.

### 2026-06-03 — Store compliance baseline (Apple + Google Play)
**Context**: Avoid rejection when shipping Flutter app to App Store and Play Store.
**Decision**: Follow `.cursor/memory/store-compliance.md` for all coding and release. Key engineering choices: server OTP with **manual code entry** (no SMS read permissions); **no Sign in with Apple** unless social logins added; **in-app account deletion**; official **YouTube IFrame/embed** (stream only); **background audio** for radio; complete **privacy disclosures**; accessibility signoff required.
**Consequences**: Flutter manifest must stay minimal on permissions; Agent 14 must publish Privacy Policy before submit; App Review needs demo OTP instructions.

### 2026-06-03 — App API URL + in-app library playback
**Context**: User needs to switch API environment (dev/staging/prod) and play library content inside the app.
**Decision**: (1) `GET /config` returns `api_base_url` (auto from site or WP Settings override). Flutter uses build default `https://radio/wp-json/radioudaan/v1` for dev plus optional persisted server override for QA. (2) Library tab uses **in-app player** (no external browser for core flows); YouTube/library items open in accessible in-app UI with clear controls.
**Consequences**: Plugin may still add `/library/*` endpoints; Flutter needs `youtube_player` or similar + a11y review.

### 2026-06-03 — Gate A: Full MVP in first app release (v1)
**Context**: Whether YouTube Library and other requirements-doc features ship in v1 or Phase 2.
**Decision**: **Everything in the first release** — all 4 tabs and flows from `Radio_Udaan_App_Requirement_Note.docx`: OTP login, Live Radio, YouTube/Library, Events + in-app dynamic registration, More (About, Contact, Profile), accessibility-first (TalkBack + VoiceOver).
**Consequences**: No “Phase 2 defer” for library tab. Flutter scope is large. WP plugin may need **library/content REST endpoints** (`radio-shows`, `whats-new`) in addition to existing event API. Production MSG91, policies, and store work still required before public launch.

### 2026-06-03 — Production code style (human-written)
**Context**: User asked for professional, production-quality code that reads like a real team built it.
**Decision**: Follow `.cursor/rules/coding-standards.mdc` — centralised `AppStrings` / `AppConstants`, `parseApiError()` for Dio, module doc comments, dev UI only in `kDebugMode`, no filler comments.
**Consequences**: All new Flutter/PHP work must match; bump `AppConstants.appVersion` when `pubspec` version changes.

### 2026-06-04 — App accounts v2 (password + OTP, soft delete)
**Context**: Move from phone-only OTP login to full registration (name, email, mobile, password) with mandatory mobile OTP at signup; login via email/mobile + password or mobile + OTP.
**Decision**: WordPress `wp_ru_app_users` holds all app accounts (hashed passwords, E.164 mobile, email). Mobile **always** unique among active users. Email uniqueness **enforced by default** with WP admin toggle to allow duplicate emails (mobile stays unique). Soft-delete on account deletion frees mobile/email for new registration. Email verify optional in profile; admin toggle can require email verification. OTP: iOS/Android **oneTimeCode autofill only** — no READ_SMS. Password min 8 chars. Purge legacy test OTP-only users on deploy. Event registration unchanged.
**Consequences**: New REST routes (`/auth/register`, `/auth/login`, forgot password, etc.); Flutter wires existing login/register screens; plugin Settings → Auth tab.

### 2026-06-03 — Forgot password: verified channels only
**Context**: Email/mobile reset should prove ownership like modern apps.
**Decision**: Email reset sends mail only when `email_verified = 1`. Mobile reset sends OTP only when `phone_verified = 1` (active account). Unverified identifiers get the same generic `status: ok` as unknown accounts (no enumeration). Mobile flow remains OTP verify → `reset-password` with phone + OTP.
**Consequences**: Users with unverified email must verify in-app or use mobile reset. Enforced in `class-app-password-auth.php` and `class-otp-service.php`.

### 2026-06-03 — Admin UX: WordPress hub, not a separate mobile admin app
**Context**: User asked whether a dedicated mobile app admin dashboard would be built.
**Decision**: WordPress + Forminator remain the admin surface; `radioudaan-app-api` adds a **Radio Udaan App** WP admin menu (dashboard, settings, events, form migration links).
**Consequences**: Staff use WP admin only; Flutter is end-user only.

## Template:
### [Date] — [Decision Title]
**Context**: Why was this decision needed?
**Options Considered**: What were the alternatives?
**Decision**: What we chose
**Reasoning**: Why this option over others
**Consequences**: What this means for future work

