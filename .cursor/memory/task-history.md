
# Task History
<!-- Log of completed work. Helps new sessions understand what's already done. -->

### 2026-07-15 — iPad cold-launch blank page (App Store 2.1a)
**Requested by**: User — ASC rejection build 70, blank page on cold launch (iPad Air M3 / iPadOS 26).
**Root cause**: (1) Firebase/Crashlytics could hang before `runApp`; (2) bootstrap navigated to `/login` when config failed then router forced `/bootstrap` with `SizedBox.shrink()` blank; (3) `ValueKey(settingsKey)` remounted MaterialApp.router; (4) white LaunchScreen looked like a blank page.
**What was done**: Timed-out safe init; stay on splash offline+Retry when `!configLoaded`; allow auth routes when config null; remove MaterialApp remount key; dark launch storyboards; bump **2.0.0+71**.
**Files**: `main.dart`, `bootstrap_screen.dart`, `app_router.dart`, `app.dart`, LaunchScreen/Main storyboards, `pubspec.yaml`, `release-state.md`
**Status**: ✅ Local fix — needs TestFlight +71 for App Review resubmit.

### 2026-07-15 — Lock-screen / notification radio controls disabled
**Requested by**: User — Stop disabled in Notification Center / lock screen on Android + iOS.
**Root cause**: `RadioAudioHandler` exposed stop-only controls; iOS/Android media UIs primarily enable pause/play. Also only piped `playbackEventStream` (misses some `playing` flips) and left `systemActions` empty.
**What was done**: Broadcast pause+stop while playing; play+stop when paused with media; set `systemActions` play/pause/stop; refresh state from playbackEvent + playing + processingState streams. Build **2.0.0+70**.
**Files**: `radio_audio_handler.dart`, `pubspec.yaml`
**Status**: ✅ Local fix — needs TestFlight/APK ship to verify on device.

### 2026-07-14 — iOS Safari-only donate (App Store 3.1.1)
**Requested by**: User — Apple 3.1.1 rejection fix; Safari link-out only on iOS/iPad.
**Agents**: Daniel (Flutter / mobile).
**What was done**: iOS never mounts `DonatePayOnlineCard`; shows `DonateSafariLinkCard` opening Razorpay payment page via `LaunchMode.externalApplication`. URL from `info_hub.donate.razorpay.ios_safari_payment_url` or default `https://rzp.io/rzp/dswNW5g`. Android native Pay Online unchanged. Scan & bank kept. Copy keys `donate_safari_*`. Build **2.0.0+69**.
**Files**: `donate_screen.dart`, `donate_safari_link_card.dart`, `info_hub_config.dart`, `app_copy_defaults.dart`, `app_copy_accessors.dart`, WP `class-app-copy-catalog.php`, `pubspec.yaml`, `app-review-donations.md`, `release-state.md`.
**Status**: ✅ Local complete (not committed / not shipped).
**Notes**: Deploy WP catalog for new copy keys before expecting remote overrides; app defaults work offline.

### 2026-07-11 — App Store Connect submission paste package
**Requested by**: User — one markdown for ASC iOS submit (description exact, 4+, Review Notes, checklist).
**Agents**: Taylor (technical writer) — packaging only; no ASC API.
**What was done**: Created `.cursor/memory/app-store-connect-submission.md` (subtitle, promo, exact description, keywords, What’s New 2.0.0, Support/Privacy URLs from prod config, age 4+ guidance, build 68, Review Notes with demo PLACEHOLDERs, human click checklist). Fixed stale “I completed payment” in `app-review-donations.md` → auto-confirm on resume. Updated `release-state.md`.
**Status**: ✅ Package ready — human must fill demo phone/OTP, screenshots/App Privacy, then Submit for Review.
**Notes**: Privacy URL live: `https://radioudaan.com/privacy-policy/`.

### 2026-07-11 — Production cutover: bake radioudaan.com into release builds
**Requested by**: User — secrets imported; go ahead and publish.
**What was done**: CI iOS/APK + AppEnv → production API; bump **+66**; ship Transfer secrets plugin; prod smoke 19/19.
**Status**: Shipping

### 2026-07-11 — SECRETS-TRANSFER: Export/Import admin tool
**Requested by**: Alex → Marcus (staging → production key move)
**What was done**: Added `RadioUdaan_Admin_Secrets_Transfer` under Radio Udaan App → Transfer secrets. Export JSON (optional redact + copy overrides); import with group checkboxes + staging→prod URL rewrite; invalidates config cache. Operator doc: `.cursor/memory/secrets-transfer-checklist.md`.
**Files**: `includes/admin/class-admin-secrets-transfer.php`, hub + layout nav wire-up.
**Verify**: `php -l` clean; `verify-wp-plugin.sh` 7/7 PASS. Not deployed to staging/prod yet.
**Status**: ✅ Complete (local plugin)

### 2026-07-11 — Donate Pay Online focus order (VO/TalkBack)
**Requested by**: User — first focus was text fields; want Pay Online → donations heading → amount chips → custom amount field.
**Fix**: Scoped `OrdinalSortKey` 1→4 (+ rest 5+) inside `DonatePayOnlineCard`; no autofocus. Page headline/intro stay above the card.
**File**: `donate_pay_online_card.dart`. Bump **+65**.
**Status**: Shipping

### 2026-07-11 — Library search Clear missed by VoiceOver/TalkBack
**Requested by**: User — cross after search missed by blind users.
**Root cause**: Clear only as right sibling; `ExcludeSemantics` widget pattern; VO jumped to results. Field had no Actions entry for Clear.
**Fix**: `CustomSemanticsAction` “Clear search” on the field; visible X with `Semantics.excludeSemantics` + InkWell; sort keys; bump **+64**.
**Status**: Shipping

### 2026-07-11 — Remove Push diagnostics from Settings
**Requested by**: User — remove Push Diagnostics from settings completely.
**What was done**: Removed Settings entry; deleted `push_diagnostics_screen.dart`. Internal `PushDiagnostics` logger kept for push service.
**Status**: Bump **+63**

### 2026-07-11 — Notifications: remove Showing + Refresh
**Requested by**: User — remove Showing N and Refresh; ask what else can go.
**What was done**: Stripped status line, Refresh button, pull-to-refresh, empty→Settings. Screen is back + list only.
**Also removable later (optional)**: unread dot/highlight; More-tab unread subtitle; relative time (“2 min ago”).
**Status**: Bump **+62**

### 2026-07-11 — Notifications simplified: list-only (no detail page)
**Requested by**: User — remove internal page; keep simple; remove extras.
**Decision**: Inbox shows title + full message on each row. No detail screen, no All/Unread, no Mark all. Push opens Notifications list. Refresh kept.
**Status**: Bump **+61**, shipping

### 2026-07-11 — Video: Showing 18 but one row + VO Refresh crash
**Evidence**: User WhatsApp video — Notifications shows "Showing 18", one row (`rvgrwff`), empty space, Refresh → crash dialog.
**Root cause**: Duplicate ListView keys when notification `id` failed strict `as num` cast (all became 0) → Flutter collapsed to one child; VO crash on broken tree.
**Fix**: string-safe id parse; unique `notif-{id}-{index}` keys; explicit ListView children; soft-refresh length guard; bump **+60**.
**Status**: Pushing

### 2026-07-11 — Inbox tap dead + VO Refresh crash + count clarity
**Requested by**: User — cannot tap rows; VO Refresh crashes; only sees one notification.
**Root cause**: ExcludeSemantics wrapping InkWell blocked taps; Refresh announce + list rebuild under VO focus; count banner only when truncated.
**Fix**: Semantics.excludeSemantics property; push-before-markRead; no refresh announce; reuse items when ids unchanged; always “Showing n”; bump **+59**.
**Status**: Pushing

### 2026-07-11 — Notification panel → detail + VoiceOver Refresh crash
**Requested by**: User — panel tap must open detail; VO swipe after Refresh crashes.
**Root cause**: Cold-start open returned when navigator null; VO crash from FilterChip/ExcludeSemantics + listen-in-build + competing announces.
**What was done**: Navigator retry opener; FLN launch details; FCM data title/body; safe announce; listenManual; filter toggles; single delayed refresh announce; bump **+58**.
**Status**: Pushing for TestFlight

### 2026-07-11 — Fix +56 IPA: prefersPageSizing iOS 17 availability
**Requested by**: User — CI `flutter build ipa` failed on ShareLargeSheet.swift:52.
**Root cause**: `prefersPageSizing` is iOS 17+ but was gated as iOS 16.
**What was done**: `#available(iOS 17.0, *)`; bump **2.0.0+57**.
**Status**: Pushing to main for CI rebuild

### 2026-07-11 — Notifications inbox a11y/UX improvements
**Requested by**: User — implement unread More subtitle, summary announce, All/Unread, Refresh, push→refresh, showing latest 20, type speech, empty→Settings, fix accents.
**Agents**: Alex → Marcus (copy) + Daniel/Maya (Flutter) → verify
**What was done**: More “N unread”; list summary announce; filter chips; Refresh button; push/open refresh; showing-latest banner; type labels+accents; empty→Settings; 12 new copy keys (WP+Flutter).
**Status**: ✅ Local verified — not committed; staging copy still 459 until plugin redeploy (new keys local-only)

### 2026-07-11 — Restore More Notifications inbox + remove admin Open in app
**Requested by**: User — Notifications under User profile (top 20 → detail title/message); remove Open in app from WP compose.
**Agents**: Alex → Marcus (WP) + Daniel/Maya (Flutter) → Elena (verify)
**What was done**:
- More tab: Notifications tile after User profile → `NotificationsScreen` (top 20 via `GET /notifications`)
- Detail: title + message only (Open CTA removed)
- WP admin: removed Open in app dropdown + what's-new/URL fields; sends pass empty `action_data`
**Files**: `more_tab.dart`, `notifications_screen.dart`, `notifications_providers.dart`, `notification_detail_screen.dart`, `class-admin-notifications.php`
**Status**: ✅ Local verified (analyze 0 / verify-wp 7/7 / smoke 19/19) — not committed/pushed; plugin zip not redeployed

### 2026-07-11 — Remove Notifications inbox screen entirely
**Requested by**: User — remove notifications screen after menu tile removal.
**What was done**: Deleted `notifications_screen.dart` + `notifications_providers.dart`; push taps open detail only; removed More-tab unread badge.
**Kept**: `notification_detail_screen.dart` for push tap content + Open destination.
**Status**: ✅ Local — not pushed

### 2026-07-11 — Remove Notifications row from More tab
**Requested by**: User — remove Notifications / Alerts and updates menu tile.
**What was done**: Removed `MoreMenuTile` for inbox from `more_tab.dart`. Push tap → detail/inbox still works via `notification_open.dart`.
**Status**: ✅ Local — not pushed

### 2026-07-11 — Build bump +55 for TestFlight
**Requested by**: User — push with updated build number.
**What was done**: `pubspec.yaml` 2.0.0+54 → **2.0.0+55**; release-state updated.
**Status**: ✅ Pushing to `main` for CI / TestFlight

### 2026-07-11 — iOS share sheet still half; force full screen host
**Requested by**: User — large detent alone still opens half; need full.
**What was done**: Full-screen host presents `UIActivityViewController` with `.fullScreen` (detents on activity VC ignored by system).
**Files**: `ShareLargeSheet.swift`, `pubspec.yaml` (+54)
**Status**: ✅ Shipped in +54; re-shipped as **+55**

### 2026-07-11 — Donate TalkBack: remove summary live region from swipe order
**Requested by**: User — swiping past custom amount heard duplicate "you will donate X" + different earcon.
**What was done**: `donate_pay_online_card.dart` — summary strip wrapped in `ExcludeSemantics` only (visual kept); removed `liveRegion` focus stop. Amount still announced on chip select + Donate button.
**Files**: `donate_pay_online_card.dart`, `pubspec.yaml` (+53)
**Status**: ✅ Shipped — build **2.0.0+53**

### 2026-07-11 — Enterprise notifications inbox + plugin deep links
**Root cause**: Admin sends had no `route` in data; push tap with id-only local payload skipped detail; unread filter was client-only (load-more hidden).
**What was done**:
- Plugin: compose **Open in app** (radio/events/what's new/url); `GET /notifications/{id}`; `?unread=1`; admin inbox totals
- Flutter: detail always opens; **Open** CTA via `notification_destination.dart`; push hydrates GET by id; server unread pagination; JSON local tap payload
**Status**: ⚠️ Local — deploy plugin zip + app build (+52 if shipping); device test 3 sends + tap + Open

### 2026-07-11 — Library search Clear (X) not recognized by TalkBack/VoiceOver
**Requested by**: User — cross button for library not seen/recognized by blind users.
**Root cause**: Clear control used `Semantics(button, label)` without `onTap` while wrapping `IconButton` in `ExcludeSemantics` — same class of bug as notification cards; SR often skips or cannot activate.
**What was done**: Switched to `UdaanAccessibleButton` (label + onTap); announce “Search cleared”; added `library_search_clear` / `library_search_cleared` to WP copy catalog (was missing from catalog; app defaults already had clear).
**Files**: `library_search_field.dart`, `app_copy_defaults.dart`, `app_copy_accessors.dart`, `class-app-copy-catalog.php`
**Status**: ⚠️ Local — device retest with TalkBack/VoiceOver after rebuild; plugin deploy for new copy keys.

### 2026-07-11 — iOS share sheet prefers large / full detent
**Requested by**: User — system share opens half sheet without Close X; full drag shows X.
**What was done**: Native `ShareLargeSheet` + MethodChannel `radioudaan/share` presents `UIActivityViewController` with `detents = [.large()]`; Dart `shareSystemText` uses channel on iOS, `share_plus` elsewhere; Radio tab wired.
**Files**: `ios/Runner/ShareLargeSheet.swift`, `AppDelegate.swift`, `project.pbxproj`, `lib/core/share/system_share.dart`, `lib/features/radio/radio_tab.dart`
**Status**: ⚠️ Local only — needs device rebuild to confirm full sheet + Close X. Not in TestFlight (+50).

### 2026-07-11 — Pay Online guided TalkBack/VoiceOver journey
**Requested by**: User — clear donation speech script (intro → amounts → custom → summary → donate with amount).
**What was done**: Guided copy; spoken summary liveRegion; chip/80G Semantics.onTap; donate button includes amount; account email read-only; Form 10BE spoken when expanded; loading label.
**Status**: ⚠️ Local — needs app build + plugin deploy for new copy keys on staging.

### 2026-07-11 — iOS donate: remove invalid Razorpay callback_url (option A)
**Requested by**: User — Donate now → loader → “Payment could not be completed”; no Safari. Chose fix A.
**Root cause**: Staging Payment Link rejected `radioudaan://` callback_url.
**What was done**: Omit callback_url; verify captures paid links without payment_id; iOS poll 15×2s; zip `dist/radioudaan-app-api-staging.zip`.
**Status**: ⚠️ **Must deploy plugin zip to staging** before iPhone retest. App poll change needs build only for longer wait (optional).

### 2026-07-10 — iOS push: inbox yes, banner no
**Requested by**: User — Android push works; iOS sees tab inbox only; diagnostics show APNs+FCM+register success.
**Findings**: Inbox ≠ push (DB first). Staging FCM project match OK, 4 devices. Client registration healthy. Top cause: Firebase APNs Auth Key for iOS app on `radio-udaan-72232`.
**What was done**: Per-platform push stats + last_error in admin/FCM logs; iOS foreground presentation set earlier in client.
**Status**: ⚠️ Operator must verify APNs key in Firebase Console; redeploy plugin for admin breakdown.

### 2026-07-10 — Notifications detail broken on real device (TalkBack)
**Requested by**: User — “not done” on device; title + own page.
**Root cause**: List card `Semantics(button)` had **no `onTap`** — SR double-tap often did nothing; detail top bar reused list title; only page 1 loaded.
**What was done**: Semantics.onTap on cards; detail top bar “Notification” + title heading; load more; copy keys.
**Status**: ⚠️ Local — needs hot restart / new device build (not in TestFlight yet as separate bump).

### 2026-07-10 — Full plugin functional audit (App Users + admin handlers)
**Requested by**: User — audit carefully; delete failed with UNIQUE email; check each function.
**Findings**:
- BUG-025 nested forms (Pause/Delete) — fixed
- BUG-026 soft-delete `email=''` UNIQUE collision — fixed (tombstones + migrate 2.3)
- FAIL: paused phone/email could re-register — fixed (`phone_taken`/`email_taken` include paused)
- FAIL: event save could rewrite non-event posts — fixed (post_type guard)
- FAIL: settings FCM error message lied about other settings — fixed (honest copy + cache invalidate)
- PASS: pause/resume/bulk nonces+caps; nested forms gone; auth blocks paused/deleted; tombstones don't block signup
**Status**: ⚠️ Local — **deploy full plugin** to staging before retesting Delete on user 126.

### 2026-07-10 — Fix soft-delete UNIQUE email collision (BUG-026)
**Requested by**: User — `Duplicate entry '' for key 'email'` on delete user 126.
**Root cause**: `soft_delete` set `email`/`phone_e164` to `''`; UNIQUE index allows only one empty value.
**What was done**: Tombstone values per id; column migration 2.3 repairs existing deleted rows; nested-form fix (BUG-025) already in place.
**Status**: ⚠️ Local — deploy full plugin to staging, then retry Delete.

### 2026-07-10 — Fix App Users Pause/Delete (nested forms) + enterprise admin audit
**Requested by**: User — App Users actions do nothing; want enterprise-level plugin improvements.
**Root cause**: Pause/Delete/Resume forms nested inside bulk `<form>` (same class of bug as BUG-022).
**What was done**: Un-nest bulk vs row forms (`form=` on checkboxes); enterprise audit + 30-day roadmap delivered in chat.
**Status**: ⚠️ Local plugin fix — deploy to staging to verify. Roadmap not implemented yet.

### 2026-07-10 — Ship +49: iOS launch safety + notifications detail + donate UI
**Requested by**: User still sees crash after build 46; notifications/donate work pending.
**Root cause**: +47 no UIScene; +48 early `FirebaseApp.configure` / Messaging before Dart init.
**What was done**: +46-safe AppDelegate; APNs apply only when Firebase ready; notification detail + mark read; Pay Online chip UI; bump **2.0.0+49**.
**Status**: Pushing.

### 2026-07-10 — Notifications: detail screen + mark read on open
**Requested by**: User — open inside notifications; mark read; top 20 fine.
**What was done**: `NotificationDetailScreen`; list shows preview + chevron; mark read on detail open; push/local tap marks read and opens detail when possible.
**Status**: ⚠️ Local — needs build bump to ship.

### 2026-07-10 — Fix iOS +47 launch crash (restore UIScene)
**Requested by**: User — TestFlight +47 “Radio Udaan Crashed” on open.
**Root cause**: +47 removed `UIApplicationSceneManifest` / used classic AppDelegate; Flutter 3.38+ requires UIScene + `FlutterImplicitEngineDelegate`.
**What was done**: Restore scene manifest + ImplicitEngine; keep Firebase configure + APNs cache/re-apply in SceneDelegate; ship **2.0.0+48** with donate a11y/auto-confirm.
**Status**: Pushing.

### 2026-07-10 — Donate Pay Online: auto-confirm + quieter a11y
**Requested by**: User — remove “I completed payment”; improve Razorpay UI/a11y (section announced everything).
**Staging config check**: Razorpay **enabled** live key; presets 100/500/1000/5000; **80G on**; 80G PDF email **off**; UPI set; **QR image empty**.
**What was done**: iOS auto-verify on app resume (poll `/donate/verify`); removed manual button; merged header semantics; clearer amount chips/summary; 80G checkbox single announcement; Form 10BE as hint; validation focus; verify-screen copy fix; new copy keys (app defaults + WP catalog).
**Status**: ⚠️ Local — needs build bump + plugin deploy for new catalog strings on staging.

### 2026-07-10 — iOS APNs: revert UIScene (classic AppDelegate)
**Requested by**: User — Android push OK; iOS forever `APNs token NOT ready` on +46.
**Root cause**: `FlutterImplicitEngineDelegate` + `UIApplicationSceneManifest` prevents FlutterFire APNs swizzling; token never reaches `Messaging.getAPNSToken()`.
**What was done**: Classic `FlutterAppDelegate`; remove scene manifest; `FirebaseApp.configure()` + cache/re-apply APNs token; iOS re-`requestPermission` when already authorized; debounce duplicate push sync; bump **2.0.0+47**.
**Status**: ⚠️ Local — needs commit + TestFlight before device retest.

### 2026-07-10 — Razorpay iOS Payment Link + Android native path
**Requested by**: User — iOS donate not working; Android opens browser.
**Findings**: Android browser-like UI is Razorpay native Custom Tab (expected). iOS Payment Link failed when `notify.email=true` with empty email; callback lacked `order_id`.
**What was done**: WP payment link resilient notify + `callback_url?order_id=`; skip link for Android platform; Flutter passes `platform`; harden native open + deep link parse.
**Status**: ⚠️ Local — needs plugin deploy + app build (+47).

### 2026-07-10 — CI fix: google-services 4.4.2 for Crashlytics 3
**Requested by**: CI fail on +45 — Crashlytics plugin 3 requires Google-Services ≥4.4.1.
**What was done**: Bump `com.google.gms.google-services` to 4.4.2; build **2.0.0+46**.
**Status**: Pushing.

### 2026-07-10 — Android Firebase init: Crashlytics component missing (Razorpay)
**Requested by**: User — +44 Android diagnostics: `FirebaseCrashlytics component is not present` (stack via `com.razorpay`).
**Root cause**: `firebase_crashlytics` in pubspec but Crashlytics Gradle plugin missing; R8 release strip broke Crashlytics registrar; Razorpay touches Crashlytics during Firebase init.
**What was done**: Apply `com.google.firebase.crashlytics` plugin; ProGuard keep Firebase/Crashlytics; build **2.0.0+45**.
**Status**: Pushing to main.

### 2026-07-10 — Push diagnostics: iOS APNs + Android Firebase init
**Requested by**: User — iPhone `apns-token-not-set`; Android `Firebase not initialized`.
**Root cause**: iOS UIScene/`FlutterImplicitEngineDelegate` skips FlutterFire APNs swizzling; Android `ensureFirebase` hid real init errors.
**What was done**: AppDelegate forwards APNs token to `Messaging.messaging().apnsToken`; Dart logs full Firebase init errors; map APNs errors → `tokenUnavailable`.
**Status**: ⚠️ Local — needs build bump + push for TestFlight/APK. Still need Firebase **production** APNs key + WP FCM project `72232`.

### 2026-07-10 — Full push notification audit (Android + iOS)
**Requested by**: User — phones not receiving push.
**Agents**: Senior mobile + WP push specialist.
**Findings**: Staging `fcm_configured: true` but project **`radio-udaan-cbfdc`** ≠ app **`radio-udaan-72232`** (BUG-023); **`push_devices_registered: 0`**. Repo Flutter/iOS entitlements/FCM sender OK. Admin “sent” = inbox rows; push needs devices + matching project.
**Code fixes**: Admin/settings mismatch warnings; health `expected_app_fcm_project` + `fcm_project_matches_app`; accurate “all users” label; `ios-push-setup.md` corrected.
**Verification**: php -l PASS; verify-wp-plugin 7/7; dart analyze push PASS; staging smoke 19/19; health evidence above.
**Status**: ⚠️ Blocked on operator — replace staging FCM SA with `radio-udaan-72232`, deploy plugin, register device on physical phone, confirm APNs key in Firebase.

### 2026-07-10 — Settings Save button not working (BUG-022)
**Requested by**: User — Save on App API settings does nothing.
**Agents**: WP admin UI specialist.
**Root cause**: Nested `<form>` for FCM/MSG91 test buttons inside main settings form; HTML5 parser ignores inner `<form>` then closes outer form on `</form>`, orphaning Save.
**What was done**: Deferred standalone test forms + `form=` attribute on buttons; reveal search-hidden fields on submit (BUG-015 hardening). About Us picker unchanged.
**Files**: `class-admin-settings-tests.php`, `class-admin-pages.php`, `admin-settings.js`
**Verification**: php -l PASS; node --check JS PASS.
**Status**: ⚠️ Local — needs plugin deploy to staging/wp-admin.

### 2026-07-10 — Push notification full audit (Android + iOS)
**Requested by**: User — push not working on Android or iPhone.
**Agents**: Alex → push specialist; parent verified live `/health`.
**Evidence (staging)**: `fcm_configured: true`, `fcm_project_id: radio-udaan-cbfdc`, `push_devices_registered: 0`. App Firebase = `radio-udaan-72232`.
**Root cause**: (1) WP FCM credentials are for wrong Firebase project vs app; (2) no devices registered.
**Code**: Client/iOS entitlements/Android channel PASS. Local plugin warnings for project mismatch (not yet deployed).
**Status**: ❌ Blocked on operator — paste `radio-udaan-72232` service account, confirm APNs in that project, physical device register, plugin deploy.
**Notes**: Admin “sent” = inbox rows; does not prove FCM delivery.

### 2026-07-10 — Settings Save button broken (nested forms)
**Requested by**: User — plugin settings Save not working.
**Root cause**: Nested Test FCM/MSG91 `<form>` inside main settings form closed the outer form early; Save was outside any form.
**What was done**: Deferred standalone test forms after main `</form>`; buttons use HTML5 `form=`; submit also shows search-hidden fields.
**Verification**: php -l PASS; verify-wp-plugin 7/7; node --check admin-settings.js PASS.
**Status**: ⚠️ Local — needs plugin deploy to staging.

### 2026-07-10 — About Us from plugin (info_hub.about)
**Requested by**: User — About Us story/vision editable like Donate; remove legal page picker.
**Agents**: Alex → WP + Flutter specialists; parent verified.
**What was done**: WP About Us fields + media on Settings → About tab; `info_hub.about` in config; legal about omitted; Flutter `AboutUsScreen` + always-visible tile.
**Verification**: php -l PASS; verify-wp-plugin 7/7; dart analyze 0 errors; staging smoke 19/19 (staging API still old plugin — no `info_hub.about` until deploy).
**Status**: ⚠️ Local — needs plugin deploy + app build.

### 2026-07-10 — YouTube loader Option A (optimistic / intent-based)
**Requested by**: User — spinner still stuck while video plays (iOS + Android); chose Option A.
**Agents**: Alex → Daniel ([YT-LOADER-A](8533e2d0-d4ff-439a-891f-fd16d70b0a2a)); parent verified.
**Root cause**: Spinner gated on flaky iframe `PlayerState.playing`; probes alone insufficient.
**What was done**: `_isPlaying` = user intent; `_startingPlayback` clears after ~1s grace once controller exists; soft confirm cancels 15s timeout; ignore unknown/cued/unStarted; ignore spurious paused during start.
**Verification**: `dart analyze lib/features/library/library_player_screen.dart` — 0 errors.
**Status**: ⚠️ Local — not committed / not in +42.

### 2026-07-10 — Share: remove custom popup; use OS share only
**Requested by**: User — don’t want Share/Copy app sheet; device default share has dismiss.
**Agents**: Alex → verify + revert custom sheet.
**What was done**: `_shareApp` calls `SharePlus` directly again. Radio schedule Close X kept.
**Verification**: dart analyze radio_tab = 0 issues.
**Status**: ⚠️ Local — not in +42 push yet (post-push fix).

### 2026-07-10 — What's New uses whats-new + latestcommunitynews
**Requested by**: User — drop in-news; use latestcommunitynews + whats-new.
**Agents**: Alex → Marcus/Daniel; parent verified php -l + dart analyze.
**What was done**: Plugin list_updates + detail route + push; Flutter enum/API/detail UI; copy Community News.
**Status**: ⚠️ Local — needs plugin deploy to staging + app build to ship.
**Notes**: Staging currently still serves old in-news until plugin zip deployed.

### 2026-07-10 — Hide About/More hero banners from SR
**Requested by**: User — “About Radio Udaan” + “More Options” must not be spoken.
**Agents**: Alex → implement.
**What was done**: `MoreHeroCard` fully `ExcludeSemantics` (decorative; tab title + menu tiles remain).
**Verification**: dart analyze touched files = 0 errors.
**Status**: ⚠️ Local — not committed.

### 2026-07-10 — Event registration keyboard Done + tap-outside
**Requested by**: User — make keyboard close easy for blind users (align with Login).
**Agents**: Alex → Daniel; parent verified.
**What was done**: All text fields + subfields: onTapOutside dismiss; KeyboardAccessory Done+Next (single-line/subfields); Done-only for textarea.
**Verification**: dart analyze = 0 errors.
**Status**: ⚠️ Local — not committed.

### 2026-07-10 — Choice checked/selected not audible (client report)
**Requested by**: User/client — cannot hear if checkbox/radio selected.
**Agents**: Alex → Maya; parent verified.
**Root cause**: Only `Semantics.checked` set; state words not in label; custom onTap often silent on TalkBack (#155298).
**What was done**: Label includes checked/selected / not…; announce new state on toggle; consent same. Copy keys a11y_*.
**Verification**: dart analyze 0 errors; registration_form_a11y_test 2/2.
**Status**: ⚠️ Local — not committed.

### 2026-07-10 — Event registration: unlock prefilled name/email/phone
**Requested by**: User — prefill but not locked; also check radios.
**Agents**: Alex → Daniel; Maya radio check.
**What was done**: Removed registration lock (readOnly/lock icon/cannot-edit hint); prefill kept. Radios/choice tiles already OK (checked, exclusive group, groupLabel, 56px). Decision logged.
**Verification**: dart analyze event_registration_screen = 0 errors.
**Status**: ⚠️ Local — not committed.

### 2026-07-10 — SCREEN-07 Events fields vs guide (code audit)
**Requested by**: User — check all Events fields vs guide/requirements.
**Agents**: Alex → Maya (audit only).
**What was done**: Field-type inventory + E1–E14. Critical: consent HTML silent (E1). HIGH: submit announce, upload client errors, event card Register verb. Text/choice/info mostly PASS. Doc SCREEN-07-events.md + canvas. No fixes.
**Status**: ⚠️ Discussion — awaiting Q1–Q6 or fix scope.

### 2026-07-10 — Library/API: auto-retry GET once + friendly timeout
**Requested by**: User (timeout error + Retry — auto retry once).
**Agents**: Alex → Marcus/Daniel; parent verified.
**What was done**: Dio interceptor retries GET/HEAD once on transport timeout/connectionError; ApiError maps those to bootstrapOffline (no raw Dio text). POST/OTP never auto-retried.
**Verification**: dart analyze api_client + api_error = 0 issues.
**Status**: ⚠️ Local — not committed.

### 2026-07-10 — Library search Clear button not in SR tree
**Requested by**: User (Search Videos clear not readable).
**Agents**: Alex → Maya/Daniel; parent verified.
**Root cause**: Clear lived in `suffixIcon` inside `AccessibleTextFieldSemantics` → `ExcludeSemantics` (FIND-034 class).
**What was done**: Clear moved outside field in Row; label `library_search_clear` = “Clear search”; 56×56.
**Verification**: dart analyze = 0 issues.
**Status**: ⚠️ Local — not committed.

### 2026-07-10 — Radio schedule + Share Close (X) for SR dismiss
**Requested by**: User — only fix missing cross on schedule and share popups.
**Agents**: Alex → Daniel; parent verified + `close` copy key.
**What was done**: Schedule header Close X; Share opens app sheet (Close / Share / Copy) before SharePlus. Copy key `close`. Other Screen 06 R-items untouched.
**Verification**: dart analyze touched files = 0 issues.
**Status**: ⚠️ Local — not committed.

### 2026-07-10 — SCREEN-06 Live Radio line-by-line a11y audit
**Requested by**: User — continue auditing.
**Agents**: Alex → Maya (code audit, no edits).
**What was done**: Full Radio tab + schedule sheet audit vs guide. Open **R1–R10** (HIGH: silent play/stop R1, error announce R2). FIND-043 still open as R3; FIND-044 fixed in code pending device. Created POPUP-06 doc; updated SCREEN-06 + canvas.
**Status**: ⚠️ Discussion — awaiting Q1–Q6 or “fix Screen 06”.
**Notes**: No Screen 05 in matrix; auth → Radio is next after OTP.

### 2026-07-10 — Password show/hide ↔ screen-reader speak sync
**Requested by**: User — show/hide not properly synced with password speak.
**Agents**: Alex → Maya.
**Root cause**: Boolean wiring was correct, but toggle gave no SR confirmation; Android obscure semantics can lag (#99763) so users heard stale character speech.
**What was done**: `isPassword` on AccessibleTextFieldSemantics; on obscure flip announce “Password shown/hidden” (never the password); value null while hidden; wired on login/email/register/reset/change-password. Copy keys added.
**Verification**: dart analyze touched files = 0 errors.
**Status**: ⚠️ Code local — not committed with OTP fixes yet.

### 2026-07-10 — Fix SCREEN-04 OTP O1–O8 + Screen 03 P1
**Requested by**: User (@alex) — “Ok fix now”.
**Agents**: Alex → Maya (a11y).
**What was done**: Verifying/resending announces; single task heading in top bar; merged intro+phone; wait timer liveRegion (login+identity); trailing icon excluded; contact support combined label; phone login sending-code announce.
**Verification**: `dart analyze` touched auth files = 0 errors.
**Status**: ⚠️ Code complete local — not committed; device QA pending.
**Notes**: Ask before commit/build bump +42. P2 intro Semantics on Screen 03 still optional.

### 2026-07-09 — SCREEN-04 OTP verify line-by-line a11y audit
**Requested by**: User (@alex) — next screen after 03.
**Agents**: Alex → Maya.
**What was done**: Full OTP verify audit (login + identity bodies). Open **O1–O8**; highest **O3** (verify loading silent). PIN Editing OK from +41. Appended to SCREEN-04-otp.md. Screen 03 parked. Canvas updated.
**Status**: ⚠️ Discussion — awaiting fix vs continue to Radio.

### 2026-07-09 — SCREEN-03 Phone login line-by-line a11y audit
**Requested by**: User (@alex) — go to next screen after Login.
**Agents**: Alex → Maya (a11y engineer).
**What was done**: Full read of phone_login_screen + shared widgets. Open: **P1** (no Sending code announce), **P2** (intro plain Text). Build 41 phone/Editing/POPUP/logo inherited. Canvas + SCREEN-03-phone-login.md updated. No code fix yet.
**Status**: ⚠️ Discussion — awaiting P1/P2.

### 2026-07-09 — TestFlight upload fail build 41 (ASC list-apps 500)
**Requested by**: User — CI error paste (Node 20 warning + altool 500).
**What was done**: Chris diagnosed: IPA built OK; upload failed on Apple ASC `list-apps` HTTP 500 → altool error 19. Same workflow uploaded build 40 earlier same day. Node warning is noise. `gh` not authed here — user must re-run in Actions UI.
**Status**: ⚠️ IPA on Artifacts; TestFlight not uploaded until re-run or Transporter.
**Notes**: Harden later: `upload-testflight-build@v5` with `backend: appstore-api` or `--apple-id 1439057220`.

### 2026-07-09 — Ship build 41 Login a11y + global Editing announce
**Requested by**: User — commit to GitHub with +41 build.
**What was done**: Pushed `ce59a9b` (app + a11y fixes) and `f49ff7d` (release-state hash). Build **2.0.0+41**.
**Status**: ✅ Pushed to `main` — CI APK/TestFlight pending; device QA still needed.
**Notes**: Unrelated WP plugin admin edits left uncommitted.

### 2026-07-09 — Standing rule: always best employee on the task
**Requested by**: User (@alex) — always use the best employee; if no worker for the role, hire one with the best skills required.
**What was done**: Logged in `decisions.md`, `project-knowledge.md`, and `.cursor/rules/specialist-agents.mdc` (BEST employee section + named roster).
**Status**: ✅ Complete — applies to all future sessions.

### 2026-07-09 — Fix Screen 02 a11y issues globally (L1–L6 + POPUP-02 + W4)
**Requested by**: User (@alex) — fix all Screen 02 issues globally.
**What was done**: L6 Editing announce + focused in AccessibleTextFieldSemantics (app-wide) + OTP pin; L1/L2/L4 phone semantics + autofill normalize; L3 loading announce; L5 Login heading; W4 logo ExcludeSemantics; POPUP-02 full-height + BlockSemantics + barrier.
**Verification**: `dart analyze lib` = 0 errors (16 pre-existing infos).
**Status**: ⚠️ Code complete local — not committed; device QA pending.
**Notes**: Ask before commit/build bump +41.

### 2026-07-09 — L6 GLOBAL: “editing” never announced on text fields
**Requested by**: User — does not hear “text field is editing” on any screen.
**What was done**: Confirmed root cause in `AccessibleTextFieldSemantics` (ExcludeSemantics strips native editing; no `focused:` / no announce on focus). Logged L6 in SCREEN-02-login.md + canvas. No code fix yet — awaiting Q-E1–E4.
**Status**: ⚠️ Open finding — discuss before fix.
**Notes**: Affects all screens using AccessibleTextFieldSemantics.

### 2026-07-09 — SCREEN-02 Login line-by-line a11y audit (discuss before fix)
**Requested by**: User — move to Screen 2; same process (read all code, apply guide, discuss wrong in popup).
**What was done**: Full read of login_screen / udaan_phone_field / udaan_auth_widgets / AccessibleTextFieldSemantics. Confirmed FIND-024/033/034 fixed in +40. Open wrong: **L1–L5** (helper silent, redundant phone label, loading silent, autofill edge, no Login heading). Canvas + SCREEN-02-login.md §8 updated. Screen 01 parked.
**Status**: ⚠️ Partial — discussion open; no code fixes.
**Notes**: Popup = `a11y-screen-01-review.canvas.tsx` (now Screen 02 content).

### 2026-07-09 — SCREEN-01 line-by-line a11y audit (discuss before fix)
**Requested by**: User — go to first screen, read all code, apply COMPLETE-ACCESSIBILITY-GUIDE line-by-line, discuss wrong items in popup.
**What was done**: Full read of bootstrap_screen / splash_body / app_bootstrap / offline_brand_logo. Found **W1–W5** (critical: offline/Retry UI unreachable because AppBootstrap swallows errors). Updated canvas + SCREEN-01-bootstrap.md §8. No code changes — awaiting Q1–Q6.
**Status**: ⚠️ Partial — discussion open; Screen 02 not started.
**Notes**: Popup = `a11y-screen-01-review.canvas.tsx`

### 2026-07-09 — Screen-by-screen a11y review started (SCREEN-01)
**Requested by**: User (@alex) — compare app vs COMPLETE-ACCESSIBILITY-GUIDE from Screen 1 → end; discuss in popup; write gaps into doc.
**What was done**: Re-checked Bootstrap/Splash live code vs guide; opened discussion canvas `a11y-screen-01-review.canvas.tsx`; appended session log + open findings to `device-audit/SCREEN-01-bootstrap.md`. No code fixes yet — awaiting Q1–Q6.
**Status**: ⚠️ Partial — Screen 01 in discussion; Scenarios B/C + Android pending; FIND-004 still incorrect in code.
**Notes**: Next = human answers popup questions, then Screen 02 Login.

### 2026-07-09 — Complete accessibility guide offline edition (full text, not links)
**Requested by**: User — single file with **actual downloaded content**, not link indexes or raw HTML.
**What was done**: Curated 15 clean markdown archives under `00-sources/offline/downloaded/` (Flutter, Android testing/principles, Apple VoiceOver/testing, W3C forms tutorials, Harvard TalkBack, Semantics API). Rebuilt `COMPLETE-ACCESSIBILITY-GUIDE.md` (~7,437 lines / ~317 KB): Part A = full project KB (37 sections); Part B = archived official text. Compile script skips re-download by default to preserve clean archives.
**Status**: ✅ Complete — `python3 scripts/compile-complete-accessibility-guide.py`

### 2026-07-09 — Complete accessibility guide (single file)
**Requested by**: User — consolidate all a11y docs into one file (not just fields).
**What was done**: Generated `.cursor/memory/accessibility-kb/COMPLETE-ACCESSIBILITY-GUIDE.md` (~5,115 lines) from KB, rules, scripts, Agent 16, device audits, copy snapshot, and production code (`accessible_text_field_semantics.dart`, `udaan_semantics.dart`). Updated KB README pointer.
**Status**: ✅ Complete — refresh by re-running compile script when KB changes.

### 2026-07-09 — Screen reader field value on refocus (build 40)
**Requested by**: User — announce existing text when refocusing every field (TalkBack/VoiceOver).
**What was done**: `AccessibleTextFieldSemantics` + `AccessibleStaticFieldSemantics`; wired into `UdaanLabeledField`, phone national field, help/profile/password, event registration text + subfields, library search, country picker search. Passwords stay obscured (label only). OTP row already had value.
**Verification**: `dart analyze lib` = 0 errors.
**Status**: ✅ Pushed to `main` — build 40.

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

### 2026-07-21 — Push Android 3.0.0+76; keep iOS 2.0.0+71
**Requested by**: User
**What was done**: Native YouTube player; Play package/signing; pubspec 3.0.0+76; iOS locked via xcconfig + CI --build-name/--build-number 2.0.0+71.
**Status**: Committing + pushing to GitHub
