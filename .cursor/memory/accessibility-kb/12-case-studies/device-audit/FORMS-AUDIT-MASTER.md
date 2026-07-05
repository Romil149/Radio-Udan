# Forms & keyboard fields — master accessibility audit

**Date:** 2026-07-05  
**Requested by:** User (urgent, all screens)  
**Method:** Code audit vs `.cursor/memory/accessibility-kb/05-ui-patterns/patterns-library.md` + `.cursor/rules/accessibility-blind-users.mdc`  
**Agents:** Auth, Events, More/Library (Auto model)  
**Device QA:** Partial — Login/OTP/Country picker only; Events/More/Register **NEEDS DEVICE QA**

---

## Executive summary

| Area | Screens | Code verdict | Device tested? |
|------|---------|--------------|----------------|
| **Auth — Login** | Login | **FAIL** | ✅ SCREEN-02 |
| **Auth — Register** | Register | **FAIL** (inherits login phone/password) | ❌ |
| **Auth — Phone login** | Phone login | **FAIL** (inherits phone) | ❌ (skipped) |
| **Auth — OTP** | OTP verify | **PASS** (PIN row) / errors untested | ✅ SCREEN-04 partial |
| **Auth — Country picker** | Modal | **FAIL** (focus leak) | ✅ POPUP-02 |
| **Auth — Forgot / Reset / Verify email** | Password recovery | **FAIL** (errors, toggles, targets) | ❌ |
| **Events — list** | Events tab | **Partial** (card context thin) | ❌ |
| **Events — registration** | Dynamic form | **FAIL** (validation announce, page nav, info HTML) | ❌ |
| **More — Edit profile** | Profile | **Partial** | ❌ |
| **More — Change password** | Password | **Partial** | ❌ |
| **More — Help contact** | Contact form | **FAIL** (duplicate field speech) | ❌ |
| **More — Settings** | Toggles/slider | **Partial** (duplicate hint, silent auto-save) | ❌ |
| **Library — Search** | Search field | **PASS** | ❌ |
| **Radio — Volume** | Slider only | **PASS** (FIND-043 duplicate hint) | ✅ SCREEN-06 |

**Release blockers (fix before blind-user sign-off): 12**

---

## 🔴 Critical / release blockers

| ID | Screen | Issue | Fix direction |
|----|--------|-------|---------------|
| **AUDIT-FIND-033** | Login, Register, Phone, Forgot | Phone national `TextField` not wrapped in `ExcludeSemantics` → **double VoiceOver stop** (label + placeholder) | `udaan_phone_field.dart` ~L238 |
| **AUDIT-FIND-034** | Login, Register, Reset, Change pwd | Password show/hide **inside** excluded `TextField` → **not in VoiceOver path** | Move toggle outside subtree in `UdaanLabeledField` |
| **AUDIT-FIND-024** | All auth + profile + contact | Validation errors use `liveRegion` only — **no `sendAnnouncement`** on submit fail | Add announce + scroll to first error |
| **AUDIT-FIND-032** | Login, Register, Phone | Autofill/paste can double country code (`+91911234567890`) | `setFromRawInput` on national change |
| **AUDIT-FIND-035/036** | Country picker | Focus leaks to login **behind** 85% sheet | Full-height sheet or exclude route below |
| **ERG-REG-VAL-001** | Event registration | Next/Submit fail: scrolls field but **does not announce** validation | `_announce()` on fail in `event_registration_screen.dart` |
| **ERG-REG-INFO-001** | Event registration | Info HTML fields wrapped in **`ExcludeSemantics`** — instructions **silent** | Remove exclude or add spoken summary |
| **A11Y-MORE-001** | Help contact | Same phone bug: `TextField` without `ExcludeSemantics` | Mirror `UdaanLabeledField` |
| **AUDIT-FIND-045** | Verify email | “Sent to {email}” wrapped in `ExcludeSemantics` — destination hidden | Remove exclude |

---

## 🟠 High / medium (fix before release preferred)

| ID | Screen | Issue |
|----|--------|-------|
| **ERG-REG-PAGE-001** | Event registration | Page change not announced when Forminator page has title |
| **ERG-REG-PAGE-003** | Event registration | “Page 1 of N” never announced on first paint |
| **ERG-REG-UPLOAD-001** | Event registration | Upload % updates visually but not spoken incrementally |
| **ERG-EVENTS-001** | Events list | Card speaks title only; schedule/summary excluded |
| **AUDIT-FIND-039** | Country picker | Search field re-speaks on double-tap |
| **AUDIT-FIND-046** | Country picker | No labeled Close; scrub Z only |
| **A11Y-MORE-002** | Settings | Push-register hint spoken **twice** |
| **A11Y-MORE-006** | Change password | “Required” not in semantics labels |
| **A11Y-MORE-003–005** | Profile, Contact, Change pwd | Validation without announce/scroll |
| **AUDIT-FIND-020/041** | Auth screens | Intro/subtitle plain `Text` — easy to miss |
| **AUDIT-FIND-042** | Forgot password | Channel chips 48px (below 56px rule) |
| **AUDIT-FIND-043** | Volume (Radio) | Duplicate swipe hints on slider |
| **A11Y-MORE-008–010** | Change pwd, Profile, Library | IconButtons under 56px |

---

## ✅ Patterns that work (reuse everywhere)

| Pattern | File | Use for |
|---------|------|---------|
| `UdaanLabeledField` (no suffix) | `udaan_auth_widgets.dart` | Text fields with label + required + single stop |
| `UdaanOtpPinRow` | `udaan_otp_pin_row.dart` | OTP — one logical focus |
| Country search field | `accessible_country_picker_sheet.dart` | Search with ExcludeSemantics |
| Library search | `library_search_field.dart` | Heading vs hint deduped |
| Event choice tiles | `registration_form_styles.dart` | Radio/checkbox with group label |
| Locked account fields | `event_registration_screen.dart` | readOnly + lock hint |

---

## Device QA backlog (priority order)

1. **Register** — inherits FIND-033/034/024 (not device-tested)
2. **Event registration** — multi-page, upload, date picker (SCREEN-07 — create)
3. **Forgot / Reset password** — channel chips, OTP, toggles
4. **Edit profile / Change password / Help contact**
5. **Settings** — toggles + duplicate hint
6. **Library search** — likely PASS; quick confirm

Existing device audits: SCREEN-02, SCREEN-04, POPUP-02, SCREEN-06 (volume PASS).

---

## Fix phase checklist (when user approves)

1. Fix `UdaanPhoneField` + `UdaanLabeledField` suffix (unblocks 5+ screens)
2. Add shared `_announceValidationError()` helper for auth/events/more
3. Country picker focus trap + modal announce
4. Event registration: announce validation + page nav + info HTML
5. Help contact ExcludeSemantics
6. Re-run device QA on fixed screens
