# Page-by-page double-speech audit (TalkBack / VoiceOver)

**Date:** 2026-06-13  
**Team:** Maya (a11y), Daniel (mobile), Elena (QA static review)  
**Method:** Static semantics tree review per screen; device pass still required.

**Legend:** PASS = one spoken node per content | FAIL = confirmed duplicate risk | REVIEW = verify on device

---

## Main shell & tabs

| Page | Verdict | Notes |
|------|---------|-------|
| Bottom navigation | PASS | Removed tab-switch `announce()`; nav label only |
| Live (Radio) tab | PASS | Hero/play/upcoming use ExcludeSemantics |
| Radio schedule sheet | PASS | Segment rows use UdaanLabeledRegion |
| Library tab | PASS | Search field uses hint label; heading separate |
| Events tab | PASS | UdaanLabeledRegion for intro |
| Event card | REVIEW | Banner title + register button both mention title |
| About tab | PASS | Hero + menu tiles OK |
| More tab | PASS | Menu tiles OK |

## Auth & bootstrap

| Page | Verdict | Notes |
|------|---------|-------|
| Splash | PASS | Loading dots no longer `liveRegion`; status line only |
| Login | REVIEW | Shared field widget pattern |
| Phone login | PASS | Screen title in top bar; logo without duplicate app name |
| Email login | PASS | Same pattern as phone login |
| Register | REVIEW | Field widgets |
| OTP verify | REVIEW | Pin row, spinner |
| Forgot password | PASS | Channel chips only; no group wrapper |
| Reset password | REVIEW | Pin row |
| Verify email | PASS | Code label once; sent-to line excluded when field speaks email |
| `udaan_otp_pin_row` | PASS | TextField excluded; parent Semantics only |
| `UdaanLabeledField` | PASS | TextField excluded inside Semantics |

## More / About (pushed)

| Page | Verdict | Notes |
|------|---------|-------|
| Settings | PASS | Visible text-size labels excluded; slider is single node |
| Edit profile | REVIEW | Avatar stack |
| Help & contact | PASS | Labels excluded |
| Notifications | REVIEW | Loading spinner |
| Change password | PASS | Visible labels excluded; field Semantics only |
| Legal content | REVIEW | App bar title + HTML h1 |
| Donate | PASS | QR image label without caption; copy uses `announce()` only |
| Contact email/phone | REVIEW | announceAndSnack on copy |
| Notification permission sheet | REVIEW | Route + header |
| Country picker | REVIEW | Favorites duplicated in list |

## Events & Library (pushed)

| Page | Verdict | Notes |
|------|---------|-------|
| Event registration | PASS | Removed form intro announce; page announce only when no visible title; upload progress on button only |
| Event deep link | REVIEW | Chains into registration |
| Library player | PASS | Video region label without duplicate title |
| Library playlists | PASS | |
| Playlist videos | PASS | |
| Library saved | PASS | ListTile semantics only; removed container label |

---

## Device QA (Elena / Jordan)

After FAIL fixes, run `scripts/a11y-device-qa.md` plus spot-check:

1. Tab switch — hear tab name **once**
2. Library search — heading then field, not same phrase twice
3. Phone login — app name **once**
4. Verify email — “verification code” **once**
5. Event registration — no triple header on open
6. Library saved row — one stop per item

Log results in `.cursor/memory/bugs-found.md`.
