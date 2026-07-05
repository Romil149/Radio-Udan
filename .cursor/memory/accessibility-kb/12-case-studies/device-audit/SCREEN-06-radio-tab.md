# SCREEN 06 — Live Radio tab (main shell)

**Audit ID:** SCREEN-06  
**Status:** IN PROGRESS  
**Route:** `/` — tab index 0 (Radio)  
**Platform:** VoiceOver iOS

**Files:**

| File | Role |
|------|------|
| `lib/features/radio/radio_tab.dart` | Hero play card, schedule, share, favorite |
| `lib/features/shell/main_shell_screen.dart` | IndexedStack + bottom NavigationBar |
| `lib/core/widgets/main_tab_app_bar.dart` | Logo + tab title |
| `lib/features/radio/widgets/radio_volume_control.dart` | Volume slider (if enabled in config) |

---

## Expected focus order (code)

| # | Element | Expected speech (pattern) |
|---|---------|---------------------------|
| 1 | App bar logo | `{app_name} logo` — `app_logo_semantics` |
| 2 | Screen title | Live Radio, heading — `tab_radio` |
| 3 | Hero card | Play Live Stream… + show title + hosts — `radioPlayButtonSemantics` |
| 4 | Volume (if shown) | Volume slider + percent |
| 5 | Upcoming segments | Upcoming segments + next show — opens schedule sheet |
| 6 | Share | Share label button |
| 7 | Favorite | Favorite / add favorite button |
| 8+ | Bottom tabs | Live Radio tab selected; Library; Events; About; More |

**Risk:** `IndexedStack` keeps all tabs alive — inactive tabs may appear in swipe path (verify).

---

## Input & keyboard inventory (code vs guide)

**Live Radio tab has no text fields** — nothing opens the on-screen keyboard on this screen.

| Control | Type | Keyboard? | VoiceOver action | Guide pattern |
|---------|------|-----------|------------------|---------------|
| Hero play card | Button | No | Double-tap play/stop | Audio player — state in label |
| **Volume** | **Adjustable slider** | No typing; optional **arrow keys** when focused | **Swipe up/down** to change; should announce new % | Audio player — volume spoken on change |
| Upcoming segments | Button | No | Double-tap → schedule sheet | Bottom sheet |
| Share / Favorite | Buttons | No | Double-tap | — |
| Bottom tabs | Tab bar | No | Double-tap switch tab | 5-tab nav |

**Schedule sheet** (from Upcoming): list + favorite buttons only — **no search, no TextField**.

Per `patterns-library.md` **Audio player** checklist:
- ☐ Play reachable quickly — CP-09
- ☐ State in label — CP-03
- ☐ **Volume changes spoken** — CP-11 below
- ☐ Slider adjustable without sighted drag — CP-11

Known code issue: **FIND-043** — `radio_volume_slider_hint` repeats iOS’s built-in “swipe up/down” instructions.

---

## Device checkpoints (input / adjustable)

| ID | Checkpoint | Expected | Heard | PASS/FAIL | Notes |
|----|------------|----------|-------|-----------|-------|
| CP-01 | First focus (logo) | Radio Udaan logo | **Heard:** Radio Udaan logo image (+ udaan) | **PASS** | iOS adds "image" trait — OK |
| CP-02 | App bar title | Live Radio, heading | **Heard:** Live Radio heading | **PASS** | `tab_radio` |
| CP-03 | Hero play card | Play Live Stream + show + hosts, one button | **Heard:** Play Live stream with RJ Karan & RJ Meera | **PASS (partial)** | One merged stop ✅; confirm full label includes **show title** between action and hosts |
| CP-04 | Volume slider | Volume, N percent, adjustable | **Heard:** volume 40% adjustable + swipe hint **twice** | **PASS (partial)** | Slider works; **FIND-043** duplicate swipe instructions |
| CP-05 | Upcoming / schedule | Upcoming Shows + segment, button | **Heard:** Upcoming Shows + show name, button | **PASS** | `radio_upcoming_segments` |
| CP-06 | Share | Share live, button | **Heard:** Share button; double-tap opens Apple share sheet | **PASS** | Dismiss: no Close in swipe path; **two-finger scrub (Z)** works — expected for iOS system sheet |
| CP-07 | Favorite | Add to favorites, button | **Heard:** Add to favourite button | **PASS** | `radio_favorite_add` |
| CP-08 | Tab bar | Live Radio tab selected + other tabs | **Not reported yet** | **PENDING** | Continue swiping |
| CP-09 | Play action | Double-tap hero → plays/stops | **Not tested yet** | **PENDING** | |
| CP-10 | End of screen | No extra hidden fields after tabs | **Not reported yet** | **PENDING** | |
| CP-11 | Volume swipe up | Level rises; hears **“Volume, N percent”** | **Not reported yet** | **PENDING** | Not keyboard — VoiceOver swipe up on slider |
| CP-12 | Volume swipe down | Level falls; announcement | **Not reported yet** | **PENDING** | |
| CP-13 | Volume limits | Stops at 0% and 100% | **Not reported yet** | **PENDING** | |
| CP-14 | Schedule sheet | Upcoming → list only, no text fields | **Not reported yet** | **PENDING** | Dismiss: scrub Z |

---

## Findings (Screen 06)

| ID | Severity | Finding |
|----|----------|---------|
| AUDIT-FIND-043 | MED | Volume slider — user heard adjustable / swipe instructions **twice** (hint + iOS default) |
| AUDIT-FIND-044 | LOW | Hero play label — verify show **title** spoken separately from hosts (user reported hosts only) |

---

## Screen 06 — partial sign-off (2026-07-05)

**Body content (logo → favorite): PASS with minor FIND-043/044.**  
**Still needed:** CP-08 tabs, CP-09 play/stop, **CP-11–14 volume + schedule input audit**.
