# SCREEN 06 — Live Radio tab (main shell)

**Audit ID:** SCREEN-06  
**Status:** DISCUSSION — line-by-line code audit 2026-07-10 (Maya); discuss before fix  
**Route:** `/` — tab index 0 (Radio) after auth  
**Discussion canvas:** `a11y-screen-01-review.canvas.tsx`  
**Related sheet:** [POPUP-06-radio-schedule.md](./POPUP-06-radio-schedule.md)

**Files:**

| File | Role |
|------|------|
| `lib/features/radio/radio_tab.dart` | Hero play card, schedule, share, favorite |
| `lib/features/radio/radio_schedule_sheet.dart` | Schedule modal (POPUP-06) |
| `lib/features/shell/main_shell_screen.dart` | IndexedStack + bottom NavigationBar |
| `lib/core/widgets/main_tab_app_bar.dart` | Logo + tab title |
| `lib/features/radio/widgets/radio_volume_control.dart` | Volume slider (if enabled in config) |

---

## Expected focus order (code — 2026-07-10)

| # | Element | Expected speech (copy keys / pattern) | Evidence |
|---|---------|----------------------------------------|----------|
| 1 | App bar logo | `{app_logo_semantics}` | `app_bar_brand_logo.dart` |
| 2 | App bar title | `{tab_radio}` heading — “Live Radio” | `radio_tab.dart` + `MainTabAppBar` |
| 3 | Hero play/stop (merged) | `{radio_play}` / `{radio_stop}` / `{radio_connecting}` + title + hosts | `radioPlayButtonSemantics` |
| 4 | Playback error (if any) | Error string, liveRegion | `radio_tab.dart` ~L141–156 |
| 5 | Volume (if `live.showVolume`) | `{radio_volume}` + percent; change → `{radio_volume_announce}` | `radio_volume_control.dart` |
| 6 | Upcoming | `{radio_upcoming_segments}` + next + view schedule | `_UpcomingSegmentsCard` |
| 7 | Share | `{radio_share_live}` / share label | `_LiveActionsRow` |
| 8 | Favorite | add/remove label; off-air disabled | `_LiveActionsRow` |
| 9+ | Bottom tabs | Live Radio selected + Library / Events / About / More | `main_shell_screen.dart` |

**Risk:** `IndexedStack` — inactive tabs in swipe path (R9 / CP-08, CP-10).

---

## Open findings (code audit 2026-07-10)

| ID | Severity | Guide / prior | Evidence | Proposed fix |
|----|----------|---------------|----------|--------------|
| **R1** | **HIGH** | Journey 4 — hear play/stop change | `radio_tab.dart` L109–115 empty `ref.listen`; unused `{radio_playing}` / `{radio_stopped}` | `announce()` on status change (and/or hero `liveRegion`) |
| **R2** | **HIGH** | Errors: liveRegion **and** announce | Error UI liveRegion only; listen ignores errors | `announce` when `errorMessage` becomes non-null |
| **R3** | **MED** | **FIND-043** duplicate swipe hint | `radio_volume_control.dart` L119 + `radio_volume_slider_hint` | Clear or shorten hint (no swipe-up/down wording) |
| **R4** | **MED** | Favorite success spoken | Main toggle L533–540 no announce; sheet announces | Same announce as schedule sheet |
| **R5** | **MED** | Sheet Close control | **FIXED 2026-07-10** — Close X (`close` copy) on schedule header | Done |
| **R6** | **MED** | Modal title once | Route `namesRoute` + header same title | Route **or** header, not both |
| **R7** | **MED** | Semantics.onTap with ExcludeSemantics | Upcoming / Share / Favorite lack `onTap` (hero has it) | Wire `onTap: onPressed` |
| **R8** | **LOW** | Segment completeness | Schedule semantics may omit `category` | Append category when present |
| **R9** | **LOW** | IndexedStack leak | `main_shell_screen.dart` IndexedStack | Device-verify; ExcludeSemantics if leak |
| **R10** | **LOW** | Disabled favorite clarity | Off-air: disabled, label still “add” | Hide or “Favorite unavailable…” |

**Strengths:** Merged hero + ExcludeSemantics; volume onIncrease/Decrease + percent announce; Share fail via announceAndSnack; 56px Share/Favorite; schedule BlockSemantics + favorite announces.

---

## Prior FIND-043 / FIND-044

| ID | Status | Notes |
|----|--------|-------|
| **AUDIT-FIND-043** | **Still open (code)** = **R3** | Hint still duplicates iOS adjustable/swipe speech |
| **AUDIT-FIND-044** | **Fixed in code · device recheck** | `radioPlayButtonSemantics` always includes show title; re-run CP-03 |

---

## Input & keyboard inventory

**No text fields** on Live Radio — no on-screen keyboard.

| Control | Type | VoiceOver action | Guide |
|---------|------|------------------|-------|
| Hero | Button | Double-tap play/stop | Audio player — state in label + **announce on change (R1)** |
| Volume | Adjustable | Swipe up/down; hear % | Volume spoken on change |
| Upcoming | Button | → POPUP-06 | Bottom sheet |
| Share / Favorite | Buttons | Double-tap | Favorite announce (R4) |
| Bottom tabs | Tab bar | Switch tab | 5-tab nav |

---

## Device checkpoints

| ID | Checkpoint | Expected | Heard | PASS/FAIL | Notes |
|----|------------|----------|-------|-----------|-------|
| CP-01 | First focus (logo) | Radio Udaan logo | Radio Udaan logo image | **PASS** | 2026-07-05 |
| CP-02 | App bar title | Live Radio, heading | Live Radio heading | **PASS** | |
| CP-03 | Hero play card | Play + **show title** + hosts | Hosts heard; title unclear | **PASS (partial)** | Recheck FIND-044 |
| CP-04 | Volume slider | Volume, N%, adjustable | Hint **twice** | **PASS (partial)** | FIND-043 / R3 |
| CP-05 | Upcoming | Upcoming + segment, button | PASS | **PASS** | |
| CP-06 | Share | Share live | PASS | **PASS** | System sheet scrub Z |
| CP-07 | Favorite | Add to favorites | PASS | **PASS** | Label only; announce R4 untested |
| CP-08 | Tab bar | Live Radio selected + others | — | **PENDING** | R9 |
| CP-09 | Play action | Double-tap → play/stop + **hear state** | — | **PENDING** | Validates R1 |
| CP-10 | End of screen | No inactive-tab leak | — | **PENDING** | R9 |
| CP-11 | Volume swipe up | “Volume, N percent” | — | **PENDING** | |
| CP-12 | Volume swipe down | Announcement | — | **PENDING** | |
| CP-13 | Volume limits | 0% / 100% | — | **PENDING** | |
| CP-14 | Schedule sheet | POPUP-06 | — | **PENDING** | See POPUP-06 |

---

## Questions for human (before fix)

1. Play/stop: prefer **`announce()`** with `{radio_playing}` / `{radio_stopped}` / `{radio_connecting}`, or **`liveRegion` on hero**, or both?
2. FIND-043 / R3: **remove** volume hint entirely, or short non-gesture hint (e.g. “ten percent steps” only)?
3. Schedule sheet: require visible **Close**, or scrub/drag enough?
4. Main-tab favorite: always announce add/remove (parity with sheet)?
5. On device after Play: any state change **without** re-swiping hero? (R1)
6. Schedule open: title once or twice? Background Radio out of swipe path?

---

## Screen 06 — partial sign-off (2026-07-05)

**Body content (logo → favorite): PASS with minor FIND-043/044.**  
**Still needed:** CP-08–14; code blockers **R1–R2** before a11y ship.

## Ready for ship? **No**

Silent play/stop & errors (R1/R2), FIND-043 still in code, main favorite silence (R4), device CP-08–14 / POPUP-06 incomplete.

---

## Session log — 2026-07-10 (line-by-line code)

**Agents:** Alex → Maya (code audit, no edits).  
**Method:** Live Radio tree vs COMPLETE guide Audio player / Journey 4 / sheets; prior device CPs.  
**Outcome:** Open **R1–R10**; POPUP-06 stub created; canvas updated for discussion. **No code fixes** until human answers Q1–Q6 or says go.
