# Task History

### 2026-06-05 — TalkBack / VoiceOver full audit + fixes
**Requested by**: User (max agents; blind/low-vision users must use app easily)
**What was done**: 4 parallel a11y audits (auth, more/shell, events, radio/library). Implemented Critical+High fixes: required field semantics, header landmarks, liveRegion on errors, sendAnnouncement for playback/validation/save, 56dp tap targets, locked account fields, switch/chip semantics dedup, notification read/unread labels, radio/library state announcements, nested button fixes on video cards.
**Files changed**: 30+ across `auth/`, `more/`, `events/`, `radio/`, `library/`, `core/widgets/`, `app_strings.dart`, `brand_tokens.dart`
**Status**: ✅ `dart analyze lib` clean
**Notes**: Manual device QA with TalkBack (Android) + VoiceOver (iOS) still required before store release per `accessibility-blind-users.mdc`.

### 2026-06-05 — Accessibility settings fully wired
**Requested by**: User ("everything needs to be working")
**What was done**: Wired all accessibility prefs app-wide: `AccessibilityScope` + `udaanTextStyle()` for bold; live preview on Settings (reverts on back without save); high-contrast palette via `context.udaan`; reduce-motion static splash dots; event registration + auth widgets + main shell + brand app bar updated.
**Files changed**: `accessibility_scope.dart`, `udaan_text_styles.dart`, `app.dart`, `settings_screen.dart`, `splash_body.dart`, `event_registration_screen.dart`, `registration_form_styles.dart`, `udaan_auth_widgets.dart`, `main_shell_screen.dart`, `brand_app_bar.dart`, `edit_profile_screen.dart`, `help_contact_screen.dart`, `change_password_screen.dart`
**Status**: ✅ `dart analyze lib` clean
**Notes**: Some tab screens (radio, library, events) still use static `UdaanColors` in cards — theme + shared widgets cover most flows; migrate remaining on next UI pass.

### 2026-06-09 — Full push notification pipeline (Flutter + WP admin)
**Requested by**: User (do everything needed to send notifications)
**What was done**: Created Firebase Android/iOS apps in project `radio-udan-2412a`. Added `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, Gradle google-services plugin, iOS `remote-notification` + Firebase in AppDelegate. WP Admin → **Send notification** (single user or all devices). Dev scripts: `verify-fcm.php`, `send-test-notification.php`.
**Status**: ✅ Server FCM OAuth OK; Flutter analyze clean; needs real device login + iOS APNs key in Firebase for iPhone push
**Notes**: Chrome/web skips push. Use WP Admin → Radio Udaan App → Send notification after device registers.

### 2026-06-05 — FCM HTTP v1 server push
**Requested by**: User (use latest FCM API)
**What was done**: Added `class-app-fcm-sender.php` (OAuth2 + `messages:send`). Replaced legacy server key admin field with service account JSON. `RadioUdaan_App_Notifications::create()` now delivers push to registered devices; respects user prefs; prunes invalid tokens.
**Files changed**: `class-app-fcm-sender.php`, `class-app-notifications.php`, `class-app-settings.php`, `class-admin-app-hub.php`, `class-admin-settings-page.php`, `class-admin-pages.php`, `class-app-logger.php`, `radioudaan-app-api.php`
**Status**: ✅ `php -l` clean; needs Firebase service account in WP admin + device test
**Notes**: Flutter client unchanged (`firebase_messaging` SDK). Configure JSON in Settings → Notifications before live push QA.

### 2026-06-09 — More tab suite + notification badge + API test suite
**Requested by**: User (add badge, wire server prefs, detailed pre-live testing)
**What was done**: Notification unread badge on More nav + Notifications menu row. `GET/PATCH /auth/notification-preferences` + `unread_count` on notifications list. Settings save syncs notification toggles to server. `scripts/test-more-suite.sh` — 14/14 API checks passed locally.
**Status**: ✅ API automated; Flutter `dart analyze lib` clean; manual device QA checklist delivered to user
**Notes**: Configure WP support helpline/email + FCM in admin before device push test. `test-api-flow.sh` uses fixed OTP phone — use `test-more-suite.sh` for fresh user.

### 2026-06-05 — Event Registration Stitch UI + blind-user a11y rule
**Requested by**: User (match mockup; app for eye-disabled users — permanent rule)
**What was done**: `.cursor/rules/accessibility-blind-users.mdc`. Registration screen Stitch layout: Udaan top bar, title/intro, peach outlined fields, account-locked name/phone with lock semantics, event summary card (type, date, FREE), orange submit + arrow. WP `GET /events/{id}/form` event block extended with summary, type, start_at, banner. `EventFormInfo` in `form_schema.dart`.
**Files changed**: `event_registration_screen.dart`, `registration_account_prefill.dart`, `widgets/registration_*`, `form_schema.dart`, `app_strings.dart`, `class-radioudaan-app-api.php`
**Status**: ✅ `dart analyze lib` + `php -l` clean
**Notes**: Hot restart after pull. Entry fee stays static FREE until WP field added. Email remains editable when empty on account.

### 2026-06-05 — Library YouTube-only (max agents, Auto model)
**Requested by**: User (go ahead, max agents, sub-agents Auto only)
**What was done**: Rule `.cursor/rules/max-agents-auto.mdc` + specialist-agents model mandate. WP `class-app-youtube-library.php` (Data API v3 proxy, 5 REST routes, admin YouTube tab, featured playlist picker). Flutter Library redesign: search, featured playlists, view all, recent uploads, local Save, `youtube_player_iframe` player. Smoke script `test-youtube-library.sh`.
**Status**: ✅ `dart analyze lib` + `php -l` clean; endpoints return 503 until API key set in WP
**Notes**: Configure Google YouTube Data API key in Settings → YouTube library. Channel `@radioudaan`.

### 2026-06-05 — Live tab schedule + Stitch UI (parallel agents)
**Requested by**: User (“go ahead, max agents”)
**What was done**: WP `GET /library/schedule?days=2` from `radio-shows` CPT (broadcast + repeat ACF fields → `on_air`, `next`, grouped `days`). Flutter Live tab redesign: hero from schedule/config, play ring, WhatsApp card, Upcoming Segments card, Share Live + local favorites (`shared_preferences`), schedule bottom sheet. Fixed model mapping (`items`, `program_host`, `thumbnail_url`, `broadcast_time`).
**Files changed**: `class-app-radio-schedule.php`, `class-radioudaan-app-api.php`, `radioudaan-app-api.php`; `radio_tab.dart`, `radio_schedule_sheet.dart`, `radio_favorites_storage.dart`, `radio_schedule.dart`, `radioudaan_api.dart`, `app_strings.dart`
**Status**: ✅ `php -l` + `dart analyze lib` clean; schedule API HTTP 200
**Notes**: WP timezone may show `+00:00` until site TZ set to Asia/Kolkata. Favorite uses `on_air` id, else `next`. No ±10s seek (MP3 live). Test Share/WhatsApp on real device.

### 2026-06-03 — Design + auth gap fix sprint (parallel agents + merge)
**Requested by**: User (“fix all gaps”, max agents)
**What was done**: Verify-email + reset-password → Udaan dark UI; More tab profile + verify-email tile; `UdaanTheme.dark(branding)` in `app.dart`; removed unused `AuthScreenShell`; `stitch/udaan_core/DESIGN.md` + `stitch/README.md`; AppStrings for OTP/register errors; `more_tab` analyzer fix.
**Files changed**: `lib/app.dart`, auth screens, `more_tab.dart`, `app_strings.dart`, deleted `auth_screen_shell.dart`, `stitch/*`
**Status**: ✅ `dart analyze lib` clean (exit 0)
**Notes**: Commit Stitch PNGs into `stitch/*/screen.png` when available; IDE browser compare on `:8765` still manual.

### 2026-06-04 — App accounts v2 (password + OTP, soft delete)
**Requested by**: User
**What was done**: WordPress plugin v1.0.0 — `wp_ru_app_users` schema v2, `class-app-password-auth.php`, extended OTP purposes, REST routes (`/auth/register`, `/login`, forgot/reset, email verify), soft-delete account, `auth_policy` in `/config`. Flutter wired login/register/OTP/forgot/reset/verify-email screens, `authUserProvider`, worldwide E.164, router guards for phone/email verification.
**Files changed**: Plugin includes (users, auth, otp, password-auth, settings, config, radioudaan-app-api.php); Flutter lib/core/*, lib/features/auth/*
**Status**: ✅ Complete
**Notes**: DB migrate to 2.0 drops legacy OTP-only test users. Run plugin update on WP then `flutter run` against API. Email templates configurable in WP Settings → Security/Auth fields (if UI present).

# Task History

### 3 June 2026 — QA docs: TESTING.md + RELEASE_CHECKLIST.md
**Requested by**: User (QA release manager)
**What was done**: Expanded `radio_udaan_app/TESTING.md` (device matrix, E2E registration, background radio, OTP resend, account deletion, a11y). Added `radio_udaan_app/RELEASE_CHECKLIST.md` condensed from `store-compliance.md`.
**Files changed**: `radio_udaan_app/TESTING.md`, `radio_udaan_app/RELEASE_CHECKLIST.md`
**Status**: ✅ Complete
**Notes**: API base `https://radio/wp-json/radioudaan/v1`; dev OTP `123456`. Not committed.

<!-- Log of completed work. Helps new sessions understand what's already done. -->

### 2026-06-03 — MAX agent sprint #2 (8 parallel + 4 follow-up)
**Done**: Upload progress+retry; registration drafts; fixed `live_api_check.dart` (4/4 PASS); a11y library/more/player/registration; Android POST_NOTIFICATIONS; TESTING.md + RELEASE_CHECKLIST.md; `docs/account-deletion.md` + Help; `e2e-registration.sh`; revoke all tokens on delete; Legal URL warnings; README update; security audit.
**Coordinator fix**: Clear all registration drafts on logout + account deletion (`registration_draft_storage.clearAll`).
**Status**: ✅ `flutter analyze lib/` clean — device E2E + MSG91 + store submit remain human tasks

### 2026-06-03 — Specialist agent sprint (gap analysis, a11y, QA, docs, OTP/validation/audio)
**Agents**: gap vs MASTER_PLAN; a11y on auth/shell/events/radio; QA health/config 0.9.1 + test-api-flow PASS; AI_PROJECT_CONTEXT phase update; OTP resend + countdown; registration required-field validation; audio_service background radio (Android FGS + lock screen).
**Files**: `otp_verify_screen.dart`, `event_registration_screen.dart`, `radio_audio_handler.dart`, `radio_audio_service.dart`, `main.dart`, `AndroidManifest.xml`, `pubspec.yaml`, a11y screens, `.cursor/plan/AI_PROJECT_CONTEXT.md`
**Status**: ✅ `flutter analyze lib/` clean — device test radio background + E2E registration still needed

### 2026-06-03 — Unified WP admin UI (Settings look on all plugin pages)
**What was done**: Orange/dark header + nav active state in `admin.css` for all `.ru-admin` screens; shared `.ru-page-intro`, `.ru-filter-tabs`, `.ru-form-sticky-footer`; intros on Dashboard/Events/Entries/Users/Help/API/Tools/Editor/Entry viewer; nav links for Advanced + API.
**Status**: ✅ Hard-refresh any Radio Udaan App admin page

### 2026-06-03 — Beautiful tabbed WP Settings admin UI
**What was done**: Tabbed settings (Branding, Copy, Connection, Legal, Uploads, OTP, SMS); live phone preview; collapsible copy groups; sticky orange save bar; `admin-settings.css` + `admin-settings.js`; `class-admin-settings-page.php`.
**Status**: ✅ Refresh https://radio/wp-admin/admin.php?page=radioudaan-app-settings

### 2026-06-03 — WP Settings fatal fix + specialist-agents rule
**What was done**: Fixed `OPTION_COPY_EVENTS` typo → `OPTION_COPY_TAB_EVENTS` on App Settings page. Added `.cursor/rules/specialist-agents.mdc` (always apply). Launched WP audit + Flutter a11y sub-agents.
**Status**: ✅ Settings page should load; refresh WP Admin → Settings

### 2026-06-03 — Extended WP copy + branded registration/OTP/library (v0.9.1)
**What was done**: 5 specialist subagents launched; integrated v0.9.1 copy keys (verify_intro, submit_registration, registration_success_prefix, library empty states, unsupported_fields_notice). Flutter: AppCopy extended, event registration + OTP + library player branded.
**Status**: ✅ Complete

### 2026-06-03 — WP-driven branding + professional Flutter UI (v0.9.0)
**What was done**: Plugin `class-app-branding.php`; Settings UI (logo, colors, copy); `GET /config` → `branding` + `copy`. Flutter: `AppBranding`, `AppCopy`, themed shell, branded splash/login/radio/library/events/more.
**Files**: plugin branding + admin; `radio_udaan_app/lib/core/config/app_branding.dart`, `core/theme/`, `core/widgets/`, feature screens
**Status**: ✅ Complete (configure logo/colors in WP Settings before release)

### 2026-06-03 — App runtime testing (Chrome + macOS) + live API tests
**What was done**: `flutter run` Chrome :8765 and macOS native; browser verified Sign-in UI; `dart run tool/live_api_check.dart` (5/5 pass); `test-api-flow.sh`; CORS class + wp-config DEV_OTP/DEV_CORS; CocoaPods installed; TESTING.md added.
**Status**: ✅ Chrome + macOS running; manual OTP tap on web still needed (Flutter canvas)

### 2026-06-03 — v0.8.0 plugin library API + Flutter features
**What was done**: WP `GET /library/shows`, `GET /library/whats-new` (`class-app-library.php`, v0.8.0). Flutter: live radio (`just_audio`), dynamic event registration + uploads, library lists + YouTube iframe player.
**Status**: ✅ Complete (pending device test + a11y/account deletion)

### 2026-06-03 — Flutter app scaffold (radio_udaan_app)
**What was done**: Created `radio_udaan_app/` with Flutter 3.44, Riverpod, go_router, Dio, secure storage; bootstrap + OTP login + 4-tab shell; events list; Android targetSdk 35. Installed Flutter via Homebrew.
**Status**: ✅ Superseded by v0.1 feature pass above

### 2026-06-03 — Store compliance refresh (2026 policies verified)
**What was done**: Re-fetched official sources; updated `store-compliance.md` with 2026 calendar: Apple Feb 6 UGC/chat clarification, Xcode 26/iOS 26 SDK (Apr 28), age ratings; Google API 35, Apr 15 policy pack, Oct 28 contacts/location.
**Status**: ✅ Complete

### 2026-06-03 — Store compliance memory (Apple + Google Play)
**What was done**: Researched App Review Guidelines + Play permissions policies; created `.cursor/memory/store-compliance.md` with Radio Udaan DO/DON'T, checklists, OTP/YouTube/account-deletion rules. Updated project-knowledge, decisions, project-context, AI_PROJECT_CONTEXT.
**Status**: ✅ Complete

### 2026-06-03 — App API v0.7.0: Production hardening + contract completion
**What was done**: Closed-event guards, OTP verify attempts + resend delay + IP limits, registration rate limits + duplicate prevention, schema sections/pages/unsupported_fields, GET /config, GET /auth/me, POST /auth/logout, private uploads + cleanup cron, admin settings expansion, CSV export, production warnings, PII-safe logging.
**Files**: `class-rate-limiter.php`, `class-registration-guard.php`, `class-app-config.php`, `class-app-logger.php`, `class-upload-cleanup.php`, `admin/class-admin-export.php`, updates across OTP/uploads/schema/registration/admin
**Status**: ✅ Complete

### 2026-06-03 — Admin: Registrations vs event sign-ups
**What was done**: Split admin lists — **Registrations** (`radioudaan-app-users`) = OTP app logins (`wp_ru_app_users`, recorded on verify); **Event sign-ups** (`radioudaan-app-registrations`) = Forminator form entries. Dashboard stats + help updated.
**Files**: `class-app-users.php`, `class-admin-app-users.php`, `class-otp-service.php`, admin hub/pages/layout/help/entry-viewer
**Status**: ✅ Complete (only new OTP logins appear until someone logs in again)

### 2026-06-03 — App v0.5.0: Professional mobile admin dashboard
**What was done**: Full branded WP admin UI (Dashboard, Events with open/closed/draft toggles, Registrations from app, Settings, API docs, Tools). Stats, Forminator shortcuts, entry counts, custom CSS/JS.
**Files**: `includes/admin/*`, `assets/css/admin.css`, `assets/js/admin.js`, refactored `class-admin-app-hub.php`
**Status**: ✅ Complete

### 2026-06-03 — App API v0.4.1: WP admin hub
**What was done**: Top-level **Radio Udaan App** menu — dashboard (API URL, health, events table + Forminator links), Settings (upload MB, dev OTP/auth, MSG91), App Events CPT, Form Migration moved under same menu.
**Files**: `class-admin-app-hub.php`, `class-app-settings.php`
**Status**: ✅ Complete

### 2026-06-03 — App API v0.4.0: ru_event CPT + MSG91 skeleton
**What was done**: `ru_event` CPT with admin meta; auto-sync from registry on version bump; API `event_id` now CPT IDs (1214 Udaan Idol, etc.); legacy page IDs still work. MSG91 provider class hooks `radioudaan_app_api_send_otp`. Auth rules documented in `decisions.md`.
**Files**: `class-cpt-ru-event.php`, `class-event-sync.php`, `class-otp-msg91.php`, updated registry/handlers, test script.
**Status**: ✅ Complete (MSG91 credentials still needed for production SMS)

### 2026-06-03 — App API v0.3.0: OTP, uploads, registrations
**What was done**: `POST /auth/otp/request|verify`, `POST /uploads`, `POST /events/{id}/registrations` → Forminator entries with `_radioudaan_source=app`. Smoke test `scripts/test-api-flow.sh` passed (entry_id 1 on Udaan Idol).
**Files**: `class-app-auth.php`, `class-otp-service.php`, `class-app-uploads.php`, `class-registration-handler.php`
**Status**: ✅ Complete (MSG91 production OTP not wired; `ru_event` CPT still optional)

### 2026-06-03 — App API events + form schema (v0.2.0)
**What was done**: `GET /events`, `GET /events/{id}`, `GET /events/{id}/form` wired to live Forminator forms (1207/1208/1209); `class-event-registry.php`, `class-form-schema-builder.php`.
**Status**: ✅ Complete

### 2026-06-03 — All registration forms CF7 → Forminator (live DB)
**Requested by**: User (continue)
**What was done**: Extended **RU Form Migration** to three events; migrated **One Minute Matters** (1208, page 1116) and **Become RJ** (1209, page 1178); Udaan Idol already on 1207. All pages verified on front-end with Forminator markup.
**Status**: ✅ Complete (email notifications parity still optional)

### 2026-06-03 — Udaan Idol CF7 → Forminator migration (live)
**Requested by**: User
**Agents involved**: Manager → Developer (migration tool) → browser verify
**What was done**: Ran **RU Form Migration** for Udaan Idol; imported CF7 form **855** into Forminator **1207** (`EVENT: registration-udaan-idol`); swapped Elementor shortcode on page **825** to `[forminator_form id="1207"]`; WhatsApp redirect on `forminator:form:submit:success`.
**Files changed**: `radioudaan-app-api/includes/class-admin-form-migration.php` (tool), Elementor meta on page 825 (via migration)
**Status**: ✅ Complete (front page verified; email notifications not yet matched to CF7)
**Notes**: Option `radioudaan_forminator_registration-udaan-idol` = 1207. Other registration pages still on CF7.

### 2026-06-03 — Local site recon + App API scaffold
**Requested by**: User
**Agents involved**: Manager (browser + plugin scaffold)
**What was done**: IDE browser audit of `https://radio/`; fixed permalinks/REST (Save Permalinks → `.htaccess`); verified Udaan Idol registration page; activated `radioudaan-app-api` v0.1.0 with `/health` and `/events` stubs.
**Files changed**:
- `radio-udan-wordpresss-website/.htaccess` (WP-generated)
- `radio-udan-wordpresss-website/wp-content/plugins/radioudaan-app-api/` (new)
- `.cursor/memory/project-knowledge.md`
**Status**: ✅ Complete (scaffold only; Gates A–E still open)
**Notes**: Registration pages still use web CF7/Elementor forms, not Forminator + app API.

### 2026-06-03 — Pin canonical workspace path
**Requested by**: User
**Agents involved**: Manager
**What was done**: Confirmed workspace is `/Users/nexus/Documents/Radio Udan` (not Downloads). Documented in plan, memory, rules, and execution rules.
**Files changed**:
- `.cursor/plan/START_HERE.md`
- `.cursor/plan/AI_PROJECT_CONTEXT.md`
- `.cursor/memory/project-knowledge.md`
- `.cursor/rules/project-context.mdc`
- `.cursor/agents/EXECUTION_RULES.md`
**Status**: ✅ Complete

### 2026-06-02 — Improve agent prompts quality
**Requested by**: User
**Agents involved**: Manager → Developer
**What was done**: Standardized all agent prompts with clearer role/non-goals, inputs, deliverables, operating rules, quality bar, and stop/ask triggers; fixed README broken filename reference; added required `.cursor/memory/*` files and created project context rule stub.
**Files changed**:
- `.cursor/agents/README.md`
- `.cursor/agents/agent-01-product-planner.md`
- `.cursor/agents/agent-02-wp-events-forms-architect.md`
- `.cursor/agents/agent-03-wp-app-api-engineer.md`
- `.cursor/agents/agent-04-security-privacy-auditor.md`
- `.cursor/agents/agent-05-flutter-app-architect.md`
- `.cursor/agents/agent-06-flutter-accessibility-specialist.md`
- `.cursor/agents/agent-07-flutter-audio-media-engineer.md`
- `.cursor/agents/agent-08-dynamic-form-renderer-engineer.md`
- `.cursor/agents/agent-09-qa-release-manager.md`
- `.cursor/agents/agent-10-devops-ci-engineer.md`
- `.cursor/agents/agent-11-request-clarifier.md`
- `.cursor/agents/agent-12-real-person-tester.md`
- `.cursor/agents/agent-14-legal-policy-packager.md`
- `.cursor/agents/agent-15-observability-monitoring.md`
- `.cursor/memory/project-knowledge.md`
- `.cursor/memory/decisions.md`
- `.cursor/memory/bugs-found.md`
- `.cursor/memory/task-history.md`
- `.cursor/rules/project-context.mdc`
**Status**: ✅ Complete
**Notes**: Non-negotiables embedded across prompts: in-app registrations only, one Forminator form per event, dynamic schema-driven forms, OTP India.

