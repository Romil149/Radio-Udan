# SCREEN 04 — OTP verify (`/otp`)

**Audit ID:** SCREEN-04  
**Status:** IN PROGRESS  
**Route:** `/otp` (login OTP flow)  
**Reached via:** Login screen → phone entered → **Login with OTP** (skips Screen 03 phone-login when number already filled)

**Files:**

| File | Role |
|------|------|
| `lib/features/auth/otp_verify_screen.dart` | OTP verify logic, resend, announce |
| `lib/features/auth/widgets/otp_verify_login_body.dart` | Login OTP UI |
| `lib/features/auth/widgets/udaan_otp_pin_row.dart` | Single merged PIN field |
| `lib/features/auth/widgets/udaan_auth_widgets.dart` | Top bar, hero, buttons |

---

## Staging copy

| Key | Expected |
|-----|----------|
| `back_button` | Back |
| (top bar title) | **App name** (`Radio Udaan`) — code uses `brandingAppName`, not `otp_enter_title` |
| `secure_verification_hero` | Secure verification |
| `otp_enter_title` | Enter OTP |
| `otp_sent_intro` | We have sent a 6-digit code to your mobile number |
| (masked phone) | e.g. +91 XXXXX 8025 — visual Text, no Semantics |
| `otp_pin_row_label` | Verification code |
| `otp_pin_row_empty` | Empty |
| `otp_pin_row_sms_hint` | Enter 6 digits from your SMS |
| `otp_login_button` | LOGIN |
| `otp_resend_label` | Resend OTP |

---

## Widget tree (focus order)

| # | Widget | Expected speech |
|---|--------|-----------------|
| 1 | Back | Back, button |
| 2 | Top bar title | Radio Udaan, heading ⚠️ not "Enter OTP" |
| 3 | Hero icon | Secure verification |
| 4 | Title | Enter OTP, heading |
| 5 | Intro | otp_sent_intro (plain Text) |
| 6 | Masked phone | +91 XXXXX •••• (plain Text) |
| 7 | PIN row | Verification code, empty, Enter 6 digits from SMS, text field |
| 8 | Error (if any) | liveRegion — may need swipe (FIND-024 pattern) |
| 9 | LOGIN button | LOGIN, button |
| 10 | Wait timer (if counting) | Didn't receive… Wait M:SS |
| 11 | Resend OTP | Resend OTP, button |

---

## Device checkpoints (2026-07-04, VoiceOver iOS)

| ID | Checkpoint | Expected | Heard (device) | PASS/FAIL | Guide notes |
|----|------------|----------|----------------|-----------|-------------|
| CP-01 | Back | Back, button | Back button | **PASS** | `back_button` |
| CP-02 | Top bar | Radio Udaan, heading | Radio Udaan heading | **PASS** | Code uses app name — **FIND-040** title not task-specific |
| CP-03 | Hero | Secure verification | Secure verification | **PASS** | `secure_verification_hero` |
| CP-04 | Enter OTP | Enter OTP, heading | Enter OTP heading | **PASS** | `otp_enter_title` |
| CP-05 | SMS intro | We have sent a 6-digit code… | Heard six-digit intro | **PASS (iOS)** | Plain Text — FIND-041 code gap |
| CP-06 | Masked phone | +91 XXXXX last4 | +91 xxxxx… (VO read digits) | **PASS (iOS)** | Plain Text — confirms destination number |
| CP-07 | PIN field | Verification code, empty, SMS hint | Verification code empty… 6 digit SMS | **PASS** | Single merged row ✅ recipe |
| CP-08 | LOGIN | LOGIN, button | **Heard:** Login button | **PASS** | Copy key `otp_login_button` = "LOGIN"; VoiceOver may say "Login" |
| CP-09 | Resend OTP | Resend OTP, button | **Heard:** Resend OTP button | **PASS** | `otp_resend_label` |
| CP-09b | Wait timer (if counting) | Didn't receive the code? Wait M:SS | **Not heard** — LOGIN → Resend directly | **PASS (assumed)** | Timer hidden when countdown finished |
| CP-10 | End of screen | Last stop = Resend OTP | Not tested — user completed OTP flow | **SKIP** | |
| CP-11 | Enter OTP + LOGIN | Code entry + successful sign-in | **User entered OTP → landed on live radio / home** | **PASS** | End-to-end login OTP journey works |

---

## Screen 04 — iOS VoiceOver sign-off (2026-07-05)

| | |
|---|---|
| **Overall** | **PASS (functional)** — linear swipe + OTP entry + login OK |
| **Open findings** | FIND-040 (dual headings), FIND-041 (plain intro/phone text) |
| **Not tested** | Wait timer stop while counting; error auto-announce on bad OTP (FIND-024 pattern) |
| **Next screen** | SCREEN-06 Radio tab (main shell after auth) |

---

*Screen 04 complete for primary journey. Continue audit on Radio tab when ready.*
