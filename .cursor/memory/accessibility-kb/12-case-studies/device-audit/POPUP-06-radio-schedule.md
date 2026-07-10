# POPUP-06 — Radio schedule sheet

**Audit ID:** POPUP-06  
**Parent:** SCREEN-06 Live Radio  
**Status:** OPEN — code findings logged 2026-07-10; device CP pending  
**Trigger:** Upcoming segments card → `showRadioScheduleSheet`

**File:** `radio_udaan_app/lib/features/radio/radio_schedule_sheet.dart`

---

## Expected focus (code)

| # | Element | Pattern |
|---|---------|---------|
| 1 | Modal route / title | `{radio_schedule_title}` — risk of double speak (R6) |
| 2 | Day headers | Headers |
| 3 | Segment rows | `{radio_schedule_segment_semantics}` |
| 4 | Favorite per row | Add/remove + announce `{radio_favorite_added}` / `{radio_favorite_removed}` |
| 5 | Dismiss | **Close X** (`{close}`) + drag / scrub |

---

## Open findings (from SCREEN-06)

| ID | Severity | Finding |
|----|----------|---------|
| R5 | MED | **FIXED 2026-07-10** — Close X labeled `{close}` on schedule header |
| R6 | MED | Route `namesRoute` + header same title → possible double speak |
| R8 | LOW | Segment semantics may omit `category` shown in UI |

**Also:** Share opens app-owned sheet with Close X + Share + Copy (OS SharePlus still has no app X after Share).

**Strengths:** `BlockSemantics` / `UdaanModalSheet`; favorite announces on toggle; empty/error liveRegions present in sheet. Close X on schedule.

---

## Device checkpoints (pending)

| ID | Checkpoint | Status |
|----|------------|--------|
| CP-S1 | Title spoken once | PENDING |
| CP-S2 | Background Radio not in swipe path | PENDING |
| CP-S3 | Favorite announce on toggle | PENDING |
| CP-S4 | Dismiss returns focus to Upcoming | PENDING |

---

*Discuss with SCREEN-06 canvas; fix when human says go.*
