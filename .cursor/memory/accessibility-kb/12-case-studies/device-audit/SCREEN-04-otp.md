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

---

## 2026-07-10 — Code fixes (O1–O8)

**Status:** CODE FIXED (local) · device re-test pending · not committed

| ID | Fix |
|----|-----|
| **O1** | Top bar title = `otpEnterTitle` / `verifyIdentityTitle`; body title visual-only (no header) |
| **O2** | Login intro + masked phone merged Semantics (like identity) |
| **O3** | `_verify` announces `verifyingCodePleaseWait` |
| **O4** | Wait timer `liveRegion: true` (login) |
| **O5** | `_resend` announces `resendingCodePleaseWait` |
| **O6** | Identity trailing icon `ExcludeSemantics` |
| **O7** | Identity gets `resendSecondsRemaining` + wait timer liveRegion |
| **O8** | Contact button label includes “Having trouble?” |

Also Screen 03 **P1**: phone login announces `sendingCodePleaseWait`.

---

*Next: device QA or Screen 06 Radio; commit/build bump on request.*

---

## 2026-07-09 — Line-by-line vs guide (Maya Chen) · build 2.0.0+41

**Status:** IN DISCUSSION (popup) — code audit only; **no fixes this pass**  
**Code reviewed:** `otp_verify_screen.dart`, `otp_verify_login_body.dart`, `otp_verify_identity_body.dart`, `udaan_otp_pin_row.dart`, related `udaan_auth_widgets.dart`  
**Prior device logs (2026-07-04 / 2026-07-05):** preserved above — do not treat as re-verified on +41

### 1. Route(s) + files + how to reach from Login

| | |
|---|---|
| **Primary route** | `/otp` → `OtpVerifyScreen` |
| **Bodies** | Login OTP → `OtpVerifyLoginBody` (`OtpPurpose.login` / reset); Registration → `OtpVerifyIdentityBody` (`OtpPurpose.verifyPhone`) |
| **Related** | `/login-otp` + `/otp-login` = Screen 03 (`PhoneLoginScreen`) — **not** this screen; Back from login OTP goes to `/otp-login` |

**Files owned**

| File | Role |
|------|------|
| `lib/features/auth/otp_verify_screen.dart` | Verify / resend / bootstrap / announces |
| `lib/features/auth/widgets/otp_verify_login_body.dart` | Login “Enter OTP” UI |
| `lib/features/auth/widgets/otp_verify_identity_body.dart` | Register “Verify Identity” UI |
| `lib/features/auth/widgets/udaan_otp_pin_row.dart` | Single merged PIN field |
| `lib/features/auth/widgets/udaan_auth_widgets.dart` | Top bar, heroes, primary/outline buttons, contact prompt |
| `lib/features/auth/auth_otp_flow.dart` | `requestLoginOtpAndOpenVerify` → push `/otp` |

**How to reach (login path)**

1. Login (`/login`) → enter phone → **Login with OTP** → may skip Screen 03 if number already filled → `requestLoginOtpAndOpenVerify` → `/otp` (`OtpVerifyLoginBody`).
2. Or Login → **Login with OTP** with empty phone → Screen 03 → **Send code** → `/otp`.
3. Register path: Register → OTP request → `/otp` (`OtpVerifyIdentityBody`).
4. Deep / session: unverified phone may land on `/otp` with bootstrap (`verifyPhone`).

### 2. Widget tree top→bottom (semantics verdict)

#### A) Login body (`OtpVerifyLoginBody`)

| # | Widget | Verdict |
|---|--------|---------|
| 1 | Back | **OK** — `back_button`, button, 56×56 |
| 2 | Top bar title = `brandingAppName` | **O1** — heading “Radio Udaan” (not task title); dual heading with #4 |
| 3 | Hero `UdaanOtpHeroIcon` | **OK** — `secure_verification_hero` |
| 4 | Title `otp_enter_title` | **OK** as task heading — **O1** conflict with #2 |
| 5 | Intro `otp_sent_intro` | **O2** — plain `Text` (no Semantics wrapper) |
| 6 | Masked phone | **O2** — plain `Text` |
| 7 | Dev OTP hint (debug only) | OK if present |
| 8 | `UdaanOtpPinRow` | **OK** — one textField; `focused` + `Editing Verification code` (+41) |
| 9 | Error (if any) | **OK (code)** — `liveRegion` + `announceValidationError` (not FIND-024 gap) |
| 10 | LOGIN `UdaanPrimaryButton` | **O3** — label OK; loading = spinner only, no announce |
| 11 | Wait timer (if counting) | **O4** — Semantics label OK; **no `liveRegion` / tick announce** |
| 12 | Resend OTP | **O5** — button OK; while `_resending` no `resendingCodePleaseWait` (success announce OK) |

#### B) Identity body (`OtpVerifyIdentityBody`) — same route, different purpose

| # | Widget | Verdict |
|---|--------|---------|
| 1 | Back | **OK** |
| 2 | Top bar title = app name | **O1** same dual-heading pattern |
| 3 | Trailing shield icon | **O6** — labeled `secure_verification_hero`, **not a button**; extra focus stop |
| 4 | Divider | Ignored (decorative) |
| 5 | Padlock hero | **OK** — `verify_identity_hero` |
| 6 | Title `verify_identity_title` | **OK** heading — **O1** with #2 |
| 7 | Intro + masked phone | **OK** — merged Semantics (better than login body) |
| 8 | PIN row | **OK** (+41 Editing) |
| 9 | Error | **OK (code)** — announce + liveRegion |
| 10 | Verify button | **O3** — loading silent |
| 11 | Resend | **O5** + **O7** — no wait-timer UI; disabled state has no spoken wait reason |
| 12 | “Having trouble?” + Contact support | **O8** — prompt plain Text; Contact support button OK |

### 3. OPEN wrong findings

| ID | Sev | Finding | File:line | Guide rule | Proposed fix |
|----|-----|---------|-----------|------------|--------------|
| **O1** | MED | Dual headings: top bar = app name **and** “Enter OTP” / “Verify Identity” | `otp_verify_login_body.dart` L54–57, L64–78; `otp_verify_identity_body.dart` L60–63, L83–97 | Guide `/otp` expects task header `{otpTitle}`; headings rotor clarity; prior **FIND-040** | Top bar: non-header brand **or** task title only; one `header: true` |
| **O2** | MED | Login intro + masked phone are plain `Text` (no Semantics) | `otp_verify_login_body.dart` L80–98 | Do not hide critical copy; prior **FIND-041**; identity body already merges | Match identity: one Semantics for intro + masked phone |
| **O3** | HIGH | Verify/LOGIN loading: spinner only — copy `verifying_code_please_wait` unused | `otp_verify_screen.dart` `_verify` L254–257; `UdaanPrimaryButton` L564–572 | Announce submit progress (Screen 02 L3 / Screen 03 P1) | `announce(context, copy.verifyingCodePleaseWait)` when `_loading = true` |
| **O4** | MED | Resend wait string has Semantics but no liveRegion / no tick announce | `otp_verify_login_body.dart` L148–164; guide OTP pattern “announce resend timer” | Patterns: announce resend timer | `liveRegion: true` and/or announce on first show / each N seconds |
| **O5** | MED | Resend in-flight: no `resending_code_please_wait`; only success `otp_resent_success` | `otp_verify_screen.dart` `_resend` L201–224 | Announce submit / progress | Announce wait copy when `_resending = true` |
| **O6** | LOW | Identity trailing icon is a focusable non-control | `otp_verify_identity_body.dart` L64–71 | Icons paired with purpose; avoid decorative focus stops | `ExcludeSemantics` on trailing **or** remove trailing (hero already labeled) |
| **O7** | MED | Identity: no wait-timer UI while resend locked — only disabled Resend | `otp_verify_identity_body.dart` (no timer); `otp_verify_screen.dart` `canResend` | Resend reachable + reason when waiting | Reuse login wait Semantics, or include wait in disabled Resend label |
| **O8** | LOW | “Having trouble?” plain Text before Contact support | `udaan_auth_widgets.dart` `UdaanContactSupportPrompt` L816–823 | Critical copy discoverable | Fold into Contact support label **or** Semantics on prompt |

**Not re-opened as wrong (code OK vs prior notes)**

| Prior note | 2026-07-09 verdict |
|------------|-------------------|
| FIND-024-style error silence | **Fixed in code** for OTP — `_setError` → `announceValidationError` + `liveRegion` |
| Six separate PIN boxes | **OK** — single merged `UdaanOtpPinRow` |
| L6 “Editing” missing on PIN | **Fixed in +41** — `focused:` + `announce('Editing …')` |

### 4. Already OK / inherited from build 41

| Item | Evidence |
|------|----------|
| Back 56×56 + label | `UdaanAuthTopBar` |
| Hero labels | `secure_verification_hero` / `verify_identity_hero` |
| Task title `header: true` | Enter OTP / Verify Identity |
| Single PIN semantics + SMS hint + empty/value | `udaan_otp_pin_row.dart` |
| **L6 Editing** on PIN | `focused` + `Editing ${otpPinRowLabel}` L53–58, L72 |
| Error announce + liveRegion | `otp_verify_screen.dart` `_setError`; bodies L125–139 / L147–161 |
| Resend **success** announce | `_announce(otpResentSuccess)` L224 |
| Bootstrap loading labeled | `semanticsLoading` + liveRegion L319–322 |
| Primary/outline buttons 56px + Semantics | `UdaanPrimaryButton` / `UdaanOutlineButton` |
| Identity intro+phone merged | `otp_verify_identity_body.dart` L99–120 |
| Contact support button | labeled, 56 min tap |
| No READ_SMS | manual entry + `AutofillHints.oneTimeCode` only |

### 5. VERIFY on device

| ID | Item | Note |
|----|------|------|
| V1 | Login intro + masked phone (plain Text) | iOS Jul 4 heard; **TalkBack pending**; O2 still code gap |
| V2 | Wait timer while counting | Not heard Jul 4 (timer finished); confirm focus stop + whether ticks speak |
| V3 | Bad OTP / incomplete → auto-announce | Code has announce; **device untested** |
| V4 | PIN focus → “Editing Verification code” | +41 — needs TalkBack + VoiceOver |
| V5 | LOGIN/Verify loading silence (O3) | Confirm no progress speech |
| V6 | Resend success announce | Code path; confirm on device |
| V7 | Identity trailing icon stop (O6) | Register OTP path only |
| V8 | Identity disabled Resend without wait copy (O7) | |

### 6. Questions for human (max 5)

1. **O1:** Top bar = brand (non-header) + “Enter OTP” heading, or top bar = “Enter OTP” only?
2. **O2:** Merge login intro + masked phone like identity body, or accept plain Text if TalkBack reads it?
3. **O3/O5:** Announce `verifyingCodePleaseWait` / `resendingCodePleaseWait` now (same as Login L3 / Screen 03 P1)?
4. **O4/O7:** liveRegion/tick announce on wait timer, and add timer UI to identity body?
5. Next: fix Screen 04 open IDs, or continue audit to Screen 05/06?

### 7. Ready for Screen 05/06?

**Yes** — for **audit continuation** (findings documented; prior iOS journey PASS).  
**No** — for calling Screen 04 **ship-ready** until O3 (and ideally O1–O2, V3–V4) decided/fixed and device-verified.

**Open count:** **8** (O1–O8). Highest: **O3**.

---

*Maya Chen — 2026-07-09. No code changes. No commit.*
