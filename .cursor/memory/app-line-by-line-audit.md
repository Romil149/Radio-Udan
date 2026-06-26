### `lib/features/library/library_tab.dart`
- **Imports:** Atkinson Hyperlegible, Riverpod, widgets for search and list, and `DioExceptionMapper`.
- **Search Controller:** Employs a `TextEditingController` with a custom `Timer` listener acting as a 400ms debounce (`_searchDebounce = Duration(milliseconds: 400)`). Updates `librarySearchQueryProvider.notifier` when active.
- **Refresh Flow:** Toggles refresh invalidation on featured playlists, recent uploads, and search queries (running concurrent futures via `Future.wait`).
- **Tab Structure:** Standard `Scaffold` with a list view body. Renders featured playlists in a custom tile row, displays recent uploads, and handles search results conditionally.
- **Compliance & Traps:** Incorporates active `Semantics` overlays wrapping tap actions and loading states to optimize audio/video selection lists.

### `lib/features/library/library_playlists_screen.dart`
- **Catalog View:** Feeds full lists via `allYoutubePlaylistsProvider` to map playlists inside `ListView.separated`.
- **Data Binding:** Passes playlist models directly to child tiles. Invalidates providers when the list is pulled down (`RefreshIndicator`).

### `lib/features/library/library_playlist_videos_screen.dart`
- **Catalog Grid:** Consumes `youtubePlaylistVideosProvider` with family arguments (`playlist.id`) to fetch videos on demand.
- **Play Hooks:** Renders individual `LibraryVideoCard` entries, mapping video model instances to high-res thumbnail fetchers.

### `lib/features/library/library_player_screen.dart`
- **Playback Architecture:** Implements a full `YoutubePlayerIFrame` wrapper using the `youtube_player_iframe` dependency.
- **A11y Control:** Listens to state transitions (playing, buffering, paused, error) and pushes real-time screen reader vocal announcements via `SemanticsService.sendAnnouncement`.
- **Fallback Route:** Obscures playback details if `watchUrl` parsing fails, showing clean "open in YouTube app" alternate routes (`openExternalUrl`) to guarantee a non-breaking UI.

### `lib/features/library/widgets/library_playlist_tile.dart`
- **Compact & Featured Tiles:** Custom designs for full-width featured items (`LibraryPlaylistFeaturedTile`) and split grid items (`LibraryPlaylistCompactTile`).
- **Tile Binding:** Correctly extracts video count metadata labels and exposes accessible, screen-reader-optimized tap areas (min 56px heights).

### `lib/features/library/widgets/library_search_field.dart`
- **Input Field:** Accessible text entry container featuring high-contrast borders and clear buttons that wipe active query notifier states on click.

### `lib/features/library/widgets/library_section_heading.dart`
- **Heading Widget:** Atkinson Hyperlegible styling configured as a semantic header component (`header: true`).

### `lib/features/library/widgets/library_video_card.dart`
- **Save Hooks:** Displays a bookmark toggle button linking `librarySavedVideoIdsProvider` to update bookmarks in shared storage.
- **Visuals:** Shows a 16:9 ratio poster image layered with a play emblem. Translates descriptions and dates dynamically using relative date formatters.

---

## 13. Events Feature Module (`lib/features/events/`)

### `lib/features/events/event_deep_link_screen.dart`
- **Target Route:** Mounts a fallback screen showing a circular indicator when `/event/:eventId` deep links are invoked.
- **Routing Hook:** Triggers `openEventFromDeepLink` inside a `PostFrameCallback` block to delegate routing once the system builds the shell structure.

### `lib/features/events/event_formatters.dart`
- **Formatter:** Formats date inputs using `intl` markers to match the standardized format `OCTOBER 24, 2026 • 6:00 PM IST`.

### `lib/features/events/registration_account_prefill.dart`
- **Prefill Mappings:** Inspects field name/key labels (`looksLikeNameField` / `looksLikePhoneField`) to match user values from `AuthSession`.
- **Auto Populate:** Returns user-registered names, emails, and E.164 phone formats automatically, format-masking them for screen reader safety.

### `lib/features/events/models/form_schema.dart`
- **Model Schema:** Decodes event metadata, form IDs, and unsupported components from `GET /events/{id}/form`.
- **Fields Schema:** Standardizes field schema models (`FormFieldSchema`) to structure constraints (types: textarea, select, checkbox, upload, number, date, time).

### `lib/features/events/events_tab.dart`
- **Query Handler:** Watches `eventsProvider` which sorts open registration campaigns before closed events.
- **Card Rendering:** Standard list layout passing event models to widgets. Registers deep-link callbacks when registration status remains open.

### `lib/features/events/widgets/event_card.dart`
- **CTA Actions:** Renders status cards (workshops, live streams, other) with localized theme badges.
- **A11y Target:** Combines campaign labels into one voice block (`eventCardSemantics`) to allow screen readers to parse descriptions sequentially.

### `lib/features/events/widgets/registration_form_styles.dart`
- **Decoration Tokens:** Centralizes border, input text, option list, and check box tile layouts inside unified widgets.
- **Layout Compliance:** Sets min heights to 56px (`BrandTokens.a11yMinTapTarget`) and cleans out server-added asterisks before rebuilding labels.

### `lib/features/events/event_registration_screen.dart`
- **Form Engine:** Builds a dynamic form based on the CPT schema. Restores draft states from local file caches on init.
- **Draft Saves:** Monitors text modifications, single selections, and multipart uploads to save backups automatically with a 500ms debounce.
- **Multipart Uploads:** Sends documents to `POST /uploads` using a custom network client. Listens to upload progress variables to send voice milestones to screen readers (e.g. "Upload is 50% complete").
- **Validation Blocks:** Validates requirements sequentially. If a field fails validation, jumps focus directly to the target component.
- ** Prefill Lock:** Disables inputs and overlays secure lock icons on locked field widgets.

---

## 14. More Options Module (`lib/features/more/`)

### `lib/features/more/notifications_providers.dart`
- **Providers:** Houses providers to fetch unread counters and notification list records from the backend database.

### `lib/features/more/notifications_screen.dart`
- **List Controller:** Lists notifications (filtered by all or unread only). Marks messages read on click.
- **Visuals:** Left-side color indicators distinguish notification categories (live broadcasts vs. event signups).

### `lib/features/more/settings_screen.dart`
- **Draft System:** Saves settings changes locally as a temporary draft before committing them to shared preferences.
- **Toggles:** Accessibility switches for high contrast, bold text, reduce motion, and notification filters.
- **A11y Sliders:** Adjusts text scale settings dynamically. Debounces speech feedback when moving sliders.

### `lib/features/more/help_contact_screen.dart`
- **Contact Form:** Submits name, email, subject, and message inputs to the `/support/contact` endpoint.
- **CTA Shortcuts:** High-contrast buttons to trigger native system mail composers or call helplines directly.

### `lib/features/more/more_tab.dart`
- **Hub Navigation:** Routes to profiles, settings, notifications, help center, and legal URLs.
- **Pruning Hooks:** Prompts user confirmation before executing account deletions or session terminations.

### `lib/features/more/change_password_screen.dart`
- **Validator Engine:** Validates new passwords against strict length and special character rules.
- **Action Control:** Updates passwords via secure POST requests and terminates active logins on success.

### `lib/features/more/edit_profile_screen.dart`
- **Editor Profile:** Edits profile details (names and emails). Uploads avatar images to the backend.
- **Locked Mobile:** Obscures user phone fields to prevent modifications, display-locking them via secure tokens.

### `lib/features/more/widgets/contact_support_actions_card.dart`
- **Card Helper:** Groups helpline buttons inside a unified container.

### `lib/features/more/widgets/more_hero_card.dart`
- **Visual Badge:** Styled Atkinson header card used as a section container.

### `lib/features/more/widgets/more_menu_tile.dart`
- **Menu Tile:** Renders standard rows with left-aligned icons, labels, descriptions, and chevrons.

---

## 15. Routing, Push, & Theme System

### `lib/core/router/app_router.dart`
- **GoRouter Configuration:** Central routing schema. Listens to token states to run dynamic check redirects.
- **A11y Redirection:** Reroutes unverified emails or phones directly to confirmation screens on login.

### `lib/core/router/event_deep_link.dart`
- **Deep Link Router:** Normalizes incoming deep-link parameters (`radioudaan://event/123` or `/radioudaan/event/123/`) to route directly to active registration campaigns.

### `lib/core/push/push_notification_service.dart`
- **Firebase Messaging:** Configures channels, listens to foreground streams, and maps tokens.

### `lib/core/theme/accessibility_scope.dart`
- **Inherited Scope:** Broadcaster widget mapping style variables down the tree.

### `lib/core/theme/app_theme.dart`
- **Theme Builder:** Maps dynamic colors to style cards, inputs, and buttons.

### `lib/core/theme/brand_tokens.dart`
- **Layout Tokens:** Hardcodes standard sizes (56px touch target limits).

### `lib/core/theme/udaan_colors.dart`
- **Color Constants:** Static hex codes mapped to light, dark, and high contrast variations.

### `lib/core/theme/udaan_text_styles.dart`
- **Text Helper:** Integrates Atkinson Hyperlegible with support for accessibility bold preferences.

### `lib/core/theme/udaan_theme.dart`
- **Dynamic Themes:** Builds accessible themes matching WordPress configuration payloads.

---

## 16. Shared Core Widgets (`lib/core/widgets/`)

### `lib/core/widgets/brand_app_bar.dart`
- **App Bar:** Dark custom theme title container.

### `lib/core/widgets/brand_logo.dart`
- **Logo Loader:** Loads network assets with disk/memory caching; falls back to text headers on failure.

### `lib/core/widgets/empty_state.dart`
- **Status State:** Reusable empty/error view layout.

### `lib/core/widgets/live_badge.dart`
- **Live Pill:** Pulsing live badge container.

### `lib/core/widgets/main_tab_app_bar.dart`
- **Tab Header:** Top bar component with menu and profile icons.

### `lib/core/widgets/section_header.dart`
- **Header:** Styled title component with a left-accent color block.

---

## 17. Firebase Options

### `lib/firebase_options.dart`
- **Firebase Keys:** Hardcodes Firebase configuration options for Android and iOS targets.











