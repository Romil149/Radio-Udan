# POPUP 02 — Country picker (login phone field)

**Status:** CODE FIXED 2026-07-09 — awaiting device re-test  
**Parent screen:** SCREEN-02 Login  
**Trigger:** Double-tap country code button  
**Code:** `accessible_country_picker_sheet.dart`, `UdaanModalSheet`  

**2026-07-09 code fixes:** full-height sheet, opaque barrier, `BlockSemantics` on modal, search FocusNode + Editing announce. Re-run POP-01–07 on device before PASS.

---

## Expected (code + copy + guide)

| Order | Element | Expected speech | Copy / code |
|-------|---------|-----------------|-------------|
| 0 | Modal opens | Route/modal context (optional on iOS) | `UdaanModalSheet` `namesRoute: true` — **title param unused in build** |
| 1 | **First stop in modal** | **Select country code, heading** | `phone_country_picker_title` |
| 2 | Search | Search country, text field | `phone_country_search_hint` |
| 3 | Favorites header | Favorites, heading | `phone_country_favorites` |
| 4 | India (favorite) | Country code, India, plus 91. Double tap to change country. | `phone_country_code_semantics` |
| 5+ | A–Z countries | Same pattern per country | `_CountryTile` |

**Guide rules:**

- Modal must trap focus — **no login screen stops** while sheet open (Apple HIG / Flutter `scopesRoute`)
- Heading before list (rotor Headings)
- Search field one stop (`ExcludeSemantics` on inner TextField) ✅ in code
- Country rows: button + full semantics label, 56px min height ✅ in code

---

## Device results (2026-07-04)

| Step | You heard / saw | Guide verdict |
|------|-----------------|---------------|
| Open | Double-tap country → sheet opens | OK |
| Swipe 1 | **"Srim"** — login **logo visible** in gap above sheet (~15% top) | **FAIL** — focus appears on **login content behind modal**, not modal first |
| Swipe 2 | Select country code, **heading** | **PASS** — matches `phone_country_picker_title` |
| Swipe 3 | Search country, text field, double tap to edit | **PASS** — label matches copy |
| Double-tap search | Re-speaks *"Search country, text field…"* — **but letter keys heard** on finger explore (keyboard open) | **PASS (partial)** — typing possible; **confusing** re-announce (**FIND-039 MED**) |
| Swipe 4 | **Favorites** (heading) | **PASS** — `phone_country_favorites` |
| Swipe 5 | Country code, India, plus 91… **button** | **PASS** — `phone_country_code_semantics` on favorite tile |
| Double-tap India | Popup **closes**; country selected | **PASS** — selection works |
| Swipe 6–8 | **Afghanistan**, **Albania**, … (A–Z list) | **PASS** — full list reachable after favorites |

**Popup sign-off (iOS VoiceOver):** **FAIL overall** — focus leak at open (FIND-035/036); list/search/selection OK.

---

## Device checklist (complete)

| ID | Test | Result |
|----|------|--------|
| POP-01 | Open from country button | PASS |
| POP-02 | First focus not login/logo behind sheet | **FAIL** (FIND-035/036) |
| POP-03 | Heading + search labeled | PASS |
| POP-04 | Search typable (keyboard) | PASS (partial — FIND-039 re-announce) |
| POP-05 | Favorites + India | PASS |
| POP-06 | A–Z countries swipable | PASS |
| POP-07 | Select country closes sheet | PASS |

---

## Findings

| ID | Severity | Finding |
|----|----------|---------|
| AUDIT-FIND-035 | **HIGH** | Partial bottom sheet (~85%) — login logo/content still visible **and in VoiceOver path** before modal heading |
| AUDIT-FIND-036 | **HIGH** | Modal focus order wrong — first stop should be **Select country code** heading, not background/login element |
| AUDIT-FIND-037 | MED | `UdaanModalSheet` accepts `title` but never sets route/modal **label** — may not announce on open |
| AUDIT-FIND-038 | MED | Sheet `initialChildSize: 0.85` — gap at top confuses blind + sighted users (logo bleed-through) |
| AUDIT-FIND-039 | **MED** | Search double-tap re-speaks label (confusing) but **keyboard does open** — letter keys confirmed on device | Improve: focus hint or `sendAnnouncement` when edit mode starts |

**Note on "Srim":** Likely mis-read of logo/app name or stray node at top of screen — confirm on next pass. Visual = login logo in gap strongly suggests **semantics leak**, not modal content.

---

## Fix direction (dev phase)

1. Trap focus: full-height sheet, or `barrierColor` + semantics exclusion on route below when sheet open.
2. Announce on open: `sendAnnouncement(copy.phoneCountryPickerTitle)` or fix `UdaanModalSheet` to apply `title` to route semantics.
3. Move focus to search or heading on open (Flutter `FocusScope` / first focusable in modal).

---

*Continue popup audit: swipe after Search country — report next 2–3 stops.*
