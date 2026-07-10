# Architecture Decisions Log
<!-- When a design choice is made, document it here so we don't re-debate it. -->

### 2026-07-10 — iOS push: classic AppDelegate (no UIScene)
**Context**: Permission authorized but `getAPNSToken` stayed nil under `FlutterImplicitEngineDelegate` + SceneDelegate; AppDelegate APNs handoff alone (+44/+46) insufficient.
**Decision**: Remove `UIApplicationSceneManifest`; use classic `FlutterAppDelegate` with `FirebaseApp.configure()`, `registerForRemoteNotifications`, and cached `Messaging.apnsToken`. Dart re-requests notification permission on iOS even when already authorized.
**Reasoning**: Known FlutterFire break with UIScene/implicit engine; classic lifecycle restores APNs → FCM token path.
**Consequences**: Do not re-add UIScene for iOS until FlutterFire documents a working APNs path; SceneDelegate.swift may remain in the Xcode project unused.

### 2026-07-10 — FCM project must match Flutter Firebase project
**Context**: Staging had FCM configured (`fcm_configured: true`) on project `radio-udaan-cbfdc` while the app uses `radio-udaan-72232`; zero devices registered; admin “send” only created inbox rows.
**Decision**: Lock expected client project as `RadioUdaan_App_Fcm_Sender::EXPECTED_APP_PROJECT_ID = radio-udaan-72232`. Expose `fcm_project_matches_app` on `GET /health`; warn in admin Send + Settings when mismatched.
**Reasoning**: FCM HTTP v1 tokens are project-scoped; cross-project sends fail/prune. Operators need a non-secret signal.
**Consequences**: Changing the app Firebase project requires updating the PHP constant + client configs together.

### 2026-07-10 — About Us content via info_hub (like Donate)
**Context**: About Us used Legal URLs → WP page HTML (`legal_pages.about`). User wants plugin fields editable like Donate.
**Decision**: Structured `info_hub.about` (badge, headline, intro, body, accessibility_note, image). Admin: Settings → About tab. Remove Legal “About page” picker and omit `legal_pages.about` from GET `/config`. Keep public `about_url` for stores/web. App Copy keeps tile labels only.
**Consequences**: Staging needs plugin deploy before content appears; empty fields until admin fills them.

### 2026-07-10 — What's New: latestcommunitynews instead of in-news
**Context**: About What's New was merging `whats-new` + `radio-udaan-in-news`. User wants `whats-new` + `latestcommunitynews` only.
**Decision**: Feed and push use those two CPTs; API type `latestcommunitynews`; detail HTML body like announcements; remove in-news from feed/routes.
**Consequences**: Staging needs App API plugin deploy. Old in-news posts no longer appear in app What's New.

### 2026-07-10 — Event registration: prefill name/email/phone, do not lock
**Context**: Account name/email/phone were prefilled and read-only with lock icon (“cannot edit”). User wants prefill but editable.
**Decision**: Keep `_applyAccountDefaults` / `accountValueForField` prefill when empty; remove registration lock (`readOnly`, lock icon, `registration_account_locked_hint`). Profile email/mobile lock elsewhere unchanged.
**Reasoning**: Registrants may correct typos or use a different contact for an event without changing account settings.
**Consequences**: Submitted values may differ from account profile; WP/Forminator receives edited values as entered.

### 2026-06-13 — Library featured playlists: auto top-5 (no admin picker)
**Context**: Admin manually picked featured playlists; user wanted latest activity surfaced automatically.
**Decision**: `GET /library/youtube/playlists/featured` returns **5 playlists** ranked by **newest video `published_at`** inside each playlist (first playlist item = newest). Exclude empty playlists and channel uploads playlist. No WP admin selection UI.
**Reasoning**: Reduces admin work; playlists with recent uploads surface naturally. App “View all” unchanged.
**Consequences**: More YouTube API calls on cache miss (one `playlistItems` per candidate + batch `videos`). Cached 1 hour; invalidated when API key/channel changes.

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

### 2026-07-08 — Razorpay donations: Android native SDK, iOS payment link
**Context**: In-app donations via Razorpay with 80G receipts; Apple Guideline 3.1.1 restricts in-app purchase of digital goods — charitable donations to a registered trust are generally exempt, but embedding third-party checkout in WebView on iOS is risky.
**Options Considered**: (1) WebView Razorpay on both platforms; (2) native SDK both; (3) native Android + Payment Link (Safari) on iOS.
**Decision**: **Android** uses `razorpay_flutter` native checkout; **iOS** opens Razorpay **Payment Link** in external browser, then user taps “I completed payment” → `POST /donate/verify`. Orders created server-side; secrets only in WP admin.
**Reasoning**: Matches plan legal review; avoids iOS WebView/store friction; webhook + verify endpoint cover Safari return without mandatory deep link in v1.
**Consequences**: iOS UX is two-step (browser + verify button). WP must be deployed with webhook URL in Razorpay dashboard. 80G PDF emailed from WP when toggles + donor opt-in + email present.

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

### 2026-06-25 — 100% WP-driven app copy + fast cold start
**Context**: Product owner requires all user-visible strings editable from WordPress plugin without app updates; cold start must stay fast.
**Decision**: Full copy catalog in `GET /config` → `copy` (map keyed by snake_case). Flutter `AppCopy.fromJson` merges WP overrides over `appCopyDefaults` (offline fallbacks). UI reads `appCopyProvider` only; `AppStrings` is compile-time fallback catalog, not shown when config is loaded. WP admin Settings → App copy uses `RadioUdaan_App_Copy_Catalog::groups()` for all fields.
**Reasoning**: Single `/config` fetch (cached 5 min WP + 6 h device) avoids extra round-trips; stale-while-revalidate shows branded UI immediately.
**Consequences**: Admin has many copy fields (grouped). Template strings use `{placeholders}` in copy values. App rebuild not needed for text changes.

### 2026-07-09 — Always best employee on the task (hire if missing)
**Context**: User (@alex) mandated that every task go to the best specialist; if no worker fits the role, hire a new employee with the best skills required.
**Decision**: Coordinator always routes to the best roster specialist for the domain. If the roster/Task types lack a fit, create/extend a specialist agent (skills + brief) before assigning work. Never default to a weak generalist for critical work. Documented in `.cursor/rules/specialist-agents.mdc`.
**Reasoning**: Radio Udaan quality (especially a11y) requires domain experts; wrong assignee wastes cycles and ships gaps.
**Consequences**: Alex must pick named best fit (Maya/Daniel/Jordan/Marcus/Elena/Ravi/etc.) or hire; Task prompts stay “Senior [domain] 20+ years”; parent still verifies.

### 2026-07-08 — Force App Update (minimum build gate)
**Context**: Prevent API-breaking changes and security fixes from being used on older app builds.
**Decision**: WordPress exposes `GET /config.app_update` with enabled + min Android/iOS build numbers. Flutter compares `package_info_plus.buildNumber` against the platform minimum and hard-blocks the app via `/force-update` when violated (with accessible copy and official store links).
**Reasoning**: Store-compliant approach (official store listing + minimum-version enforcement only). Hard-block avoids broken/unsafe API behavior while still being controllable from WP admin.
**Consequences**: Staging WP deployment must include the `app_update` config slice before QA. Admin must raise minimum builds only after the new build is live on the relevant store.

## Template:
### [Date] — [Decision Title]
**Context**: Why was this decision needed?
**Options Considered**: What were the alternatives?
**Decision**: What we chose
**Reasoning**: Why this option over others
**Consequences**: What this means for future work
