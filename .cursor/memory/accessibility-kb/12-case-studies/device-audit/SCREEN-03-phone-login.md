# SCREEN 03 — Phone OTP login (`/login-otp`)

**Audit ID:** SCREEN-03  
**Status:** CODE FIXED 2026-07-10 — P1 done; P2 intro plain Text still optional / parked  
**Route:** `/login-otp` (also `/otp-login` alias)  
**Code reviewed:** 2026-07-04 · **Re-verified:** 2026-07-09 vs build **2.0.0+41**  
**How to reach:** Login → **Login with OTP**

**Files:**

| File | Role |
|------|------|
| `lib/features/auth/phone_login_screen.dart` | OTP phone entry + Send code |
| `lib/features/auth/widgets/udaan_auth_widgets.dart` | Top bar, logo, buttons |
| `lib/features/auth/widgets/udaan_phone_field.dart` | Country + national (shared) |

**Popups:** Country picker — POPUP-02 (code fixed in +41; device re-verify).

---

## Staging copy (snapshot)

| Key | Expected string |
|-----|-----------------|
| `back_button` | Back |
| `sign_in_with_mobile` | Login using mobile |
| `sign_in_intro` | Choose your country code and mobile number. We will send a one-time code by SMS. |
| `otp_send_code` | Send code |
| `sign_in_with_password` | Sign in with password |
| `phone_invalid` | Enter a valid mobile number for the country you selected. |
| `sending_code_please_wait` | (used on Login OTP path — should use here for P1) |

---

## Widget tree (2026-07-09)

| # | Widget | Verdict |
|---|--------|---------|
| 1 | Back | OK |
| 2 | Title Login using mobile, heading | OK |
| 3 | Logo | OK (W4) |
| 4 | Intro `signInIntro` | **P2** plain Text |
| 5 | Country + national phone | OK (L1/L2/L4/L6 inherited) |
| 6 | Error | OK (announce + liveRegion) |
| 7 | Send code | **P1** loading silent |
| 8 | Sign in with password | OK |

---

## OPEN (discuss before fix)

| ID | Sev | Finding | Proposed |
|----|-----|---------|----------|
| **P1** | HIGH | No announce when Send code starts loading | `announce(context, _copy.sendingCodePleaseWait)` like `login_screen.dart` |
| **P2** | MED | Intro plain Text | Optional Semantics, or accept if device reads |

## Inherited FIXED from build 41

FIND-024, FIND-033, L1, L2, L4, L6, W4, POPUP-02 code, top bar heading, 56px buttons.

## Questions

1. Fix P1 now?
2. P2 Semantics or leave plain?
3. Next: Screen 04 or device-check 03?

---

*Next: Screen 04 OTP verify after P1/P2 decision.*
