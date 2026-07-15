# App Store Guidelines — Full Pre-Resubmit Audit (Radio Udaan iOS)

**Date:** 2026-07-15  
**Basis:** [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) + local code audit  
**Target binary:** **2.0.0+71** (must ship; do **not** resubmit +70)  
**Prior rejections:** 3.1.1 donate (68); 2.1 blank iPad (70)

---

## Verdict

| Status | Meaning |
|--------|---------|
| **DO NOT SUBMIT +70** | Known blank-launch rejection |
| **HIGH RISK until blockers cleared** | Even with +71 code |
| **Ship path** | Fix BLOCKERs → push +71 → iPad cold-launch QA → update ASC notes → submit **71** |

---

## BLOCKERS (must clear before Submit)

| ID | Guideline | Finding | Scenario | Fix |
|----|-----------|---------|----------|-----|
| **ASC-001** | 2.1 | Build **70** blank on iPad cold launch | Reviewer opens app on iPad Air → empty screen | Submit **+71 only** after TestFlight + iPad smoke |
| **ASC-002** | 2.1(a) | App is **login-gated**; demo phone/OTP must work | Reviewer cannot reach radio/events/library | Real demo phone + OTP in Review Notes; test on **production** |
| **ASC-003** | 5.1.1 | Privacy Policy is website-oriented; missing app data | Apple compares labels vs policy | Update policy: OTP/MSG91, uploads, Crashlytics, push, Razorpay, PAN/80G, account deletion |
| **ASC-004** | 2.3 / 3.1.1 | Stale Review Notes (Pay Online / auto-verify) | Reviewer looks for removed UI | Paste Safari-only notes from improved template |

---

## HIGH (fix before or with +71)

| ID | Guideline | Finding | Scenario | Fix |
|----|-----------|---------|----------|-----|
| **ASC-005** | 5.1.1 | Camera/mic **Info.plist** strings but app only uses gallery + file picker | Reviewer asks why camera/mic | Remove unused purpose strings **or** add matching features |
| **ASC-006** | 5.1 | More → Privacy may hide if WP `legal_pages.privacy` empty; `privacyPolicyUrl` unused | No in-app privacy link | Fallback open `https://radioudaan.com/privacy-policy/` |
| **ASC-007** | 5.1 | Push permission without in-app pre-prompt | System dialog on login | Pre-prompt or defer until Settings |
| **ASC-008** | 5.1 App Privacy | Crashlytics in release; must be in App Privacy + policy | Labels mismatch | Declare Diagnostics/Crash Data |
| **ASC-009** | 2.1 / 2.5 | Force-update min build raised too early | Reviewer hard-blocked | Keep WP min build ≤ submitted build |
| **ASC-010** | 2.3 | ASC metadata still says build 68/70 | Wrong binary narrative | Set build **71**, refresh What’s New |
| **ASC-011** | Age rating | 2026 questionnaire / social media answers | Wrong rating | Confirm **4+**, not Kids; no unrestricted web |

---

## MEDIUM (reduce re-rejection risk)

| ID | Guideline | Finding | Fix |
|----|-----------|---------|-----|
| **ASC-012** | 3.1.1 | `razorpay_flutter` still in iOS binary (UI unused) | Review Notes: “no iOS SDK checkout”; later Android-only dep |
| **ASC-013** | 3.1.1 | UPI QR + bank in-app | Keep Trust disclosure; attach Trust/80G PDF |
| **ASC-014** | Universal Links | Entitlements only `nexusfleck.com` | Add `radioudaan.com` AASA **or** don’t claim UL |
| **ASC-015** | 5.2.3 | YouTube custom controls / branding | Manual iPad check: attribution, ≥200×200, no download |
| **ASC-016** | 2.1 | Splash may show raw Dio errors | Friendly offline copy only |
| **ASC-017** | 2.3 | Display name “Radio Udaan App” vs listing | Align if easy |
| **ASC-018** | 4.0 | iPad is phone-scaled layout | Functional OK; optional max-width polish |
| **ASC-019** | 5.1.1(v) | Copy says “permanently deletes”; server soft-deletes | Soften copy to match |
| **ASC-020** | 2.1 | Prod YouTube/donate QR empty | Ensure prod content for review |

---

## LOW (cleanup / polish)

| ID | Note |
|----|------|
| **ASC-021** | Leftover iOS donate copy keys from old checkout |
| **ASC-022** | google_fonts network fetch offline cosmetic |
| **ASC-023** | Bundle ID looks like RN template (historical) |
| **ASC-024** | No ATT — correct if no tracking |
| **ASC-025** | Encryption export declaration — confirm still accurate |

---

## Already compliant (document in Review Notes)

| Area | Guideline | Status |
|------|-----------|--------|
| iOS donate Safari-only | 3.1.1 | OK in +69/+71 UI |
| Phone OTP / no SiWA | 4.8 | OK |
| Account deletion in-app | 5.1.1(v) | OK (API exists) |
| Background audio for radio | 2.5.4 | OK |
| YouTube embed, no download | 5.2.3 | OK |
| No READ_SMS / no SMS auto-read | — | OK |
| No “coming soon” core paths | 2.1 | OK |
| Not a thin web wrapper | 4.2 | OK |
| No ATT / no IDFA | 5.1 | OK |
| HTTPS production API | 2.5 | OK |
| +71 launch timeouts / no blank shrink | 2.1 | Fixed locally |

---

## Scenario matrix (must pass before submit)

| # | Scenario | Pass criteria |
|---|----------|---------------|
| 1 | Fresh install **iPhone** | Splash → Login (not blank) |
| 2 | Fresh install **iPad** (Air / iPadOS 26) | Splash → Login (not blank) — **critical** |
| 3 | Offline cold start | Offline splash + Retry (not empty) |
| 4 | Demo login | OTP works on production |
| 5 | Home tabs logged in | Radio, Events, Library, About, More all load |
| 6 | Live radio + lock screen | Pause/Stop enabled (+70/+71) |
| 7 | iOS Donate | Safari to rzp.io; **no** amount chips |
| 8 | Bank/QR visible | Informational only |
| 9 | YouTube play | Embed plays; attribution; no download |
| 10 | Event registration + file pick | Works; clear errors |
| 11 | Account delete | Confirm → signed out; cannot re-login same account |
| 12 | Privacy from More | Opens policy (HTML or Safari URL) |
| 13 | Decline push | App still usable |
| 14 | Wrong OTP | Clear error, not crash |
| 15 | Force update off | WP min ≤ 71 |

---

## Pre-submit gate (human checklist)

- [ ] Push **+71** to TestFlight  
- [ ] iPad cold launch OK (uninstall → install → open)  
- [ ] Demo phone + OTP tested on **radioudaan.com**  
- [ ] Privacy policy updated for app data  
- [ ] App Privacy labels: phone, name, email, files, crash, push, donations  
- [ ] Info.plist camera/mic fixed  
- [ ] Review Notes = Safari donate + build **71** + demo  
- [ ] Trust/80G PDF attached (optional but recommended)  
- [ ] WP force-update min ≤ 71  
- [ ] Age rating still **4+**  
- [ ] Screenshots match current UI (esp. Donate)

---

## Recommended fix order (engineering)

1. Push +71 (iPad blank)  
2. Privacy URL fallback in More tab  
3. Remove or rewrite unused camera/mic plist strings  
4. Push pre-prompt (or defer sync)  
5. Privacy policy content (human/legal)  
6. Soften account-deletion copy  
7. Optional: radioudaan.com associated domains  

---

*Audit compiled from dual specialist passes + store-compliance.md. Re-run before every ASC submit.*
