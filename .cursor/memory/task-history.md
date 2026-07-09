
### 2026-07-09 — Form focus + blind-user validation (build 38)
**Requested by**: User — fix keyboard Next chaining and scroll/focus on validation errors.
**What was done**: `revealFieldForValidation` + `FormFieldAnchor`; `UdaanLabeledField` Next→`nextFocus()`; auth/profile/help/password screens get FocusNodes + scroll/focus on error; event registration focuses field after scroll.
**Verification**: `dart analyze lib` = 0 errors.
**Status**: ✅ Pushed to `main` — build 38.

### 2026-07-08 — Push diagnostics screen (build 36)
**Requested by**: User — live logging to debug zero device registrations on release builds.
**What was done**: `PushDiagnostics` recorder; instrumented `push_notification_service.dart` (permission, APNs, FCM token, API); `PushDiagnosticsScreen` in Settings with Run / Copy log / Clear; bumped **2.0.0+36**.
**Verification**: `dart analyze lib` = 0 errors.
**Status**: ✅ Pushed to `main` — CI APK/TestFlight pending; user runs Settings → Push diagnostics → Copy log.
**Requested by**: User — "do all these" (full OTP/DLT go-live after VILPOWER PE-TM approval).
**What was done**:
- **MSG91 (browser)**: Added PE-TM chain entity `1101451530000096415` → TM-D `1302157225275643280` (**Active**); mapped DLT PE ID on sender **RUDAAN**; clicked **Re-verify** on template `Radio_Uddan_OTP` → status **Pending by MSG91**.
- **Plugin (local)**: OTP SMS text aligned with DLT suffix in `class-otp-msg91.php`; packaged `dist/radioudaan-app-api-staging.zip`.
**Verification**: `verify-wp-plugin.sh` 7/7; staging smoke **19/19**; `dart analyze lib` 0 errors.
**Status**: ✅ OTP live on staging (user confirmed SMS 2026-07-08). Push: FCM configured; device registration + admin send test pending on physical device.
**Notes**: See `.cursor/memory/otp-production-setup.md` for IDs and deploy steps.

**Requested by**: User — fresh Firebase project for push; align app + staging WP.
**What was done**: Replaced `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, `firebase.json` for project `radio-udaan-72232`; bumped build **2.0.0+34**; staging FCM service account + APNs configured by operator.
**Status**: ✅ Pushed to `main` — CI APK/TestFlight pending; device push QA after install.
**Notes**: Web/Chrome skips push. Real device required to register FCM token.

### 2026-07-08 — Razorpay donations + 80G (Pay Online on Donate screen)
**Requested by**: User — Razorpay before Scan & Donate; presets + custom amount; guest OK; full WP backend; Android native checkout; iOS payment link; 80G toggles + optional PAN; WP PDF email.
**What was done**:
- **WP (local)**: donations settings/DB/Razorpay client/REST (`/donate/orders`, `/donate/verify`, `/donate/webhook`), 80G PDF email, admin toggles + donations list, copy catalog (+14 keys), `info_hub.donate.razorpay` in `/config`.
- **Flutter (local)**: `RazorpayDonateConfig`, API methods, `DonatePayOnlineCard`, `DonateRazorpayService` (Android SDK / iOS Safari link + verify), wired into `donate_screen.dart`, `razorpay_flutter` dependency.
- **Smoke**: script checks donate routes + `info_hub.donate.razorpay`.
**Verification**: `dart analyze lib` = 0 errors; `verify-wp-plugin.sh` = 7/7 (428 copy keys); staging smoke = **15/19** (donate routes + razorpay config — deploy plugin to staging).
**Status**: ✅ Code complete locally. Staging deploy + Razorpay keys in WP admin required before live QA.
**Notes**: App Review paste text in `.cursor/memory/app-review-donations.md`. Deep link `radioudaan://donate/verify`. Android proguard rules added.

### 2026-07-08 — About tab What's New (combined feed + push)
**Requested by**: User — What's New entry under About Us; combined `whats-new` + `radio-udaan-in-news` feed; detail screens; push on publish to all device users; tap opens detail.
**What was done**:
- **WP**: `GET /library/updates`, detail routes, `class-app-updates-notifications.php` (first-publish hook + force push), copy catalog keys (+9), smoke script route + test; fixed `single-radio-udaan-in-news.php` theme template.
- **Flutter**: models, API, providers, `WhatsNewListScreen` + `WhatsNewDetailScreen`, About tab tile, `whats_new_deep_link.dart`, push + inbox tap routing for `whats_new_detail` payload.
**Verification**: `dart analyze lib` = 0 errors; `verify-wp-plugin.sh` = 7/7 (414 copy keys); staging smoke = **16/16** (plugin deployed; `/library/updates` returns 33 items).
**Status**: ✅ Complete (local code + staging API). App changes not on `main`/TestFlight yet. Manual device QA + push tap still pending.
**Notes**: FCM on staging may still need BUG-019 fix for real push delivery.

### 2026-07-08 — Keyboard Done/Next on More forms + country picker
**Requested by**: User (add keyboard Done button pattern app-wide for blind users)
**What was done**: Added `textInputAction` (Next/Done/Search), `onSubmitted`, and `onTapOutside` → `dismissKeyboard` to:
- `edit_profile_screen.dart` — Name: Next; Email: Done + submit on Done
- `change_password_screen.dart` — Current/New: Next; Confirm: Done + submit on Done
- `help_contact_screen.dart` — Name/Email/Subject: Next; Message: Done + send on Done
- `accessible_country_picker_sheet.dart` — Search: Search action + dismiss on submit
**Verification**: `dart analyze lib` = 0 errors (8 pre-existing info lints)
**Status**: ✅ Complete (local)

### 2026-07-08 — Email verification made manual (no auto-send on login)
**Requested by**: User ("email verification OTP only sends when we click Verify email, nothing else"). Popup answers: let user into app after phone OTP; only a Send button on the Verify Email screen sends the code; leave WP `require_email_verification` toggle as-is.
**What was done**:
- **Server** (`class-otp-service.php`, `class-app-password-auth.php`): removed the 3 auth-time auto-sends of the email verification code — phone OTP login, password login, and activate-after-phone-verify now just issue the session. Explicit resend route (`/auth/email/resend`) unchanged. Profile email-change auto-send (`class-app-profile.php:79`) left as-is.
- **App**: `verify_email_screen.dart` no longer auto-sends on open; shows a "Send code" primary button first, then reveals the 6-digit entry + Verify after a code is sent. Router (`app_router.dart`) no longer force-routes to `/verify-email`; `otp_verify`/`login`/`email_login` go straight into the app. `more_tab.dart` opens Verify Email without auto-send. Removed unused `VerifyEmailRouteArgs.sendCodeOnOpen`. Added copy key `verify_email_send_prompt`.
**Verification**: dart analyze lib = 0 errors (8 pre-existing info lints); verify-wp-plugin.sh = 7/7 (405 copy keys); staging smoke = 14/14. PHP -l clean on both changed files.
**Status**: ✅ Complete (local). Not deployed — WP plugin must be re-deployed to staging for server behavior to take effect.
**Notes**: Email verification is now fully optional/manual; the WP `require_email_verification` toggle no longer gates app entry (app ignores it for routing). Flag to user if they later want login gating back.

### 2026-07-08 — VILPOWER DLT content template submitted (OTP)
**Requested by**: User (header approved; proceed with OTP setup in browser)
**What was done**: Via VILPOWER browser session — confirmed approved header **RUDAAN**; submitted transactional content template **Radio Udaan OTP** (ID `1107178349700604138`, pending). MSG91 account `udaan11` logged in; AuthKey view blocked on mobile verification. Documented full pipeline in `.cursor/memory/otp-production-setup.md`.
**Status**: ⚠️ Partial — await VILPOWER template approval + MSG91 TM chain + WP admin MSG91 fields + disable dev OTP
**Notes**: Sender is **RUDAAN** (not UDAANR from older proof PDF).

### 2026-07-05 — Forms accessibility master audit + top blocker fixes
**Requested by**: User (urgent — all form fields on all screens)
**What was done**: Code audit across Auth, Events registration, More, Library → `FORMS-AUDIT-MASTER.md`. Logged A11Y-001–009 in bugs-found. **Fix phase started:** phone field ExcludeSemantics + autofill normalize; password toggle moved outside excluded TextField in `UdaanLabeledField`; validation `announceValidationError` on Login, Register, Phone login.
**Status**: ⚠️ Partial — country picker focus trap, event registration announce, help contact still open
**Notes**: Re-test Login/Register on device for FIND-033/034/024.

**Requested by**: User — stop merging now-playing into GET /config; app fetches AzuraCast URL directly
**What was done**: WP plugin stores `now_playing_api_url` only; removed show title/subtitle from `live_radio` public payload. Flutter: AzuraCast model + provider with smart poll (15–90s, aligned to track `remaining`); Live tab hero from AzuraCast + WP fallback hero; upcoming card prefers `playing_next`; removed 30s full `/config` refresh on Radio tab.
**Files changed**: plugin admin/config/live-radio/azuracast class; Flutter azuracast provider/model, live_now_playing, radio_tab, remote_config, live_radio_config; tests
**Status**: ✅ Local complete — staging plugin **not deployed** yet
**Notes**: App uses default `https://stream.radioudaan.com/api/nowplaying` until staging serves `now_playing_api_url`.

### 2026-07-04 — Screen-by-screen device audit started (Screen 01 Bootstrap)
**Requested by**: User (Jordan workflow: code audit → device test → document findings only)
**What was done**: Created `device-audit/AUDIT-PROTOCOL.md` + `SCREEN-01-bootstrap.md` with full code walkthrough, 7 code findings, 13 device checkpoints. Updated Agent 16 for audit-only mode.
**Status**: ⏳ AWAITING human device results for Screen 01

### 2026-07-04 — Phase A accessibility KB integrity
**Requested by**: User (Phase A from Alex rating follow-up)
**What was done**: Created missing KB files (`release-checklist-flutter.md`, `accessibility-scanner.md`, `reference-apps.md`). Added `accessibility-kb/CHANGELOG.md`. Added `scripts/export-a11y-copy-snapshot.sh` + exported staging copy to `expected-copy-snapshot.json` (405 keys, 209 a11y). Updated Agent 16 operating model (human runs screen readers; agent coordinates). Updated README index, simulator, global subagent.
**Files changed**: `accessibility-kb/**`, `scripts/export-a11y-copy-snapshot.sh`, `agent-16-talkback-voiceover-tester.md`, `~/.cursor/agents/agent-16-*`
**Status**: ✅ Phase A complete — snapshot from staging curl 2026-07-04
**Notes**: Re-run snapshot after WP copy deploy: `bash scripts/export-a11y-copy-snapshot.sh`

### 2026-07-04 — Expert Accessibility KB + Agent 16 wiring
**Requested by**: User (@alex — full Flutter a11y KB structure: APIs, journeys, patterns, matrix, bug DB, simulator)
**What was done**: Created `.cursor/memory/accessibility-kb/` (12 sections): official index, WCAG, Flutter API ref, behavior matrix, widget encyclopedia (45+), Android TalkBack, Apple VoiceOver, UI patterns, Radio Udaan recipes, testing manual (25 scenarios), blind user journeys, screen reader simulator, bug database (20 issues), audit template, videos, research index, release checklist. Updated Agent 16 mandatory read list + global subagent. Legacy KB → redirect.
**Files changed**: `accessibility-kb/**`, `agent-16-talkback-voiceover-tester.md`, `talkback-voiceover-knowledge-base.md`, `~/.cursor/agents/agent-16-*`, `scripts/a11y-device-qa.md` (About tab fix)
**Status**: ✅ KB complete — **device quotes in 07-audits/apps/ still require human capture**
**Notes**: Widget encyclopedia target 100+; real app audits use template only until device sessions logged.

### 2026-07-04 — TalkBack/VoiceOver knowledge base + Agent 16
**Requested by**: User (@alex — professional screen-reader testing prompt, online-sourced KB, production agent)
**What was done**: Created `.cursor/memory/talkback-voiceover-knowledge-base.md` from official Flutter 3.44, Android Developers, and Apple accessibility docs (gestures, setup, ship criteria, WCAG refs, Radio Udaan screen matrix). Created `.cursor/agents/agent-16-talkback-voiceover-tester.md` (Jordan Lee / Agent 16) with no-assumption rules, step evidence template, ship blockers, bug format, session report. Updated agents README.
**Files changed**: `.cursor/memory/talkback-voiceover-knowledge-base.md`, `.cursor/agents/agent-16-talkback-voiceover-tester.md`, `.cursor/agents/README.md`
**Status**: ✅ Documentation complete — **device QA still requires human OTP + physical builds**
**Notes**: Invoke via `@agent-16-talkback-voiceover` or paste agent-16 file; pairs with `scripts/a11y-device-qa.md`. Global Cursor subagent registered at `~/.cursor/agents/agent-16-talkback-voiceover-tester.md`.

### 2026-07-03 — Live Radio: schedule gaps + volume slider a11y
**Requested by**: User (show hero during slot only; WP defaults between shows; volume swipe like slider)
**What was done**: WP schedule adds `ends_at` + `duration_minutes` (ACF `broadcast_duration_minutes`, default 60). `on_air` only inside slot. Config `live_radio` merges schedule when on-air, exposes `default_*` fields for gaps. Flutter `resolveLiveNowPlaying` uses schedule window + admin defaults; volume control: Semantics slider + vertical drag on track.
**Files changed**: `class-app-radio-schedule.php`, `class-app-config.php`, `live_now_playing.dart`, `live_radio_config.dart`, `radio_volume_control.dart`, `radio_schedule_provider.dart`, tests
**Status**: ✅ `php -l`, `dart analyze lib`, tests pass — **deploy plugin to staging** + rebuild app for device QA
**Notes**: Add ACF number field `broadcast_duration_minutes` on radio-shows if durations differ from 1 hour.

### 2026-07-03 — Push notifications: diagnose + professional delivery
**Requested by**: User (push not working; Zomato/Swiggy-quality; both platforms)
**What was done**: Root cause: **FCM not configured on staging** (admin created inbox only). WP: high-priority Android channel + APNs alert headers; admin shows push_sent/failed/fcm_skipped; `GET /health` adds `fcm_configured` + `push_devices_registered`. Flutter: iOS `aps-environment`, foreground presentation, APNS wait, tap→inbox, Settings re-enable button.
**Files changed**: `class-app-fcm-sender.php`, `class-app-notifications.php`, `class-admin-notifications.php`, `class-radioudaan-app-api.php`, `push_notification_service.dart`, `Runner.entitlements`, `settings_screen.dart`, `app_router.dart`
**Status**: ⚠️ Code ready — **operator must paste Firebase service account JSON on staging** + upload APNs key in Firebase for iOS; deploy plugin; rebuild app (build 26+)
**Notes**: User confirmed admin send symptom + FCM not configured. Chrome/web skips push by design.

**Requested by**: User (@alex — remove manual featured picker; 5 latest playlists by newest video)
**What was done**: WP `get_featured_playlists()` ranks playlists by newest video `published_at`; excludes empty + uploads playlist. Removed admin picker UI/AJAX/option. Flutter unchanged.
**Files changed**: `class-app-youtube-library.php`, admin settings/hub/pages/assets, `admin-settings.js`
**Status**: ✅ `php -l` pass; deploy plugin to staging
**Notes**: Cache key `ru_yt_feat_latest_5`, TTL 1h.

### 2026-06-13 — Page-by-page double-speech audit + fixes
**Requested by**: User (@alex — team check each page)
**What was done**: Static audit across all screens (`scripts/a11y-double-speech-audit.md`). Fixed all FAIL items: tab switch announce removed; library search hint vs heading; auth screens deduped app name; OTP pin row + UdaanLabeledField TextField excluded; splash single liveRegion; forgot-password channel chips; verify-email labels; settings slider; change-password fields; donate QR + copy announce; event registration announces + upload progress; library player/saved tiles.
**Files changed**: 20+ files under `radio_udaan_app/lib/`; `scripts/a11y-double-speech-audit.md`
**Status**: ✅ `dart analyze lib` exit 0; **device QA still pending** (`A11Y-QA`)
**Notes**: REVIEW rows (favorites announce, spinners, legal h1, country picker favorites) need TalkBack/VoiceOver spot-check on device.

### 2026-06-13 — Blind-user navigation a11y (phased plan)
**Requested by**: User (implement VoiceOver/TalkBack navigation plan)
**What was done**: Phases 0–5: shared `udaan_semantics.dart` toolkit; tab announcements + screen header landmarks; radio hero merge + schedule modal; flattened event/library cards; registration event context banner + page announcements; YouTube native-only controls + Open in YouTube; modal sheets (schedule, country picker); HTML heading landmarks; deep link announce; SnackBar→`announceAndSnack` sweep. Device QA script: `scripts/a11y-device-qa.md`.
**Files changed**: `lib/core/accessibility/udaan_semantics.dart`, `main_shell_screen.dart`, `brand_app_bar.dart`, `radio_tab.dart`, `radio_schedule_sheet.dart`, `event_card.dart`, `event_context_banner.dart`, `event_registration_screen.dart`, `library_video_card.dart`, `library_player_screen.dart`, `accessible_country_picker_sheet.dart`, `accessible_html_content.dart`, `external_link.dart`, `event_deep_link.dart`, about contact/donate screens
**Status**: ✅ `dart analyze lib` exit 0; **device QA pending** (see `scripts/a11y-device-qa.md`)
**Notes**: YouTube `showControls: false` — sighted users use native Play/Pause row below embed. Deploy staging APK/IPA before Elena/Jordan sign-off.

### 2026-06-27 — Blind-user a11y: VoiceOver keyboard + double-speech fixes
**Requested by**: User (fix audit gaps; TestFlight path)
**What was done**: Global keyboard dismiss; ExcludeSemantics across auth/registration/library/radio/more; accessible country picker; native library video controls; AccessibleHtmlContent; liveRegion labels; build 2.0.0+20. Branch `cursor/a11y-voiceover-keyboard-fixes-1ab5`, PR #4.
**Files changed**: 50+ Flutter files under `radio_udaan_app/lib/`
**Status**: ✅ `dart analyze` PASS (0 errors); staging smoke 14/14; **not merged to main**; device VoiceOver QA pending
**Notes**: Merge PR → GitHub Actions Build iOS IPA → TestFlight. YouTube WebView controls still inaccessible (native row below).

**Requested by**: User (100% validation, conditions, file types — WP-driven future forms)
**What was done**: Schema v2 (`supported_field_types_version: 2`): `choice_options`, address/name `subfields`, `info` HTML blocks, `consent_html`, `page_index`, `form_warnings`, `app_submittable`. Full visibility operators (date/day/month/n-days). Server `class-form-field-validator.php`. Per-field upload limits. Multi-file upload. Flutter: pagination, blocking banners, subfields, slider/rating, info HTML, client validation, multi-upload.
**Files changed**: `class-form-field-validator.php`, `class-form-visibility.php`, `class-form-schema-builder.php`, `class-registration-handler.php`, `class-app-uploads.php`, `form_schema.dart`, `form_visibility.dart`, `form_field_validator.dart`, `event_registration_screen.dart`, `registration_draft_storage.dart`
**Status**: 🟡 `dart analyze` + `php -l` + `verify-wp-plugin.sh` pass; hot restart + plugin deploy to staging
**Notes**: Cannot support Stripe/PayPal/CAPTCHA in-app (blocks submit). Signature still unsupported. Sync local Forminator conditions from staging for OMM.

**Requested by**: User (go with B)
**What was done**: WP `class-app-legal-pages.php` — page pickers in Settings → Legal, Elementor-aware body HTML in `GET /config` → `legal_pages`. Flutter `LegalContentScreen` with `flutter_widget_from_html`; removed WebView legal screen.
**Files changed**: `class-app-legal-pages.php`, `class-app-config.php`, admin settings/hub/pages, `legal_pages_config.dart`, `legal_content_screen.dart`, `more_tab.dart`, `remote_config.dart`, `wp_media_url.dart`
**Status**: ✅ Local `/config` returns privacy HTML (page 3); `dart analyze` pass
**Notes**: Pick Terms/About pages in wp-admin or rely on URL auto-resolve; upload plugin to staging; hot restart app to refresh config cache.

### 2026-06-13 — P3 sprint: deploy zip, QA automation, iOS links, MSG91 gate
**Requested by**: User (continue in order, full AI agents team)
**Agents**: shell (package-staging-plugin + staging-qa-automated) + Flutter/iOS (Universal Links entitlements) + WP (India OTP fail-loud) + docs (ios-push-setup.md)
**What was done**: `dist/radioudaan-app-api-staging.zip` packager. Extended QA script (events all + auth_policy). iOS `Runner.entitlements` + URL scheme. MSG91 non-+91 returns 400 with clear message. `scripts/apple-app-site-association.template.json` for HTTPS universal links.
**Status**: ✅ dart analyze + staging-qa-automated PASS (staging API; new plugin bits need zip upload)
**Notes**: Upload zip to staging; GitHub APK still manual; AASA file needs Team ID on server.

### 2026-06-13 — P2 sprint: deep links, live_radio cache, deploy scripts, MSG91 audit
**Requested by**: User (continue in order, full AI agents team)
**Agents**: WP (BUG-013 cache) + Flutter (event deep links) + shell (post-deploy verify + load plan) + explore (MSG91 intl)
**What was done**: Separate 60s transient for `live_radio`. Route `/event/:eventId` + Android intent filters + pending link through login. `scripts/staging-post-deploy-verify.sh`, `scripts/load-test-registration-plan.sh`. `.cursor/memory/msg91-international.md`. Staging post-deploy **OVERALL PASS**.
**Status**: ✅ dart analyze + staging verify pass; APK workflow needs manual trigger (gh not auth locally)
**Notes**: Deploy plugin folder to staging for email dedupe + cache fix. Test deep link: `adb shell am start -a android.intent.action.VIEW -d "radioudaan://event/1318" com.radioudaan.radio_udaan_app`

**Requested by**: User (continue in order with full AI agents team)
**Agents**: Coordinator → WP (email dedupe) + Flutter (closed events) + Flutter (Crashlytics) + shell verify
**What was done**: Fixed `staging-api-smoke.sh` (`privacy_policy_url` top-level). Staging gate **14/14 PASS**. Per-event `ru_allow_multiple_registrations` + email duplicate guard (`_radioudaan_email`). Events tab shows closed events disabled. Firebase Crashlytics wired in `main.dart`. OTP Contact Support → in-app Help (prior). Admin label updated to email per event.
**Status**: ✅ `dart analyze lib` + `php -l` + staging smoke exit 0 locally
**Notes**: Deploy plugin to staging for dedupe meta. Crashlytics needs **release** build to upload. Manual device QA checklist below still required.

**Requested by**: User (automate everything via messaging)
**What was done**: Pushed `AGENTS.md`, `CLOUD_OPERATIONS.md`, `.cursor/environment.json`, `ci-analyze.yml`, and version-controlled `.cursor/rules|memory|agents` to `main`. GitHub already connected as Romil149. Created cloud environment for `Romil149/Radio-Udan` and started dashboard setup agent (~20 min). Updated `.gitignore` to allow team `.cursor` config.
**Files changed**: `AGENTS.md`, `CLOUD_OPERATIONS.md`, `.cursor/environment.json`, `.github/workflows/ci-analyze.yml`, `.gitignore`, `.cursor/**`
**Status**: ⚠️ Partial — Slack connected (Nexusfleck); branch default=`main` set; environment still Unconfigured until user clicks Save on setup agent
**Notes**: Invite `/invite @cursor` in Slack channel. Test: `@cursor Read AGENTS.md. Run dart analyze lib`. See CLOUD_OPERATIONS.md Part B Option 3.

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

### 2026-07-05 — AzuraCast now playing on Live tab
**Requested by**: User
**What was done**: WP plugin polls `https://stream.radioudaan.com/api/nowplaying/1` every 30s; merges song title, artist, album art into `GET /config` → `live_radio`. Removed admin show title/subtitle fields. Flutter hero uses AzuraCast always (before + during play); ICY still overrides while playing. Radio tab refreshes config every 30s.
**Files changed**: `class-app-azuracast-now-playing.php`, `class-app-config.php`, `class-app-live-radio.php`, admin settings, `live_radio_config.dart`, `live_now_playing.dart`, `radio_tab.dart`, tests
**Status**: ✅ Complete locally — **deploy plugin to staging** required for live API
**Notes**: Fallback hero image in WP admin when stream has no album art. Schedule kept for favorites/upcoming only.

### 2026-07-08 — Force App Update (Minimum Build, WP-driven)
**Requested by**: User
**Agents involved**: Manager → Planner → Developer (WP + Flutter) → QA gate (verification scripts)
**What was done**:
- **WP (App API)**: Added `app_update` slice in `GET /config` (`enabled`, `android_min_build`, `ios_min_build`) via `RadioUdaan_App_Version_Policy`; wired to WP Admin “App update policy” card + save handlers; added copy catalog keys `force_update_*`.
- **Flutter**: Added `AppUpdatePolicy` parsing in `RemoteConfig`, `package_info_plus` build detection in `AppBootstrap`, a `ForceUpdateGate` helper, and a hard-block `/force-update` screen with accessible semantics.
**Files changed**: WP config/admin/settings/copy catalog + `scripts/staging-api-smoke.sh`; Flutter `remote_config.dart`, `app_providers.dart`, `app_bootstrap.dart`, router/bootstrap + `force_update_gate.dart` and `force_update_screen.dart`.
**Status**: ⚠️ Partial — local verification passed; staging API smoke failed because `/config.app_update.enabled` was missing (staging plugin redeploy required).
**Notes**: Re-run `bash scripts/staging-api-smoke.sh` after uploading the full packaged plugin zip to staging.
