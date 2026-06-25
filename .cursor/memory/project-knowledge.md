# Project Knowledge Base
<!-- Updated by ALL agents. Add things you learn that future sessions need to know. -->

## Tech Stack
- **Mobile**: Flutter (Android + iOS)
- **Backend/Admin**: WordPress + Forminator (free) + custom WP plugin (“App API”)
- **Auth**: OTP (India), provider abstraction (MSG91 default; switchable)
- **Forms**: Server-driven dynamic schemas derived from Forminator

## Gotchas & Traps
- **WP admin UI (June 2026)**: Radio Udaan App plugin admin uses a **unified orange theme** (`#ff6b00`, aligned with site branding) and **tabbed navigation on every plugin page** (Settings, Events, Form Migration, etc.). New admin screens should reuse the same tabbed layout and styles — do not introduce one-off WP default styling on a single page.
- **Non-negotiable**: all event registrations happen **inside the app** (not web forms).
- **Non-negotiable**: **one Forminator form per event** (strict 1:1 mapping).
- Dynamic forms must evolve without forcing frequent app updates (contract stability matters).
- OTP testing requires human-provided test numbers/codes; never assume.

## Live radio schedule (`radio-shows` CPT)
- **API**: `GET /library/schedule?days=2` — expands ACF `broadcasting_day` + `broadcast_time` and repeat fields into `on_air`, `next`, and `days[].items`.
- **Not a separate stream URL** — schedule drives hero copy + upcoming UI only; playback stays `live_radio.stream_url` (MP3).
- **Flutter**: `radioScheduleProvider` in `radio_schedule_sheet.dart`; favorites are **local-only** (`shared_preferences`, key `radio_favorite_show_ids`).
- **ACF day fields** are often arrays (e.g. `["Friday"]`); theme home shortcode filters with meta_query LIKE.

## RJ profiles (users, not CPT)
- **Source of truth**: WordPress users with role **`rj`** — plugin class `RadioUdaan_Rj_Profile` (`class-rj-profile.php`).
- **Public URLs**: `/rj-profiles/` (archive), `/rj-profiles/{user-nicename}/` (single) — `user_nicename` copied from legacy CPT `post_name` on migration.
- **Profile fields**: user meta prefix `radioudaan_rj_*` + WP `display_name` + `description` (bio). Future app link: `radioudaan_rj_linked_app_user_id`.
- **Shows**: assign RJ user(s) on **`radio-shows` → ACF `program_host`** (User field). Profile “hosted shows” derived by reverse lookup — no `hosted_shows` on user.
- **Migration**: Radio Udaan App → Advanced tools → **Migrate RJ profiles to users**; then delete `rj-profiles` in CPT UI + save Permalinks.
- **RJ admin**: login → `profile.php`; Media Library allowed; minimal admin menu in theme `functions.php`.

## Patterns to Follow
- **Primary audience**: blind and low-vision users — see `.cursor/rules/accessibility-blind-users.mdc` (56px targets, persistent labels, Semantics + liveRegion, no icon-only controls).
- **100% WP-driven copy (non-negotiable)**: All user-visible strings come from `GET /config` → `copy` map + `branding`. Flutter `appCopyProvider` / `AppCopy` accessors in UI; `AppStrings` + `app_copy_defaults.dart` are offline fallbacks only. WP admin: Settings → App copy (full `RadioUdaan_App_Copy_Catalog`).
- **Fast cold start (non-negotiable)**: Never block first frame on network. `ConfigCacheStorage` stale-while-revalidate; single `/config` fetch (parallel with `/auth/me` when logged in); WP transient cache 5 min. No extra startup API calls for copy.
- **Live radio background**: `audio_service` + `just_audio` — `RadioAudioHandler` in `lib/features/radio/`, init in `main.dart`; Android FGS `mediaPlayback` + notification play/pause; iOS `UIBackgroundModes` → `audio`.
- Write acceptance criteria as **pass/fail** checks.
- Accessibility-first: TalkBack + VoiceOver requirements per screen/flow.
- “No assumptions”: ask the human to confirm ambiguous requirements.
- **Production code style**: see `.cursor/rules/coding-standards.mdc` — user strings in `app_strings.dart`, errors via `parseApiError()`, dev-only UI in `kDebugMode`.

## Patterns to AVOID
- Hardcoding event forms or upload constraints in the app.
- Leaking PII in logs (phone/email/uploads).
- Introducing paid plugins/vendors without explicit approval.
- Using **`nexusfle_radio.sql`** (or any static dump) as source of truth — it is an **old archive**. Use the **live DB** wired in `radio-udan-wordpresss-website/wp-config.php` (`DB_NAME` = `radio` locally).

## Key Files to Know
- `.cursor/agents/*` — copy/paste prompts for specialized agents

## Form migration (website)
All three header registration pages migrated to Forminator on local `radio` DB (2026-06-03):
| Event | Page ID | Forminator ID | URL slug |
|-------|---------|---------------|----------|
| Udaan Idol | 825 | 1207 | `registration-udaan-idol` |
| One Minute Matters | 1116 | 1208 | `radio-udaan-one-minute-matters-...` |
| Become RJ | 1178 | 1209 | `become-rj` |

- Migration admin: **Tools → RU Form Migration** (`tools.php?page=radioudaan-form-migration`) — reads live DB status per row.
- Options: `radioudaan_forminator_{event_code}` → form ID.

## Gate A (locked 2026-06-03)
- **v1 = full MVP**: Live Radio + YouTube/Library + Events/registration + More/Profile; accessibility-first; no feature deferred to “Phase 2” for app tabs.

## Store compliance (Apple + Google Play)
- **Always read** `.cursor/memory/store-compliance.md` before Flutter features and before release.
- **OTP**: manual entry only — **never** `READ_SMS` on Android.
- **Sign in with Apple**: not required (own phone OTP login).
- **Required before submit**: in-app Privacy Policy link, account deletion, Data safety / App Privacy labels, demo account for review, YouTube embed (no download), background audio for radio, TalkBack/VoiceOver pass.

## Environment Notes
- **Workspace root**: `/Users/nexus/Documents/Radio Udan` (not Downloads).
- **Live database (source of truth)**: MySQL database **`radio`** per `wp-config.php` (`DB_HOST` localhost, table prefix `wp_`). Agents can verify via WP APIs, **Tools → RU Form Migration** (live Elementor status), or PHP PDO — not via `nexusfle_radio.sql`.
- **Local dev site**: `https://radio/` (WordPress 7.0, admin logged in during agent sessions).
- **REST API**: `/wp-json/` works after permalinks saved (`.htaccess` rewrite rules generated).
- **Forminator**: active; at least one form (id **973**, 0 submissions as of 2026-06-03).
- **Udaan Idol registration page**: `https://radio/register/registration-udaan-idol/` — **Forminator form 1207** on web (app API schema not wired yet).
- **`radioudaan-app-api` plugin**: v0.9.0 at `wp-content/plugins/radioudaan-app-api/`; REST includes `/config` (**branding** + **copy** + stream/legal URLs), `/auth/me`, `/auth/logout`, rate limits, closed-event checks, schema `sections[]` + `unsupported_fields[]`, admin CSV export. Event ID = `ru_event` CPT id. **App branding**: WP Admin → Radio Udaan App → **Settings** → “App branding & appearance” (logo, colors, tab labels, splash copy). Defaults match website orange `#ff6b00`. Local dev: enable **Development OTP** in Settings (or `RADIOUDAAN_APP_API_DEV_OTP`) for OTP `123456`.
- **Flutter app branding**: `RemoteConfig.branding` / `RemoteConfig.copy` / `RemoteConfig.liveRadio` → `appBrandingProvider` / `appCopyProvider` / `liveRadioProvider`. Live tab (show title, hero image, WhatsApp/schedule/share) editable in WP **Settings → Live radio**; exposed as `GET /config` → `live_radio`.
- **Specialist agents**: `.cursor/rules/specialist-agents.mdc` — delegate non-trivial work to parallel Task sub-agents (senior-expert framing).
- **WP admin gotcha**: `copy_option_map` must use exact constant names (e.g. `OPTION_COPY_TAB_EVENTS`, not `OPTION_COPY_EVENTS`) or Settings page fatals.
- **Performance**: WP `GET /config` transient cache 5 min + `Cache-Control`; Flutter `ConfigCacheStorage` stale-while-revalidate; parallel `/config` + `/auth/me`; `cached_network_image` for logo; `RepaintBoundary` on tabs. See `.cursor/rules/performance.mdc`.
- OTP provider keys and app signing keys must never be committed.
- **FCM push (server)**: WordPress uses **FCM HTTP v1** via `class-app-fcm-sender.php` — Firebase **service account JSON** + OAuth2 (not legacy server key). Admin: Settings → Notifications → paste JSON; optional `RADIOUDAAN_FCM_SERVICE_ACCOUNT_JSON` or `_PATH` in `wp-config.php`. Sends on `RadioUdaan_App_Notifications::create()` when configured; respects per-user notification prefs by type.

