# Bug Tracker
<!-- Every bug found by any agent goes here. Update status as bugs get fixed. -->

## Open Bugs

| ID | Severity | File | Description | Found By | Status |
|----|----|---|----|----|-----|
| BUG-009 | 🔴 Critical | `app_bootstrap.dart` | Cold start assumed `phoneVerified: true`; network errors kept zombie bearer tokens | Multi-agent audit | Fixed |
| BUG-010 | 🔴 Critical | `api_client.dart` / auth screens | No global 401 handling; email verify dead-end without bearer token | Multi-agent audit | Fixed |
| BUG-011 | 🔴 Critical | `class-app-password-auth.php` | Phone squatting via unauthenticated `POST /auth/register` (no OTP proof) | Multi-agent audit | Partial (rate limit + stale pending purge; OTP-first still recommended) |
| BUG-012 | 🔴 Critical | `class-app-settings.php` | Dev auth/OTP bypass could be enabled on production via admin checkbox | Multi-agent audit | Fixed (production env guard) |
| BUG-014 | 🟠 High | `class-rate-limiter.php` | Rate limits trusted spoofable `X-Forwarded-For` | Multi-agent audit | Fixed (REMOTE_ADDR default; proxy opt-in) |
| BUG-006 | 🔴 Critical | `radio_player_controller.dart` / `MainActivity.kt` | Live radio failed on Android — `AudioService.init` failed because `MainActivity` did not extend `AudioServiceActivity` | User report | Fixed: `AudioServiceActivity` + init retry + just_audio fallback |
| BUG-007 | 🟡 Medium | Staging WP YouTube settings | Library playlists/videos return 503 `youtube_not_configured` — no API key on staging | User report | Fixed (WP admin key added) |
| BUG-008 | 🔴 Critical | `library_player_screen.dart` | YouTube embed “Video unavailable” (error 15/153) on all videos in mobile WebView; endless loader | User report | Fixed: `origin: youtube-nocookie.com`; load after scaffold init; 15s timeout; Retry only (no external YouTube) |
| BUG-004 | 🟢 Low | `go_router` | Direct URL `#/events` fails (`no routes for location: /events`); tabs are shell-only (`/`). | Agent 12 | Open (by design) |
| BUG-017 | 🔴 Critical | `assets/images/radio_udaan_logo.png` | Logo asset declared in pubspec but missing from repo — `Image.asset` on splash/auth crashes cold start (iOS + Android) | User report | Fixed (asset added + OfflineBrandLogo fallback) |
| BUG-001 | 🟡 Medium | `.cursor/agents/README.md` | README referenced non-existent `agent-03-wp-app-api.md` (fixed) | Developer | Closed |
| BUG-019 | 🔴 Critical | Staging WP + `Runner.entitlements` + admin notifications | Push “sent” from WP admin but phones get nothing — FCM service account not on staging; iOS missing `aps-environment`; admin only reported inbox created | User report | Partial: repo fixed (payload, stats, entitlements, client). **Still open on staging:** FCM project `radio-udaan-cbfdc` ≠ app `radio-udaan-72232`; `push_devices_registered: 0` |
| BUG-023 | 🔴 Critical | Staging FCM + Flutter Firebase | WP FCM HTTP v1 project (`radio-udaan-cbfdc`) does not match app Firebase project (`radio-udaan-72232`) — tokens from app cannot be delivered by staging sender | Push audit 2026-07-10 | Open — operator must paste SA JSON from `radio-udaan-72232`; admin/health now warn on mismatch |
| BUG-024 | 🔴 Critical | Android Crashlytics Gradle / ProGuard | `Firebase.initializeApp` fails: `FirebaseCrashlytics component is not present` (Razorpay stack) — Crashlytics plugin missing + R8 strip | User +44 diagnostics | Fixed in **2.0.0+45** — apply Crashlytics Gradle plugin + keep Firebase in ProGuard |
| BUG-021 | 🔴 Critical | `library_player_screen.dart` | YouTube plays but loader stuck + play/pause UI wrong — iframe `unknown`/`cued` flipped `_isPlaying` false | User report | Fixed (Option A) — optimistic ~1s spinner clear; Play/Pause = user intent; soft iframe confirm + 15s error; ignore unknown/cued/unStarted |
| BUG-022 | 🔴 Critical | `class-admin-settings-tests.php` | Settings Save did nothing — nested Test FCM/MSG91 `<form>` closed main settings form early; Save button outside form | User report | Fixed — deferred standalone test forms + `form=` attribute on buttons |
| A11Y-001 | 🔴 Critical | `udaan_phone_field.dart` | National TextField missing ExcludeSemantics — double VoiceOver stop (FIND-033) | Forms audit 2026-07-05 | Fixed @ ab2cffe |
| A11Y-002 | 🔴 Critical | `udaan_auth_widgets.dart` | Password show/hide inside excluded TextField — unreachable (FIND-034) | Forms audit 2026-07-05 | Fixed @ ab2cffe |
| A11Y-003 | 🔴 Critical | Auth + More screens | Validation errors liveRegion only — no sendAnnouncement (FIND-024) | Forms audit 2026-07-05 | Fixed @ ab2cffe |
| A11Y-004 | 🔴 Critical | `udaan_phone_field.dart` | Autofill double country code (FIND-032) | Forms audit 2026-07-05 | Fixed @ ab2cffe |
| A11Y-005 | 🔴 Critical | `accessible_country_picker_sheet.dart` | Focus leak to content behind modal (FIND-035/036) | Forms audit 2026-07-05 | Fixed @ ab2cffe |
| A11Y-006 | 🔴 Critical | `event_registration_screen.dart` | Validation fail does not announce; info HTML excluded (ERG-REG-VAL-001, ERG-REG-INFO-001) | Forms audit 2026-07-05 | Fixed @ ab2cffe |
| A11Y-007 | 🟠 High | `help_contact_screen.dart` | TextField without ExcludeSemantics — duplicate speech (A11Y-MORE-001) | Forms audit 2026-07-05 | Fixed @ ab2cffe |
| A11Y-008 | 🟠 High | `verify_email_screen.dart` | Sent-to email in ExcludeSemantics (FIND-045) | Forms audit 2026-07-05 | Fixed @ ab2cffe |
| A11Y-009 | 🟠 High | `event_registration_screen.dart` | Page navigation not announced (ERG-REG-PAGE-001) | Forms audit 2026-07-05 | Fixed @ ab2cffe |

## Fixed Bugs

| ID | Severity | File | Description | Fixed By | Fix Description |
|----|----|---|----|----|-----|
| BUG-002 | 🔴 Critical | `includes/admin/class-admin-pages.php` | Settings page fatal: undefined constant `OPTION_COPY_EVENTS` (should be `OPTION_COPY_TAB_EVENTS`) | Coordinator | Corrected `copy_option_map` entry for Tab: Events |
| BUG-001 | 🟡 Medium | `.cursor/agents/README.md` | Broken agent filename reference | Developer | Updated to `agent-03-wp-app-api-engineer.md` |
| BUG-013 | 🟠 High | `class-app-config.php` | GET `/config` rebuilds `live_radio` on every cache hit | Multi-agent audit | Separate 60s transient for `live_radio`; removed from main 300s blob; `invalidate_cache()` clears both |
| BUG-015 | 🔴 Critical | `admin-settings.js` / `class-admin-app-hub.php` | Tabbed settings save omitted inactive-tab fields (`display:none` / `hidden`); checkboxes reset; YouTube playlists wiped; invalid FCM JSON blocked entire save | User report | Fixed: reveal all panels on submit; preserve playlists when absent from POST; FCM error redirect; register `admin_post` in bootstrap |
| BUG-016 | 🔴 Critical | `class-app-settings.php` | Dev OTP admin save appeared broken — `wp_get_environment_type()` defaults to `production`, blocking dev OTP on staging; checkbox showed effective state not stored option | User report | Fixed: lock dev bypass only on `radioudaan.com` hosts; admin shows wp-config lock + active status |
| BUG-022 | 🔴 Critical | `class-admin-settings-tests.php` | Settings Save did nothing — nested FCM/MSG91 `<form>` inside main settings form; HTML parser closed outer form early, orphaning Save button | User report | Fixed: deferred standalone test forms + `form=` attribute on buttons; search-hidden fields revealed on submit |
| BUG-018 | 🔴 Critical | `radioudaan-app-api.php` | `class-app-copy-catalog.php` not required — wp-admin fatal `Class RadioUdaan_App_Copy_Catalog not found` | User report | Added `require_once` before `class-app-branding.php`; `scripts/verify-wp-plugin.sh` catches missing requires |

