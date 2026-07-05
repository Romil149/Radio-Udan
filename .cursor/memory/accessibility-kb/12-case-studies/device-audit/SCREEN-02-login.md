# SCREEN 02 — Login (`/login`)

**Audit ID:** SCREEN-02  
**Status:** IN PROGRESS — popup audit  
**Code reviewed:** 2026-07-04 by Jordan Lee  
**Files:**

| File | Role |
|------|------|
| `lib/features/auth/login_screen.dart` | Main login UI + submit/OTP flows |
| `lib/features/auth/widgets/udaan_auth_widgets.dart` | Header, fields, buttons, footer |
| `lib/features/auth/widgets/udaan_phone_field.dart` | Country + national number |
| `lib/core/widgets/offline_brand_logo.dart` | Logo semantics |
| `lib/core/widgets/accessible_country_picker_sheet.dart` | **Popup** — country picker (audit separately) |

**Popups on this screen:**

| Popup | Trigger | Audit file |
|-------|---------|------------|
| Country picker sheet | Tap country code on phone field | `POPUP-02-country-picker.md` (when opened) |

**Staging copy (snapshot):**

| Key | Expected string |
|-----|-----------------|
| `login_mobile_intro` | Sign in with your mobile number and password. |
| `phone_field_label` | Mobile number |
| `phone_field_helper` | Choose your country code, then enter your mobile number without the leading zero. |
| `phone_country_code_semantics` | Country code, {country_name}, plus {dial_code}. Double tap to change country. |
| `password_label` | Password |
| `login_password_hint` | Enter your password |
| `show_password` / `hide_password` | Show password / Hide password |
| `forgot_password_link` | Forgot Password? |
| `login_button` | Login |
| `sign_in_with_otp` | Login with OTP |
| `sign_in_with_email` | Login using email |
| `dont_have_account` | Don't have an account? |
| `register_here` | Register Here |

---

## 1. Code walkthrough

### `LoginScreen`

| Function | A11y impact |
|----------|-------------|
| `_submit()` | Sets `_error` with `liveRegion` Semantics — no `sendAnnouncement` |
| `_startOtpLogin()` | Navigates to OTP flow — error inline only |
| `_passwordVisibilityToggle()` | `Semantics(button, label: show/hide password)` ✅ |

### Widget tree (top → bottom)

| # | Widget | Semantics | Expected speech |
|---|--------|-----------|-----------------|
| 1 | `UdaanAuthLogoHeader` → logo | `{appName} logo`, image | Radio Udaan logo |
| 2 | App name | `header: true` | Radio Udaan, heading |
| 3 | Subtitle `loginMobileIntro` | **Plain Text — NO Semantics** | ⚠️ AUDIT-FIND-020 |
| 4 | Phone label + helper | **ExcludeSemantics** (visual only) | Not focused separately |
| 5 | Country code button | `phoneCountryCodeSemantics` | Country code, India, plus 91… |
| 6 | National number field | `textField`, label includes mobile + country + required | Mobile number, India, plus 91, required, edit box |
| 7 | Password field | `UdaanLabeledField`, `Password, required` | Password, required, edit box |
| 8 | Show/hide password | Suffix semantics button | Show password / Hide password |
| 9 | Forgot password | `UdaanAuthLink` button | Forgot Password? |
| 10 | Error (if any) | `liveRegion: true` | Error message text |
| 11 | Login | `UdaanPrimaryButton` 56px | Login, button |
| 12 | Login with OTP | `UdaanOutlineButton` | Login with OTP, button |
| 13 | Login using email | `UdaanOutlineButton` | Login using email, button |
| 14 | Footer prompt | **Plain Text** `dontHaveAccount` | ⚠️ AUDIT-FIND-021 |
| 15 | Register | `Semantics(button)` on action only | Register Here, button |

**Note:** No dedicated screen title "Login" — app name header only (AUDIT-FIND-022).

---

## 2. Code review findings (audit only)

| ID | Severity | Finding | Code |
|----|----------|---------|------|
| AUDIT-FIND-020 | HIGH | Subtitle `login_mobile_intro` plain Text — may be missed | `UdaanAuthLogoHeader` L286-296 |
| AUDIT-FIND-021 | MED | Footer "Don't have an account?" plain Text — only Register button labeled | `UdaanAuthFooterPrompt` L850-857 |
| AUDIT-FIND-022 | MED | No screen-level "Login" heading landmark | `login_screen.dart` — no top bar title |
| AUDIT-FIND-023 | MED | Helper text excluded — OK if field label sufficient | `udaan_phone_field.dart` L173-181 |
| AUDIT-FIND-024 | **HIGH** | Error via `liveRegion` only — **not auto-spoken on iOS** when Login tapped; blind user must swipe to find error | `login_screen.dart` L170-184 — no `SemanticsService.sendAnnouncement` (unlike OTP/reset screens) |
| AUDIT-FIND-025 | MED | Loading spinner on Login button — no loading announcement | `UdaanPrimaryButton` loading state |
| AUDIT-FIND-026 | OK | Password + phone use required in semantics label | `UdaanLabeledField`, phone field |
| AUDIT-FIND-027 | OK | Buttons 56px min height | `UdaanPrimaryButton` / `UdaanOutlineButton` |
| AUDIT-FIND-028 | MED | Phone field semantics may omit spoken "required" on iOS | User heard label without "required" — verify copy/semantics join |
| AUDIT-FIND-029 | MED | Helper text (`phone_field_helper`) excluded — blind user may not hear "without leading zero" | `udaan_phone_field.dart` L173-181 |
| AUDIT-FIND-030 | MED | `phone_national_field_semantics` copy exists but login code uses custom label with country repeated | `app_copy_accessors.dart` vs `udaan_phone_field.dart` L152-157 |
| AUDIT-FIND-031 | LOW | Country name/code spoken on both country button and phone field | Redundant for VoiceOver linear navigation |
| AUDIT-FIND-032 | **CRITICAL** | Autofill/paste full number into national field → double country code (`+91911234567890`) | See autofill section below |
| AUDIT-FIND-033 | **HIGH** | National phone `TextField` missing `ExcludeSemantics` → VoiceOver two stops (label + placeholder) | `udaan_phone_field.dart` L238-258 vs `UdaanLabeledField` L365-370 |
| AUDIT-FIND-034 | **HIGH** | Show password toggle inside `ExcludeSemantics` TextField subtree — not in VoiceOver swipe path | `login_screen.dart` L106-120 + `UdaanLabeledField` suffix inside excluded TextField |

---

## 3. Device checkpoints

**Platform:** VoiceOver iOS (continue from Screen 01)  
**Setup:** Logged out, on Login screen, VoiceOver ON

| ID | Checkpoint | Expected | Heard (device) | PASS/FAIL | Notes |
|----|------------|----------|----------------|-----------|-------|
| CP-01 | Logo | Radio Udaan logo | Radio Udaan logo | **PASS** | |
| CP-02 | App name heading | Radio Udaan, heading | Radio Udaan, heading | **PASS** | |
| CP-03 | Intro subtitle | Sign in with your mobile number and password. | Heard intro subtitle | **PASS** | Plain Text read on iOS — FIND-020 not reproduced |
| CP-04 | Country code button | Country code, {country}, plus {code}… | Country code announced correctly | **PASS** | |
| CP-05 | Phone number field | Mobile number, {country}, plus {code}, required, edit box | **Heard:** "Mobile number, India, plus 91, double tap to edit" then **second stop** placeholder 9876543210 | **FAIL** (partial) | FIND-028 (required); FIND-033 **double focus** — should be ONE field stop |
| CP-06 | Password field | Password, required, edit box | **Heard:** "Password, required, text field, double tap to edit" | **PASS** | Single stop; "required" spoken (contrast phone FIND-028) |
| CP-07 | Show password toggle | Show password, button | **Not reached** — swipe goes Password → Forgot Password | **FAIL** | FIND-034 — control exists in code but not exposed to VoiceOver |
| CP-08 | Forgot password | Forgot Password?, button | **Heard:** "Forgot password, button" | **PASS** | Clear label + button role |
| CP-09 | Login button | Login, button | **Heard:** "Login, button" | **PASS** | |
| CP-10 | Login with OTP | Login with OTP, button | **Heard:** "Login with OTP, button" | **PASS** | |
| CP-11 | Login using email | Login using email, button | **Heard:** "Login using email, button" | **PASS** | |
| CP-12 | Footer prompt | Don't have an account? | **Heard:** "Don't have an account" | **PASS (iOS)** | Guide re-check: copy matches `dont_have_account` ( ? may drop); **FIND-021 code gap** — plain `Text`, no `Semantics`; verify TalkBack separately |
| CP-13 | Register Here | Register Here, button | **Heard:** "Register Here, button" | **PASS** | Guide: `register_here` copy ✓; `Semantics(button)` + 56px tap target ✓ |
| CP-14 | Error on empty/invalid submit | Error auto-spoken when Login tapped | **Seen on screen:** phone invalid message; **NOT auto-spoken** — only heard on swipe left | **FAIL** | FIND-024 confirmed — `liveRegion` only, no `sendAnnouncement` |
| CP-15 | Country popup | Modal trapped; search; favorites; select closes | Open: focus leak; search/list/select OK | **FAIL** (partial) | POPUP-02 complete — FIND-035/036 open; FIND-039 MED |
| CP-16 | End of screen | Last stop = Register Here; end chime on next swipe | **Heard:** end-of-screen sound, then Register Here again | **PASS** | Normal VoiceOver boundary — not duplicate control (code has one `Semantics` button) |

---

## Screen 02 — iOS VoiceOver linear sign-off (2026-07-04)

| | |
|---|---|
| **Overall** | **FAIL** — 2 blocking/high issues on phone row + show password |
| **Device** | iOS VoiceOver, logged-out `/login` |
| **PASS** | CP-01–04, CP-06, CP-08–13, CP-16 |
| **FAIL** | CP-05, CP-07, CP-14, CP-15 (partial — popup focus leak) |
| **Pending** | POPUP-02 swipes 4+; Android TalkBack |

## CP-05 — Your answer + keyboard question (logged)

**You said:** *"Yes it says mobile number india +91 double tab to edit."*

**Jordan assessment:** **PASS** for focus label. That matches how VoiceOver should introduce this field.

### Your question: keyboard or number input?

**Correct for blind users on this field: the phone / number pad — not the full letter keyboard.**

| What | Expected on Login phone field |
|------|-------------------------------|
| **Country** | Separate control (CP-04). You already passed this — double-tap opens country **popup** (audited later). |
| **National number** | Double-tap the phone field → iOS should open a **numeric phone keypad** (digits only). |
| **Why** | Code uses `keyboardType: TextInputType.phone` + digits-only filter — national part is numbers only, no letters. |
| **Full QWERTY keyboard** | **Wrong** for this box — you should not need to type letters here. |
| **Bluetooth keyboard** | When the field is focused, number keys should work. |

**VoiceOver wording:** *"Double tap to edit"* = activate the field so you can type. That is normal iOS speech (same role as "edit box" on Android TalkBack).

**Small gap (FIND-028):** Code builds label with **"required"** (`Mobile number, India, plus 91, required`) but you did not hear *required*. We log that for fix phase — not a blocker if you can still complete login.

**Optional quick check:** Double-tap the phone field now — confirm the **number pad** appears (not ABC keyboard). Reply in chat: *"number pad yes"* or *"full keyboard appeared*.

**Device check (2026-07-04):** User confirmed **number pad appeared** — correct behavior ✅

### Guide compliance review (CP-05 — your question)

**Short answer:** Numeric keyboard is set up **correctly**. Spoken labels are **mostly correct** but **not fully** per Radio Udaan guide — logged for fix phase.

| Guide requirement | Code / device | Verdict |
|-------------------|---------------|---------|
| Phone uses **number pad** (not ABC) | `keyboardType: TextInputType.phone` + digits-only filter; you confirmed number pad | ✅ **PASS** |
| **Persistent label above field** (not floating-only) | Visual "Mobile number" + helper excluded from duplicate focus | ✅ **PASS** |
| **Required** spoken on required fields | Code: `Mobile number, India, plus 91, required` — you did **not** hear "required" | ❌ **GAP** (FIND-028) |
| **Meaningful unique labels** | Country button + phone field are two stops | ✅ **PASS** |
| **Helper instructions reachable** | Helper text ("without the leading zero…") is `ExcludeSemantics` — **not spoken** | ⚠️ **GAP** (FIND-029) |
| **Copy key `phone_national_field_semantics`** | WP copy: *"Mobile number without country code"* — **code does not use this key**; instead repeats country in phone label | ⚠️ **GAP** (FIND-030) |
| **Country spoken once clearly** | Country button (CP-04) + again on phone field ("India, plus 91") | ⚠️ **Redundant** (FIND-031) |
| **Touch target ≥ 56px** | Country row `minHeight: 56` | ✅ **PASS** |

**What you heard vs what code intends:**

| Control | Code intends (full) | You heard | Match? |
|---------|---------------------|-----------|--------|
| Country button | "Country code, India, plus 91. Double tap to change country." | (CP-04 PASS) | ✅ |
| Phone field | "Mobile number, India, plus 91, required" + edit | "Mobile number, India, plus 91, double tap to edit" | **Partial** — missing "required"; country duplicated |

**Jordan verdict for audit:** **CP-05 FAIL (partial)** — number pad OK, but **extra VoiceOver stop on placeholder** (FIND-033) + label gaps FIND-028/029/030/031.

### Autofill / double country code — AUDIT-FIND-032 (CRITICAL)

**Client report:** Autofill puts `91` in the number box; registration/login sends `+919112345678890` instead of `+911234567890`.

**Jordan: Client is correct — this is a real bug** (function + accessibility).

**Why it happens (code):**

1. UI is **split**: country picker shows **+91** + separate **national** field (digits only).
2. Correct E.164 is built as: `+{countryCode}{national}` → e.g. `+91` + `1234567890` = `+911234567890`.
3. iOS/Android **autofill** (`AutofillHints.telephoneNumber`) often fills the **full** number into the national field, e.g. `911234567890` or `91234567890`.
4. **Login screen does not run** `setFromRawInput()` when autofill fills the field — only `phone_login_screen` does that for route prefill.
5. Submit uses `_phoneInput.e164` which **concatenates blindly**:

```dart
// phone_country.dart
return normalizeE164Phone('+${country.phoneCode}$national');
// IN (+91) + national "911234567890" → +91911234567890 ❌
```

6. `setFromRawInput()` **would** split correctly via `splitE164Phone()` — but **autofill bypasses it**.

**Impact:**

| User | Result |
|------|--------|
| VoiceOver + autofill | Wrong number sent; OTP/login/register fails or wrong account |
| Sighted user + autofill | Same wrong E.164 |
| Manual 10-digit entry | Works ✅ |

**Fix direction (dev phase — not now):**

1. On national field **change / autofill**: normalize paste — if digits start with selected country code, **strip** it before submit.
2. Reuse `setFromRawInput()` or `splitE164Phone()` on every full paste/autofill.
3. Optionally **announce** when number normalized: *"Mobile number filled, India plus 91"* (client “speak what we’re entering”).
4. Validate E.164 length/country before submit; speak error if invalid.
5. Consider `tel-national` / full single field for autofill on iOS (platform autofill expects one phone control).

**Audit:** Log as **CRITICAL** — blocks blind users who rely on autofill (common for login).

### Double VoiceOver stop on phone field — AUDIT-FIND-033 (HIGH)

**Client report (2026-07-04):** On country code → swipe → hears *"Mobile number +91 required, text field, double tap to edit"* → swipe again → hears *"9876543210, text field, double tap to edit"*. Feels wrong — *"do I have to swipe again to edit?"*

**Jordan: Client is correct — the third stop is NOT fine per guide.**

| Swipe step | What you heard | Correct per guide? |
|------------|----------------|-------------------|
| 1 — Country code button | Country code, India, plus 91… **button** | ✅ Two controls = two stops is OK |
| 2 — National number field | Mobile number, India, plus 91… **text field** | ✅ This is where you **double-tap to type** |
| 3 — Placeholder (`9876543210`) | Separate **text field** stop | ❌ **BUG** — placeholder must not be its own focus target |

**What should happen (Apple HIG + Flutter + Radio Udaan rules):**

1. **Country picker** = **one button stop**. Double-tap **changes country**, does not open keyboard for typing digits.
2. **National number** = **one text-field stop**. Double-tap **opens number pad** and you type there. You do **not** swipe past it to a second “9876543210” field.
3. Placeholder (`98765 43210`) may be spoken as a **hint inside** the national field announcement when empty — not as a separate swipe target.
4. Ideal label (WP copy exists): *"Mobile number without country code, required"* — country already spoken on button (FIND-030/031).

**Root cause in code:** Password field uses the correct pattern; phone field does not:

```dart
// UdaanLabeledField (password) — ONE stop ✅
Semantics(textField: true, label: ..., child: ExcludeSemantics(child: TextField(...)))

// UdaanPhoneField national — TWO stops ❌
Semantics(textField: true, label: ..., child: TextField(...))  // no ExcludeSemantics
```

**Fix direction (dev phase):** Wrap national `TextField` in `ExcludeSemantics` (match `UdaanLabeledField` / OTP recipe). Re-test CP-05: exactly **2 stops** for phone row (country button + national field).

---

## CP-14 — Login error not auto-announced (device + guide verified)

**You did:** Empty/invalid mobile + Login tap.

**Seen on screen:** *"Enter a valid mobile number for the country you selected."* (`phone_invalid` copy key)

**VoiceOver:** Error **did not speak on appear** — only when you **swiped left** to focus it.

| Source | Requirement | Result |
|--------|-------------|--------|
| **Guide** | `liveRegion: true` on errors **and** `sendAnnouncement` for validation errors | **FAIL** — liveRegion only |
| **KB #003** | Sighted sees error; blind hears nothing until exploring | **FAIL** — matches SnackBar-only pattern |
| **Code** | `Semantics(liveRegion: true)` on error Text | Present |
| **Code** | `SemanticsService.sendAnnouncement` on `_submit()` error | **Missing** (OTP/reset screens have `_announce()`) |
| **Focus order** | Error appears **above** Login buttons in tree — swipe path may miss it if user stays at bottom | Extra confusion |

**Verdict: CP-14 FAIL** — **FIND-024 HIGH** (release blocker for blind users).

---

*Screen 02 iOS linear + error test logged. Pending: CP-15 country popup, Android TalkBack.*

---

*Popups: open country picker only when Jordan sends POPUP checkpoint.*
