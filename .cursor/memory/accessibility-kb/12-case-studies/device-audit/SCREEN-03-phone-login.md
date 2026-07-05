# SCREEN 03 — Phone OTP login (`/login-otp`)

**Audit ID:** SCREEN-03  
**Status:** IN PROGRESS  
**Route:** `/login-otp` (also `/login/phone` alias in router)  
**Code reviewed:** 2026-07-04  
**Files:**

| File | Role |
|------|------|
| `lib/features/auth/phone_login_screen.dart` | OTP phone entry + Send code |
| `lib/features/auth/widgets/udaan_auth_widgets.dart` | Top bar, logo, buttons |
| `lib/features/auth/widgets/udaan_phone_field.dart` | Country + national (shared with login) |

**How to reach:** Login → **Login with OTP** button.

**Popups:** Country picker (same as POPUP-02 — inherits FIND-035/036).

---

## Staging copy (snapshot)

| Key | Expected string |
|-----|-----------------|
| `back_button` | Back |
| `sign_in_with_mobile` | Login using mobile |
| `sign_in_intro` | Choose your country code and mobile number. We will send a one-time code by SMS. |
| `phone_field_label` | Mobile number |
| `phone_country_code_semantics` | Country code, {country}, plus {dial_code}. Double tap to change country. |
| `otp_send_code` | Send code |
| `sign_in_with_password` | Sign in with password |
| `phone_invalid` | Enter a valid mobile number for the country you selected. |

---

## Widget tree (focus order)

| # | Widget | Expected speech |
|---|--------|-----------------|
| 1 | `UdaanAuthTopBar` back | Back, button |
| 2 | Top bar title | Login using mobile, heading |
| 3 | Logo (`showAppNameHeader: false`) | Radio Udaan logo |
| 4 | Subtitle `signInIntro` | Plain Text — ⚠️ may miss on some platforms (FIND-020 pattern) |
| 5 | Country code button | Country code, India, plus 91… |
| 6 | National phone field | Mobile number… required, text field (**inherits FIND-033** from login) |
| 7 | Error (if shown) | liveRegion only — **inherits FIND-024** |
| 8 | Send code | Send code, button |
| 9 | Sign in with password | Sign in with password, button |

**Note:** No app name heading on this screen (only top bar title).

---

## Inherited findings from Screen 02 (same widgets)

| ID | Applies here? |
|----|----------------|
| FIND-033 | Yes — phone double stop |
| FIND-032 | Yes — autofill double 91 |
| FIND-028–031 | Yes — phone label gaps |
| FIND-024 | Yes — error not auto-announced |
| POPUP-02 | Yes — country picker |

---

## Device checkpoints

**Platform:** VoiceOver iOS  
**Setup:** Login screen → tap **Login with OTP** → on Phone login screen

| ID | Checkpoint | Expected | Heard (device) | PASS/FAIL | Notes |
|----|------------|----------|----------------|-----------|-------|
| CP-01 | Back button | Back, button | | | |
| CP-02 | Screen title | Login using mobile, heading | | | |
| CP-03 | Logo | Radio Udaan logo | | | No app name header |
| CP-04 | Intro subtitle | Choose your country code and mobile number… | | | FIND-020 pattern |
| CP-05 | Country code | Country code, India, plus 91… | | | |
| CP-06 | Phone field | Mobile number… required, one stop | | | FIND-033 |
| CP-07 | Send code | Send code, button | | | |
| CP-08 | Sign in with password | Sign in with password, button | | | |
| CP-09 | End of screen | Last = Sign in with password | | | |
| CP-10 | Error (optional) | Invalid phone → auto-spoken error | | | FIND-024 |

---

*Jordan waiting for CP-01 — one checkpoint at a time.*
