# Radio Udaan — Release checklist

Condensed from `.cursor/memory/store-compliance.md`. Complete every **applicable** item before App Store Connect / Play Console submission. Full policy context and links live in that file.

**Review build API:** stable production or staging HTTPS endpoint (not local `https://radio/` unless reviewers can reach it).  
**App Review demo:** document test phone + how to obtain OTP (dev: `123456` when Development OTP enabled — **never** in production store builds).

---

## Pre-flight (both stores)

- [ ] `flutter analyze` clean; release build succeeds (Android + iOS)
- [ ] `dart run tool/live_api_check.dart` passes against target API
- [ ] `test-api-flow.sh` passes if registration schema unchanged
- [ ] Manual matrix in `TESTING.md` done on **Android device** + **iPhone**
- [ ] No `READ_SMS` / `RECEIVE_SMS` in Android manifest
- [ ] OTP: user **manually enters** SMS code (no auto-read SMS)
- [ ] Privacy Policy URL **live** — in store metadata **and** in-app (More tab)
- [ ] Terms / legal links work; no “coming soon” on core tabs
- [ ] In-app **account deletion** tested (`TESTING.md` → Account deletion)
- [ ] **TalkBack** + **VoiceOver** sign-off on main flows
- [ ] YouTube/library: **embed/stream only** — no download; branding visible
- [ ] Background **live radio** tested (lock screen, background, stop)
- [ ] Production build: **no** dev OTP, debug menus, or cleartext API
- [ ] App Privacy (Apple) + Data safety (Google) match real collection (phone, name, email, files, etc.)
- [ ] Screenshots and store description match shipped features

---

## Product DO / DON'T (quick audit)

| DO | DON'T |
|----|--------|
| Phone OTP via server (MSG91); manual entry | `READ_SMS`, auto-read SMS |
| In-app event registration only | WebView / web forms for signup |
| Account deletion in More tab | Force unrelated permissions at launch |
| Background audio for radio only | Download/save YouTube content |
| Request camera/mic/storage when user uploads | Sell or share PII for ads |
| Incremental permissions with explanation | Placeholder About/Contact or broken links |

**Sign in with Apple:** Not required (phone OTP only — no Google/Facebook login).

---

## Apple App Store (iOS)

### Build & SDK (2026)

- [ ] Built with **Xcode 26+** and **iOS 26 SDK** (required for App Store Connect uploads since 28 Apr 2026)
- [ ] All API traffic **HTTPS** (ATS); no debug base URL in release
- [ ] `Info.plist` purpose strings match real use (camera, mic, photos for registration uploads)
- [ ] Background mode **audio** only for live radio — not misused for other work

### App Store Connect

- [ ] **Age rating** questionnaire completed (updated questions — recheck each submission)
- [ ] Privacy Policy URL in metadata
- [ ] **App Privacy** labels accurate
- [ ] **Demo credentials** in App Review notes (phone + OTP instructions)
- [ ] **Accessibility Nutrition Labels** honest when applicable

### Regression (iOS)

- [ ] Account deletion path tested on device
- [ ] VoiceOver on login, OTP resend, tabs, radio, registration, library, More
- [ ] YouTube player compliant (IFrame/embed; accessible controls)
- [ ] Background radio: lock screen + interrupt handled

---

## Google Play (Android)

### Target SDK & build

- [ ] **targetSdkVersion 35** (Android 15) for new submission / updates
- [ ] Release signing + **Play App Signing** configured
- [ ] **Cleartext disabled** in release (`usesCleartextTraffic=false`); HTTPS API only
- [ ] **64-bit** ABI included (Flutter default)

### Play Console

- [ ] **Data safety** form: phone, name, email, files, audio, device/app version as collected
- [ ] Privacy policy URL
- [ ] **Content rating** questionnaire accurate
- [ ] No SMS/Call log permissions declared
- [ ] If `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` declared: Play **declaration** explains why Photo Picker is insufficient (prefer picker/SAF)

### Technical (Android)

- [ ] Foreground service type **`mediaPlayback`** for background radio + visible notification
- [ ] `POST_NOTIFICATIONS` only if used; explained before prompt on Android 13+

### Regression (Android)

- [ ] TalkBack on main flows
- [ ] Background radio + notification controls tested
- [ ] Registration uploads via system picker (not broad storage without justification)

---

## OTP & telecom (production)

- [ ] **MSG91** production credentials in WP (not dev fixed OTP)
- [ ] India **DLT SMS template** registered for production OTP texts
- [ ] Rate limiting / abuse controls acceptable under load
- [ ] Privacy policy mentions SMS processor (MSG91)

---

## Data & legal (human + legal review)

- [ ] Final Privacy Policy + Terms on approved domain (e.g. radioudaan.com)
- [ ] WP **account delete** API behavior confirmed (login removed; token revoked)
- [ ] Registrations retention after account delete documented for support
- [ ] No undisclosed analytics SDK — or disclosures updated if added
- [ ] Content rating answers honest (forms collect user data; not Kids Category unless intended)

---

## 2026 policy reminders (recheck within 2 weeks of submit)

| When | What |
|------|------|
| 28 Apr 2026+ | Apple: Xcode 26+ / iOS 26 SDK for uploads |
| Now | Google: target **API 35** for new apps/updates |
| Per submit | Apple age rating questionnaire; Play policy deadline table |

Official links: see **Official reference links** in `.cursor/memory/store-compliance.md`.

---

## QA sign-off

| Role | Sign-off |
|------|----------|
| QA | Manual `TESTING.md` matrix + regression sections above |
| Accessibility | TalkBack + VoiceOver |
| Security | Permissions + no PII in logs; HTTPS only |
| Legal | Privacy/Terms URLs + store questionnaires |

**Date / build / version:** _______________  
**Tester:** _______________
