# WordPress App API Plugin — Line-by-Line Code Audit

This document contains a comprehensive, line-by-line and component-level code audit of the **Radio Udaan WordPress App API** plugin (`radioudaan-app-api`). It serves as the single source of truth for the plugin structure, database interactions, hooks, rate limiters, REST API endpoints, private upload protections, and administrative controllers.

---

## Part 1: Entry Bootstrapper

### `radioudaan-app-api.php`
- **Purpose:** Core plugin bootstrapper, constant declarations, activation hook mappings, and service initialization.
- **Hooks & Actions:**
  - `plugins_loaded` (priority 10) -> `radioudaan_app_api_init()`: Bootstraps services, custom tables, and hooks.
  - `init` (priority 25) -> `radioudaan_app_api_maybe_sync_events()`: Auto-syncs definitions to `ru_event` CPT when `radioudaan_ru_events_sync_version` does not match the active plugin version (`1.0.0`).
  - `register_activation_hook` -> Initializes custom SQL schemas (`wp_ru_app_users` table), registers CPT, creates FCM tables, registers RJ roles, setups public rewrite rules, and flushes rules.
- **Imports:** Loads all 38 include files under `includes/`.

---

## Part 2: Core Utilities & Helpers (`includes/`)

### `includes/class-rate-limiter.php`
- **Purpose:** IP and phone-based rate limiting using WordPress transient APIs.
- **Key Methods:**
  - `is_limited( $key, $limit, $window )`: Checks if a custom transient count exceeds the limit.
  - `bump( $key, $window )`: Bumps the current request count.
  - `get_client_ip()`: Resolves remote IP, checking standard proxy headers (`HTTP_CLIENT_IP`, `HTTP_X_FORWARDED_FOR`, `REMOTE_ADDR`).

### `includes/class-app-logger.php`
- **Purpose:** Secure, PII-compliant logging interface that avoids writing sensitive user data (passwords, OTPs, full phone numbers) to disk.
- **Key Methods:**
  - `log( $action, array $context )`: Sanitizes contexts and records logs under `/wp-content/uploads/radioudaan-app-logs/`.
  - `mask_value( $key, $value )`: Checks fields containing "phone", "otp", "token", "fcm_token" and redacts them using suffix masks (`****1234`).

### `includes/class-app-cors.php`
- **Purpose:** Intercepts REST request contexts to inject CORS headers, supporting Flutter Web clients in development.
- **Hooks & Actions:**
  - `rest_pre_serve_request` -> Adds headers: `Access-Control-Allow-Origin: *` (dev only when `RADIOUDAAN_APP_API_DEV_CORS` is active), `Access-Control-Allow-Headers`, `Access-Control-Allow-Methods`, `Access-Control-Allow-Credentials`.

### `includes/class-app-mailer.php`
- **Purpose:** Wraps standard `wp_mail` with HTML framing and fallback templates for verification/password-reset emails.
- **Key Methods:**
  - `send_html_email( $to, $subject, $body )`: Configures filters for HTML header headers, formats messages with brand layouts, and dispatches mails.

---

## Part 3: User & Auth Layer (`includes/`)

### `includes/class-app-users.php`
- **Purpose:** Direct management of mobile app accounts inside the custom database table `wp_ru_app_users` (fully segregated from WP `wp_users`).
- **Schema Columns:** `id`, `display_name`, `email`, `phone_e164`, `password_hash`, `status`, `phone_verified`, `email_verified`, `created_at`, `updated_at`, `avatar_url`, `avatar_attachment_id`, `verification_code`.
- **Key Methods:**
  - `maybe_create_table()`: Applies schema. Column migrations are executed on activation.
  - `find_by_phone( $phone )`, `find_by_email( $email )`, `get_by_id( $id )`.
  - `soft_delete( $user_id )`: Marks user as deleted and clears `phone_e164`, `email`, `password_hash` to allow re-registration.

### `includes/class-app-password-auth.php`
- **Purpose:** Password validation, account creation, secure login sessions, and verification token generators.
- **Key Methods:**
  - `register( array $params )`: Enforces minimum length, uniques (mobile/email), sends verification email.
  - `login( array $params )`: Authenticates via mobile/email + password or E.164 phone + OTP.
  - `forgot_password( $identifier )`: Checks unverified identity limits and emails reset links or stores SMS OTP flags.
  - `reset_password( array $params )`.
  - `verify_email( array $params, $user_id )`.

### `includes/class-app-auth.php`
- **Purpose:** JWT-like bearer token session manager. Generates and validates auth headers.
- **DB Operations:** Tracks session transients prefix `ru_session_` with an expiration window of 30 days.
- **Key Methods:**
  - `require_auth( WP_REST_Request $request )`: Returns `true` if bearer token is valid. Bypassed only when `RADIOUDAAN_APP_API_DEV_AUTH` is defined (except on production domains).
  - `get_user_id_from_request( WP_REST_Request $request )`.
  - `revoke_token( $token )`.
  - `revoke_all_tokens_for_user_id( $user_id )`.

### `includes/class-app-profile.php`
- **Purpose:** Editing app user profile details (displayName, email updates) and processing avatar uploads.
- **Key Methods:**
  - `update_profile( $user_id, array $params )`: Saves updates to `wp_ru_app_users`.
  - `handle_avatar_upload( WP_REST_Request $request )`: Validates image formats, writes files to media uploads, registers attachment, and updates user profile.

### `includes/class-app-user-notification-prefs.php`
- **Purpose:** Database storage of per-user notification switches.
- **DB Operations:** Uses `wp_ru_app_notification_prefs` table.
- **Key Methods:**
  - `get_for_user( $user_id )`: Retrieves custom array (switches: `events_enabled`, `library_enabled`, `promotions_enabled`).
  - `update_for_user( $user_id, array $prefs )`.

---

## Part 4: SMS Gateway (`includes/`)

### `includes/class-otp-msg91.php`
- **Purpose:** Dispatches SMS notifications via MSG91 API gateway.
- **Key Methods:**
  - `init()` -> Action hook `radioudaan_app_api_send_otp`.
  - `send_sms( $phone, $otp )`: Hits MSG91 Flow API using configured Sender ID, Auth Key, and DLT Template ID.

### `includes/class-otp-service.php`
- **Purpose:** OTP generator, purpose coordinator, IP rate checks, and E.164 domestic validation.
- **Key Methods:**
  - `request_otp( $phone_e164, $purpose )`: Normalizes to E.164. Checks non-+91 domestic limit. Returns `400` with clear text instruction if non-+91 when MSG91 is live.
  - `verify_otp( $request_id, $otp )`: Validates code correctness. Increments wrong-verify attempts. Caps at `RadioUdaan_App_Settings::get_otp_verify_max_attempts()`.

---

## Part 5: Events & Registrations (`includes/`)

### `includes/class-cpt-ru-event.php`
- **Purpose:** Declares `ru_event` Custom Post Type.
- **Meta Keys:**
  - `_ru_event_code` (internal event code matching `RadioUdaan_Event_Registry`)
  - `_ru_forminator_form_id` (1:1 Forminator form mapping)
  - `_ru_registration_page_id` (Website page lookup)
  - `_ru_event_status` (`open` | `closed` | `draft`)
  - `_ru_event_start_at` (Datetime ISO)
  - `_ru_event_type` (`live_stream` | `workshop` | `other`)
  - `_ru_success_message` (Thank-you screen text)
  - `_ru_allow_multiple_registrations` (Enables multiple entries per email address)

### `includes/class-event-meta-ui.php`
- **Purpose:** Fields mapping lists, options select grids, Forminator dropdown choices for the admin CPT fields editor.

### `includes/class-event-registry.php`
- **Purpose:** Legacy hardcoded event fallbacks. Acts as registry dictionary for core event campaigns.
- **Key Methods:**
  - `get_definitions()`: Maps legacy campaigns (Udaan Idol ID 825, Becoming RJ ID 1178, One Minute Matters ID 1116).
  - `list_events( $status )`: Queries CPT posts or returns legacy overrides.

### `includes/class-event-sync.php`
- **Purpose:** Programmatically registers post definitions to `ru_event` when missing.
- **Key Methods:**
  - `sync_all()`: Resolves hardcoded configurations, programmatically creating WP Posts matching CPT if they do not exist.

### `includes/class-form-schema-builder.php`
- **Purpose:** Parses active Forminator form configurations, mapping and translating fields into API schemas.
- **Key Methods:**
  - `build_for_form( $form_id, array $summary )`: Decodes pages, fields, allowed file sizes, and options. Unsupported fields are returned in a separate array for client warning.

### `includes/class-registration-guard.php`
- **Purpose:** Pre-validation layer mapping rate limit checks and email duplicate registrations.
- **Key Methods:**
  - `assert_submission_allowed( $user_id, $event, $email )`: Checks if duplicate registrations are blocked.

### `includes/class-registration-handler.php`
- **Purpose:** Decodes event submissions, stages multi-part documents, and inserts entries into Forminator's database as `source=app`.
- **Key Methods:**
  - `submit( WP_REST_Request $request )`: Maps inputs, validates schemas, attaches staged private uploads, and saves the entry.

### `includes/class-entry-source.php`
- **Purpose:** Attaches source markers (`source=app`) to registration entries.
- **Hooks & Actions:**
  - `forminator_custom_form_submit_before_save` -> Binds custom entry meta.

---

## Part 6: Radio Broadcasts & Shows (`includes/`)

### `includes/class-app-live-radio.php`
- **Purpose:** Configurations for the Live Radio Home screen (WhatsApp chat lines, stream audio links, share copy text).

### `includes/class-app-radio-schedule.php`
- **Purpose:** Resolves schedules from `radio-shows` CPT, parsing ACF broadcast times.
- **Key Methods:**
  - `get_schedule( WP_REST_Request $request )`: Groups segments by week dates relative to `wp_timezone()`.

---

## Part 7: RJ Profiles & Directory (`includes/`)

### `includes/class-rj-profile.php`
- **Purpose:** Maps standard WordPress user metadata to preserve public RJ profiles (bio, social handles, hosting shows).

### `includes/class-rj-profile-admin.php`
- **Purpose:** Modifies WP Admin User profiles screen to display RJ specific fields (social URLs, host titles).

### `includes/class-rj-profile-migration.php`
- **Purpose:** Migrates legacy RJ Profile posts (CPT) to WordPress users with custom `rj` role.

### `includes/class-rj-profile-public.php`
- **Purpose:** Manages public URL query rewrites, routing `/rj-profiles/{user_nicename}` Single templates.

---

## Part 8: Library & YouTube Proxy (`includes/`)

### `includes/class-app-library.php`
- **Purpose:** Dynamic query loaders for local shows CPT lists.

### `includes/class-app-youtube-library.php`
- **Purpose:** Acts as a secure, cached API proxy for Google YouTube Data v3.
- **Key Methods:**
  - Hits playlist and search routes, caching endpoints locally to avoid API quota limits.

---

## Part 9: System Config & Push FCM (`includes/`)

### `includes/class-app-config.php`
- **Purpose:** Aggregates legal terms, settings limits, branding colors, and splash copy assets into a single config payload.
- **Cache Mechanism:** Stores results in a 5-minute Transient Cache.

### `includes/class-app-branding.php`
- **Purpose:** Manages brand colors and splash screens copy options.

### `includes/class-app-settings.php`
- **Purpose:** Declares system option keys, defaults, and handles developer bypass limits locks.
- **Key Methods:**
  - `get_production_warnings()`: Flags active test OTP states or bypassed bearer validation flags.
  - `dev_bypass_is_locked()`: Forces dev bypass settings to remain `disabled` when running on production URLs (`radioudaan.com`, `www.radioudaan.com`).

### `includes/class-app-support.php`
- **Purpose:** Manages user help queries, saving feedback to `wp_ru_app_support` table.

### `includes/class-app-fcm-sender.php`
- **Purpose:** Secure OAuth2 token wrapper and message payload constructor for Firebase HTTP v1 API.
- **Key Methods:**
  - `send_push_notification( $token, $title, $body, array $data )`: Formulates JWT signatures, retrieves cached tokens, and makes POST requests to Firebase.

---

## Part 10: Notifications & Uploads (`includes/`)

### `includes/class-app-notifications.php`
- **Purpose:** In-app inbox databases (`wp_ru_app_notifications` & `wp_ru_app_devices`) and push dispatcher hooks.
- **Key Methods:**
  - `register_device( $user_id, array $params )`: Registers FCM registration tokens.
  - `create_for_users( array $user_ids, $title, $body, $type, array $data )`: Enqueues messages, filters unsubscribed tokens, and fires FCM pushes.

### `includes/class-upload-cleanup.php`
- **Purpose:** System cleanup cron.
- **Hooks & Actions:**
  - `radioudaan_app_upload_cleanup_cron` -> Runs daily to delete expired private uploads from staging directories.

### `includes/class-app-uploads.php`
- **Purpose:** Handles private document staging before form entry submissions.
- **Key Methods:**
  - `stage_upload( $file, $user_id, $event_id, $field_key )`: Stages files under `/wp-content/uploads/radioudaan-app-private/` protected by a generated `.htaccess` (`Deny from all`) and an empty `index.php`.

### `includes/class-admin-form-migration.php`
- **Purpose:** Migrates Contact Form 7 forms into Forminator forms and swaps Elementor shortcodes.

### `includes/class-admin-app-hub.php`
- **Purpose:** Main menu registration, settings schema setups, and action dispatchers for admin screens.
- **Admin Submenu Slugs:**
  - `radioudaan-app` (Dashboard overview)
  - `radioudaan-app-events` (Events manager)
  - `radioudaan-app-users` (App registrations list)
  - `radioudaan-app-registrations` (Event entries list)
  - `radioudaan-app-notifications` (Compose notifications form)
  - `radioudaan-app-settings` (General Settings screen)
  - `radioudaan-app-help` (Help documents)
  - `radioudaan-app-api` (REST endpoints developer details)
  - `radioudaan-form-migration` (Advanced CF7 migration tools)

---

## Part 11: Admin UI Modules (`includes/admin/`)

### `includes/admin/class-admin-assets.php`
- **Purpose:** Enqueues admin stylesheets and scripts (`admin.css`, `admin.js`, `admin-settings.js`, `admin-settings.css`) in WP Admin pages.

### `includes/admin/class-admin-data.php`
- **Purpose:** Data aggregations and AJAX listeners for dashboard statistics, event reordering, and entry logs.
- **AJAX Actions:**
  - `wp_ajax_radioudaan_save_event_order` -> Saves CPT menu order when events are dragged in the admin dashboard.

### `includes/admin/class-admin-app-users.php`
- **Purpose:** Renders the list of registered App Users (`wp_ru_app_users`) who logged in or verified via phone OTP. Can query, list, and check verification timestamps.

### `includes/admin/class-admin-entry-viewer.php`
- **Purpose:** Renders details for a single Forminator entry (submitted files, user answers).
- **Key Methods:**
  - `render_page()`: Resolves entry metadata and loads labels.
  - `get_entry_detail( $entry_id, $form_id )`: Returns array of date, source label, phone numbers, and answers.
  - `format_value( $value )`: Formats uploaded files as direct secure download links.

### `includes/admin/class-admin-event-editor.php`
- **Purpose:** In-plugin event creator/editor panel.
- **Key Methods:**
  - `render_page()`: Enqueues media pickers and renders input fields.
  - `handle_save()`: Sanitizes and updates CPT post variables (`ru_event_status`, start times, success messaging templates, attachment image IDs).

### `includes/admin/class-admin-export.php`
- **Purpose:** Exports event submissions to CSV files.
- **Key Methods:**
  - `handle_export()`: Filters registrations by source/form, sets headers, writes CSV streams, and exits safely.

### `includes/admin/class-admin-help.php`
- **Purpose:** Renders help guide documents for non-technical staff.

### `includes/admin/class-admin-layout.php`
- **Purpose:** Admin UI container layout wrapper (header branding bar, dashboard tab navigations, and notification banners).

### `includes/admin/class-admin-notifications.php`
- **Purpose:** Forms composer for enqueuing notifications.
- **Key Methods:**
  - `render_page()`: Lists users with registered devices and configures targets.
  - `handle_send()`: Validates request nonces, handles user targets, and enqueues messages.

### `includes/admin/class-admin-pages.php`
- **Purpose:** Container class rendering main submenus:
  - `render_dashboard()`: General dashboard stats, REST API status indicator, recent entry lists.
  - `render_events()`: Event items table with drag-and-drop sort interfaces.
  - `render_event_entries()`: Form entry lists with source filter links.
  - `render_api()`: Endpoints reference sheet for developers.

### `includes/admin/class-admin-settings-page.php`
- **Purpose:** Tabbed settings dashboard interface.
- **Render Tabs:** Branding settings, Splash App Copy, Connection Base URLs, Live Radio hero settings, YouTube API scopes, App Accounts password rules, Legal URL fields, Upload stage constraints, OTP request windows, MSG91 configuration keys, and FCM Project settings.

---

## Part 12: REST Routes Summary

All REST endpoints operate under the namespace `/wp-json/radioudaan/v1`.

| Route | Method | Callback Method | Auth Required | Description |
|---|---|---|---|---|
| `/health` | `GET` | `RadioUdaan_App_Api::health` | No | API and database table checks |
| `/config` | `GET` | `RadioUdaan_App_Api::get_config` | No | Branding, legal URLs, and copy configurations |
| `/auth/register` | `POST` | `RadioUdaan_App_Api::auth_register` | No | Mobile account creation |
| `/auth/login` | `POST` | `RadioUdaan_App_Api::auth_login` | No | Session login via credentials or phone + OTP |
| `/auth/otp/request` | `POST` | `RadioUdaan_App_Api::otp_request` | No | Generates and sends OTP codes |
| `/auth/otp/verify` | `POST` | `RadioUdaan_App_Api::otp_verify` | No | Validates SMS OTP codes |
| `/auth/me` | `GET` | `RadioUdaan_App_Api::auth_me` | **Yes** | Current session details |
| `/auth/me` | `PATCH` | `RadioUdaan_App_Api::auth_me_update` | **Yes** | Profile updates (displayName, email) |
| `/auth/change-password`| `POST` | `RadioUdaan_App_Api::auth_change_password`| **Yes** | Secure password modification |
| `/auth/avatar` | `POST` | `RadioUdaan_App_Profile::handle_avatar_upload` | **Yes** | Secure avatar image staging |
| `/auth/notification-preferences` | `GET` | `RadioUdaan_App_Api::get_notification_preferences` | **Yes** | User notification switches lookup |
| `/auth/notification-preferences` | `PATCH` | `RadioUdaan_App_Api::patch_notification_preferences` | **Yes** | Update notification switches |
| `/auth/forgot-password`| `POST` | `RadioUdaan_App_Api::auth_forgot_password`| No | Trigger password reset verification |
| `/auth/reset-password` | `POST` | `RadioUdaan_App_Api::auth_reset_password` | No | Set new password via reset token |
| `/auth/email/resend` | `POST` | `RadioUdaan_App_Api::auth_email_resend` | **Yes** | Resend email verification code |
| `/auth/email/verify` | `POST` | `RadioUdaan_App_Api::auth_email_verify` | **Yes** | Verify email verification code |
| `/auth/logout` | `POST` | `RadioUdaan_App_Api::auth_logout` | **Yes** | Terminate and revoke active token |
| `/auth/account/delete` | `POST` | `RadioUdaan_App_Api::auth_account_delete` | **Yes** | Soft-deletes app account |
| `/support/contact` | `POST` | `RadioUdaan_App_Support::handle_contact` | No | Submit customer support queries |
| `/devices/register` | `POST` | `RadioUdaan_App_Api::devices_register` | **Yes** | Register device FCM token |
| `/notifications` | `GET` | `RadioUdaan_App_Api::list_notifications` | **Yes** | List user enqueued inbox messages |
| `/notifications/{id}` | `PATCH` | `RadioUdaan_App_Api::mark_notification_read` | **Yes** | Mark inbox item as read |
| `/events` | `GET` | `RadioUdaan_App_Api::list_events` | No | List registered CPT events |
| `/events/{id}` | `GET` | `RadioUdaan_App_Api::get_event` | No | Event metadata detail |
| `/events/{id}/form` | `GET` | `RadioUdaan_App_Api::get_event_form` | No | Forminator form schema mapping |
| `/events/{id}/registrations` | `POST` | `RadioUdaan_App_Api::submit_registration` | **Yes** | Submit event registration entry |
| `/uploads` | `POST` | `RadioUdaan_App_Api::upload_file` | **Yes** | Staged secure file uploads |
| `/library/shows` | `GET` | `RadioUdaan_App_Library::list_shows` | No | Local shows custom list |
| `/library/whats-new` | `GET` | `RadioUdaan_App_Library::list_whats_new` | No | What's New items custom list |
| `/library/schedule` | `GET` | `RadioUdaan_App_Radio_Schedule::get_schedule` | No | Live weekly program guide |
| `/library/youtube/recent` | `GET` | `RadioUdaan_App_Youtube_Library::rest_recent` | No | Channel-wide recent uploads |
| `/library/youtube/playlists` | `GET` | `RadioUdaan_App_Youtube_Library::rest_playlists` | No | All channel playlists list |
| `/library/youtube/playlists/featured` | `GET` | `RadioUdaan_App_Youtube_Library::rest_featured_playlists` | No | Admin-featured playlists |
| `/library/youtube/playlists/{id}/videos` | `GET` | `RadioUdaan_App_Youtube_Library::rest_playlist_videos` | No | Videos within a playlist |
| `/library/youtube/search` | `GET` | `RadioUdaan_App_Youtube_Library::rest_search` | No | Search channel video catalogue |
