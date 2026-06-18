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
| BUG-006 | 🔴 Critical | `radio_player_controller.dart` | Live Radio tab blank when `initRadioAudioService()` failed at startup — provider constructor threw on `radioAudioHandler` | User report | Fixed (pending rebuild) |
| BUG-007 | 🟡 Medium | Staging WP YouTube settings | Library playlists/videos return 503 `youtube_not_configured` — no API key on staging | User report | Fixed (WP admin key added) |
| BUG-008 | 🔴 Critical | `library_player_screen.dart` | YouTube iframe showed "Video unavailable" — WebView mounted only after tap, before player init | User report | Fixed (pending rebuild) | `browser_fill` on phone field sometimes does not update Flutter state (validation: “10-digit” while field looks filled). Workaround: click field → fill → Enter. “Verify and continue” needs bottom button click or semantics tree; Enter alone unreliable on OTP screen. | Agent 12 (IDE browser) | Open |
| BUG-004 | 🟢 Low | `go_router` | Direct URL `#/events` fails (`no routes for location: /events`); tabs are shell-only (`/`). | Agent 12 | Open (by design) |
| BUG-001 | 🟡 Medium | `.cursor/agents/README.md` | README referenced non-existent `agent-03-wp-app-api.md` (fixed) | Developer | Closed |

## Fixed Bugs

| ID | Severity | File | Description | Fixed By | Fix Description |
|----|----|---|----|----|-----|
| BUG-002 | 🔴 Critical | `includes/admin/class-admin-pages.php` | Settings page fatal: undefined constant `OPTION_COPY_EVENTS` (should be `OPTION_COPY_TAB_EVENTS`) | Coordinator | Corrected `copy_option_map` entry for Tab: Events |
| BUG-001 | 🟡 Medium | `.cursor/agents/README.md` | Broken agent filename reference | Developer | Updated to `agent-03-wp-app-api-engineer.md` |
| BUG-013 | 🟠 High | `class-app-config.php` | GET `/config` rebuilds `live_radio` on every cache hit | Multi-agent audit | Separate 60s transient for `live_radio`; removed from main 300s blob; `invalidate_cache()` clears both |

