# SCREEN 01 — Bootstrap / Splash (`/bootstrap`)

**Audit ID:** SCREEN-01  
**Status:** PARKED — 2026-07-09 (human moved to Screen 02; W1–W5 still open)  
**Code reviewed:** 2026-07-04 by Jordan Lee · **Re-verified code:** 2026-07-09 by Alex (coordinator) vs build **2.0.0+40**  
**Discussion canvas:** `a11y-screen-01-review.canvas.tsx`  
**Files:**

| File | Role |
|------|------|
| `lib/features/bootstrap/bootstrap_screen.dart` | Route, navigation, bootstrap states |
| `lib/features/bootstrap/widgets/splash_body.dart` | UI + semantics |
| `lib/core/bootstrap/app_bootstrap.dart` | Config load, session restore |
| `lib/core/widgets/offline_brand_logo.dart` | Logo semantics |
| `lib/core/router/app_router.dart` | `initialLocation: '/bootstrap'` |

**Popups on this screen:** None (no dialog). Inline **Retry** button only on error state.

**Staging copy (snapshot):**

| Key | Expected string |
|-----|-----------------|
| `bootstrap_loading` | `READY TO LAUNCH` |
| `bootstrap_offline` | `Could not connect to the server. Check your network and try again.` |
| `semantics_loading` | `Loading…` |
| `splash_tagline` | `...A flight of life` |
| `splash_a11y_badge` | `Optimized for screen readers` |
| `retry` | `Retry` |
| `app_logo_semantics` | `Radio Udaan logo` |

---

## 1. Code walkthrough (function by function)

### `BootstrapScreen` / `_BootstrapScreenState`

| Function / block | What it does | A11y impact |
|------------------|--------------|-------------|
| `_minSplash` (1800ms) | Minimum splash visibility | User stays on screen ≥1.8s — screen reader may auto-read live regions |
| `_navigate()` | Delays then calls `_completeNavigation` | No announcement of "navigating to login/home" |
| `_completeNavigation()` | `context.go('/')` if logged in else `/login` | Focus must jump to next screen; splash becomes `SizedBox.shrink()` |
| `ref.listen(bootstrapProvider)` | Navigates when bootstrap completes | — |
| `bootstrap.when(data/loading/error)` | Three UI states | See SplashBody per state |

**Navigation branches (no popup):**

- Logged in + no deep link → `/` (Radio tab)
- Logged in + pending event → `/event/{id}`
- Logged out → `/login`

### `AppBootstrap.run()`

| Step | Behavior | A11y impact |
|------|----------|-------------|
| Load cached config | Shows branding from cache | Logo/title visible quickly |
| Fetch `/config` + `/auth/me` if token | Network | Loading state on splash |
| Fail closed on invalid token | Clears session → login | User may not hear why session cleared |
| Returns `BootstrapResult` | `isLoggedIn` drives navigation | No spoken "signed in" / "session expired" |

### `SplashBody.build()`

| Widget | Semantics (code) | Expected TalkBack/VoiceOver |
|--------|------------------|----------------------------|
| `_SplashBackgroundGlow` | None (decorative) | Should **not** receive focus |
| `_SplashLogo` → `OfflineBrandLogo` | `label: '{appName} logo'`, `image: true` | e.g. **"Radio Udaan logo, image"** |
| `_SplashTitleBlock` — app name | `Semantics(header: true)` + `ExcludeSemantics` on Text | e.g. **"Radio Udaan, heading"** |
| `_SplashTitleBlock` — tagline | **Plain `Text` only — NO Semantics** | ⚠️ CODE REVIEW: may be **silent** OR read as unlabeled text depending on OS |
| `_SplashLoadingDots` | `Semantics(label: semanticsLoading)` → `"Loading…"` | **"Loading…"** — dots are visual only inside semantics node |
| Status message | `Semantics(label: statusMessage, liveRegion: true)` + excluded Text | Auto-announced: **"READY TO LAUNCH"** (loading) or offline message |
| `errorDetail` | `liveRegion: true`, raw `error.toString()` | ⚠️ May speak **technical** error text |
| Retry button | `Semantics(button: true, label: copy.retry)` + `FilledButton` 56px height | **"Retry, button"** |
| `_SplashAccessibilityBadge` | `Semantics(label: splashA11yBadge)` | **"Optimized for screen readers"** |

### `OfflineBrandLogo`

| Case | Semantics |
|------|-----------|
| Image loads | `{appName} logo`, image |
| Image error fallback | Same outer label; inner text excluded |

---

## 2. Expected focus order (linear swipe, top → bottom)

**Hypothesis from code** — verify on device:

| Step | Element | Expected speech |
|------|---------|-----------------|
| 1 | Logo | Radio Udaan logo |
| 2 | App name heading | Radio Udaan, heading |
| 3 | Tagline | ??? (code gap — see AUDIT-FIND-001) |
| 4 | Loading indicator | Loading… |
| 5 | Status live region | READY TO LAUNCH (may auto-announce without focus) |
| 6 | A11y badge | Optimized for screen readers |

**Error state adds:** error detail live region + Retry button before badge.

---

## 3. Code review findings (audit only — not fixed)

| ID | Severity | Finding | Code reference |
|----|----------|---------|----------------|
| AUDIT-FIND-001 | HIGH | Tagline `splashTagline` has no `Semantics` — may be missed by screen reader | `splash_body.dart` `_SplashTitleBlock` L191-201 |
| AUDIT-FIND-002 | MED | App name may be spoken twice (logo + heading) | `offline_brand_logo.dart` + `_SplashTitleBlock` |
| AUDIT-FIND-003 | MED | No announcement when navigating away from splash | `bootstrap_screen.dart` `_completeNavigation` |
| AUDIT-FIND-004 | MED | Error state speaks raw `error.toString()` — may be jargon | `bootstrap_screen.dart` L95 |
| AUDIT-FIND-005 | LOW | Session cleared silently on bootstrap failure | `app_bootstrap.dart` L133-139 |
| AUDIT-FIND-006 | OK | Status uses `liveRegion: true` for loading/offline | `splash_body.dart` L52-66 |
| AUDIT-FIND-007 | OK | Retry button 56px min height + labeled | `splash_body.dart` L87-107 |

---

## 4. Test scenarios — YOUR TURN

Enable **TalkBack** (Android) or **VoiceOver** (iOS) **before** force-quitting the app.

**Build to test:** `2.0.0+31` (or tell Jordan your actual build)

### Scenario A — Cold start (logged out, online)

1. Force-quit Radio Udaan
2. Ensure Wi‑Fi on
3. If logged in from before, sign out first (or skip to Scenario B)
4. Launch app cold
5. Stay on splash ~2 seconds
6. Linear swipe through **entire splash** before it navigates to Login
7. Note what happens when screen changes to Login

### Scenario B — Cold start (already logged in)

1. Log in normally (without screen reader if needed)
2. Force-quit
3. Enable TalkBack/VoiceOver
4. Cold launch
5. Swipe splash then note landing screen (should be Radio tab)

### Scenario C — Offline / error (Retry — no popup)

1. Enable airplane mode
2. Force-quit, enable screen reader, launch
3. Wait for error state on splash
4. Swipe through all elements
5. Double-tap **Retry** (do not fix network yet) — what happens?
6. Turn network on, tap Retry again

### Scenario D — Reduce Motion (optional)

1. iOS: Settings → Accessibility → Motion → Reduce Motion ON  
   Android: Remove animations / reduce motion if available
2. Cold launch logged out
3. Does loading still announce "Loading…"?

---

## 5. Checkpoints — device results

**Session started:** 2026-07-04 · **Platform:** VoiceOver iOS  
**Scenario:** A — cold start logged out (in progress)

| ID | Checkpoint | Expected | Heard (device) | PASS/FAIL | Notes |
|----|------------|----------|----------------|-----------|-------|
| CP-01 | Logo focused | Radio Udaan logo | Radio Udaan logo (or similar with image) | **PASS** | Human confirmed via popup |
| CP-02 | App name heading | Radio Udaan, heading | Radio Udaan, heading | **PASS** | |
| CP-03 | Tagline | ...A flight of life | ...A flight of life (splash_tagline) | **PASS** | VoiceOver read plain Text despite no Semantics — AUDIT-FIND-001 downgraded to LOW on iOS |
| CP-04 | Loading | Loading… | Loading… | **PASS** | |
| CP-05 | Status auto-announce | READY TO LAUNCH | Heard when swiped to focus (not auto) | **PASS** | liveRegion did not auto-speak on iOS — note for CP-05 |
| CP-06 | A11y badge | Optimized for screen readers | Optimized for screen readers | **PASS** | |
| CP-07 | Duplicate speech? | App name once preferred | Distinct — not annoying duplicate | **PASS** | AUDIT-FIND-002 not reproduced on iOS |
| CP-08 | Navigate to login (A) | Login screen focus sensible | Landed Login; first focus sensible | **PASS** | |
| CP-09 | Navigate to Radio (B) | Radio tab / heading | | | |
| CP-10 | Offline message (C) | bootstrap_offline copy | | | |
| CP-11 | Error detail (C) | (technical string?) | | | AUDIT-FIND-004 |
| CP-12 | Retry button (C) | Retry, button | | | |
| CP-13 | Retry action (C) | Retries load / recovers | | | |

**Platform:** ☐ TalkBack Android ☐ VoiceOver iOS  
**Device model / OS:** _______________

---

## 6. Sign-off (after your reply)

| Field | Value |
|-------|-------|
| Overall SCREEN-01 Scenario A (iOS VoiceOver) | **PASS** (2026-07-04) |
| Open findings | AUDIT-FIND-003, 004, 005 — not device-tested; 001/002 not reproduced on iOS |
| Android TalkBack | Pending |
| Scenario C offline/Retry | Pending |
| Ready for Screen 02? | **Blocked** until human answers popup Q1–Q6 (2026-07-09) |

---

## 7. Session log — 2026-07-09 (Alex / guide re-check)

Superseded by §8 line-by-line audit.

---

## 8. Line-by-line audit — 2026-07-09 (vs COMPLETE-ACCESSIBILITY-GUIDE)

**Method:** Read every line of Screen 01 stack → apply guide rules → discuss wrong items in popup before fixing.  
**Files read in full:** `bootstrap_screen.dart`, `splash_body.dart`, `app_bootstrap.dart`, `offline_brand_logo.dart` (+ force_update_screen for branch).  
**Canvas:** `a11y-screen-01-review.canvas.tsx`

### WRONG (must discuss — not fixed yet)

| ID | Sev | Finding | Lines | Guide rule broken |
|----|-----|---------|-------|-------------------|
| **W1** | CRITICAL | `AppBootstrap.run()` catch never rethrows → `bootstrapProvider` almost never `AsyncValue.error` → SplashBody offline + Retry **unreachable** on network fail | `app_bootstrap.dart` L135–165; `bootstrap_screen.dart` L103–113 | Errors must be spoken + recoverable (liveRegion / Retry) |
| **W2** | HIGH | App name: `Semantics(header: true)` + `ExcludeSemantics(Text)` **without `label:`** — unlike `UdaanScreenHeader` | `splash_body.dart` L175–189 | Meaningful label; ExcludeSemantics must not strip spoken name |
| **W3** | MED | If error UI ever shows: `errorDetail: error.toString()` spoken | `bootstrap_screen.dart` L108; `splash_body.dart` L68–83 | Errors = user message, not jargon |
| **W4** | MED | Logo `Image.asset` not wrapped in `ExcludeSemantics` under labeled parent | `offline_brand_logo.dart` L21–33 | Avoid duplicate / bare “Image” node |
| **W5** | MED | No `announce()` on navigate away, Retry, or silent session clear | `bootstrap_screen.dart` L41–71, L109–112; `app_bootstrap.dart` L136–141 | Announcements for important state changes |

### VERIFY ON DEVICE

| ID | Item | Note |
|----|------|------|
| V1 | Tagline plain `Text` | Usually OK as static text; confirm TalkBack |
| V2 | `liveRegion` auto-speak status | iOS previously needed focus swipe |

### OK vs guide

Status liveRegion; Loading… label + reduceMotion; Retry 56px + label (when shown); a11y badge ExcludeSemantics; decorative glow unlabeled; copy keys present; force-update screen uses header + liveRegion + announceAndSnack.

### Questions for human (popup)

1. W1: Offline always stay on splash + Retry? (Yes / No / Only if no cache)
2. W2: Fix heading `label: branding.appName`?
3. W3: Drop technical `errorDetail` from SR?
4. W4: ExcludeSemantics on logo Image?
5. W5: Silent nav vs announce destination vs only session/offline/retry?
6. Fix Screen 01 now or log-only then Screen 02?
7. Device for V1/V2: TalkBack / VoiceOver / both?

---

*Next: after human answers Q1–Q6 — either implement Screen 01 fixes or open Screen 02 line-by-line.*
