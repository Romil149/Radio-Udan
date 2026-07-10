# SCREEN 07 — Events (list + registration fields)

**Audit ID:** SCREEN-07  
**Status:** DISCUSSION — code audit 2026-07-10 (Maya); discuss before fix  
**Routes:** Events tab → event card → registration (no separate detail screen)  
**Discussion canvas:** `a11y-screen-01-review.canvas.tsx`

**Files:**

| File | Role |
|------|------|
| `lib/features/events/events_tab.dart` | List, empty/error |
| `lib/features/events/widgets/event_card.dart` | Card CTA semantics |
| `lib/features/events/event_registration_screen.dart` | Dynamic Forminator fields |
| `lib/features/events/widgets/registration_form_styles.dart` | Choice tiles, labels |
| `lib/features/events/models/form_schema.dart` | Field types |

---

## Field-type inventory (vs guide)

| Type | Checklist | Notes |
|------|-----------|-------|
| text / textarea / email / url / number | **PASS** | Label outside + required; AccessibleTextFieldSemantics; Editing on focus |
| address (flat) | **PASS** | Multiline + hint |
| phone | **PARTIAL** | Phone keyboard; not UdaanPhoneField / country picker |
| name/address **subfields** | **PARTIAL** | Required OK; no focusNode → no Editing |
| Account name/phone/email | **PASS (updated)** | Prefill from account; **editable** (lock removed 2026-07-10) |
| select / radio / rating | **PASS** | Choice tiles 56px |
| checkbox multi | **PARTIAL** | Tiles OK; group “Selected:” unused |
| consent (single checkbox + HTML) | **FAIL** | **E1** — HTML inside ExcludeSemantics |
| info HTML | **PASS** | AccessibleHtmlContent (prior fix) |
| date / time / datetime | **PARTIAL** | Labeled picker; system dialogs; helpText may omit required |
| upload | **PARTIAL** | Progress % + filename announce; client rejects silent (**E4**); some 48px |
| slider | **FAIL/PARTIAL** | Raw Slider; no volume-style announce (**E8**) |
| Page chrome | **PARTIAL** | Next/Prev announce; first paint silent (**E6**) |

---

## Open findings

| ID | Sev | Issue | Proposed fix |
|----|-----|-------|--------------|
| **E1** | **CRITICAL** | Consent HTML silenced under ExcludeSemantics | Speak HTML or plain summary in checkbox label |
| **E2** | **HIGH** | Submit API error: liveRegion only, no announce | `_announce` on catch |
| **E3** | **HIGH** | Submit success: liveRegion only | `_announce` success + reference |
| **E4** | **HIGH** | Upload client rejects (size/ext/count) silent | Announce `_uploadErrors` strings |
| **E5** | **HIGH** | Event card omits “Register For…” + summary | Use `eventRegisterForSemantics` + optional summary |
| **E6** | **MED** | First page not announced on open | Post-frame page announce |
| **E7** | **MED** | Some upload/retry targets 48px not 56 | Use `a11yMinTapTarget` |
| **E8** | **MED** | Slider no a11y value/announce | Match radio volume pattern |
| **E9** | **MED** | DecDecoration errors inside ExcludeSemantics | Outer liveRegion or semantics |
| **E10** | **MED** | Subfields no Editing announce | Pass FocusNodes |
| **E11** | **MED** | Multi-file count ExcludeSemantics | Append to upload label |
| **E12–E14** | **LOW** | Retry hit box, picker helpText required, EmptyState 56 | Polish |

### Prior FORMS-AUDIT-MASTER status

| Prior | Status |
|-------|--------|
| ERG-REG-VAL-001 | **Fixed** — announce + scroll |
| ERG-REG-INFO-001 (info) | **Fixed** |
| ERG-REG-PAGE-001 | **Fixed** (Next/Prev) |
| ERG-REG-PAGE-003 | **Open** → E6 |
| ERG-REG-UPLOAD-001 | **Partial** → E4 |
| ERG-EVENTS-001 | **Partial** → E5 |

---

## What already PASSes

Persistent labels + required spoken; text fields ExcludeSemantics + Editing; locked account fields; choice tiles 56px; validation announce+scroll; page Next/Prev announce; upload progress milestones + file selected; info HTML; deep-link opening announce.

---

## Questions for human

1. Consent (E1): spoken HTML in tree, or short plain summary in checkbox label?
2. Event card (E5): always “Register For {title}”; include summary (full / truncated / never)?
3. Upload progress: keep 25% steps or denser?
4. Slider: match Radio volume, or leave rare Material default?
5. Success/error: require sendAnnouncement in addition to liveRegion?
6. Device QA first: multi-page, upload, or date pickers?

---

## Ready for ship? **No**

Blockers: E1–E5 + no device QA.

---

## Session log — 2026-07-10

**Agents:** Alex → Maya (code audit, no edits).  
**Outcome:** SCREEN-07 + canvas; awaiting Q1–Q6 or “fix Events E…”.
