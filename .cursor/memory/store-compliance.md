# App Store & Google Play Compliance — Radio Udaan
<!-- READ before Flutter coding and before every release. -->

**Last verified:** 3 June 2026 (official Apple Developer News + Google Play Help Center)

## 2026 policy calendar (what matters for Radio Udaan)

| Date | Platform | Requirement | Impact on this app |
|------|----------|-------------|-------------------|
| **31 Jan 2026** | Apple | Updated **age rating** questions in App Store Connect | Complete questionnaire before each submission |
| **6 Feb 2026** | Apple | Guidelines clarify **random/anonymous chat** → Guideline **1.2 UGC** | **N/A** unless you add chat; event forms are private registrations, not public UGC feeds |
| **28 Apr 2026** | Apple | Uploads must use **Xcode 26+** and **iOS 26 SDK** | **Required now** for new iOS builds submitted to App Store Connect |
| **31 Aug 2025** | Google Play | New apps & updates must **target API 35** (Android 15) | **Required now** — set `targetSdkVersion` / Flutter `compileSdk` to 35+ |
| **31 Aug 2025** | Google Play | Existing apps must target **API 34+** for discoverability | Compliant if you ship updates on API 35 |
| **15 Apr 2026** | Google Play | Policy announcement (contacts, location button, account transfer) | See “Upcoming” row; most items **not** in v1 scope |
| **~15 May 2026** | Google Play | At least **30 days** after Apr 15 to comply with some April changes | Review [Policy Deadlines table](https://support.google.com/googleplay/android-developer/table/12921780) before submit |
| **28 Oct 2026** | Google Play | **Contacts** + **Location** permission policy updates (picker / location button) | **N/A** if app does not request contacts or location |

Re-check Apple [Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/) and Play [announcements](https://support.google.com/googleplay/android-developer/announcements/13412212) within 2 weeks of each store submission.

## How to use this file
- **All agents** must check relevant sections before implementing auth, uploads, library/YouTube, background audio, or release tasks.
- **Agent 14** owns policy text; **Agent 09** owns release checklist; **Agent 05/06/07/08** own implementation compliance.
- When store rules change, update this file and log in `decisions.md`.

---

## Radio Udaan — product-specific rules (DO / DON'T)

### DO
| Area | Requirement |
|------|-------------|
| **OTP login** | User **manually enters** SMS code from your server (MSG91). **Do not** read SMS on device. |
| **Sign in with Apple** | **Not required** — you use your **own** phone OTP (Apple 4.8: exception for company-owned account system). |
| **Privacy** | Public **Privacy Policy** URL in App Store Connect + Play Console + **in app** (More tab). |
| **Account deletion** | **In-app account deletion** (or delete request flow) — required because you create accounts via OTP (Apple 5.1.1(v)). |
| **App Review** | Provide **demo login**: test phone + dev OTP instructions, or built-in demo mode (Apple 2.1(a)). |
| **Live radio** | Use **background audio** mode correctly (iOS `audio` background mode; Android foreground service for media). |
| **YouTube / library** | Use **official YouTube IFrame Player API** (or compliant embed). **Stream only** — no download/save YouTube video. Show YouTube branding/attribution per API terms. Player min size ~200×200px with visible controls. |
| **Uploads** | Request camera/mic/**storage** only when user starts upload. Prefer **system pickers** (Photo Picker / document picker) over broad `READ_MEDIA_*` on Android. |
| **Accessibility** | **VoiceOver + TalkBack** on every screen — ship blocker for this product (not optional). |
| **Data disclosure** | Complete **Apple App Privacy** labels and **Google Play Data safety** to match real behavior (phone, files, audio, identity docs). |
| **Permissions** | Request **incrementally** with clear in-app explanation before system dialog. |
| **Metadata** | Screenshots show real app UI; description matches features (events, radio, library, OTP). |
| **API URL** | Production app points to production API; review build uses stable backend. |

### DON'T
| Area | Violation risk |
|------|----------------|
| **READ_SMS / RECEIVE_SMS** | **Never** declare on Android — not default SMS app. Google will reject. |
| **Auto-read OTP from SMS** | Avoid unless using **SMS Retriever API** without broad SMS permissions; manual entry is safest. |
| **Download YouTube** | No save/convert/offline YouTube content (Apple 5.2.3). |
| **WebView registration** | No web forms for event signup — in-app only (product rule + review quality). |
| **Force permissions** | No blocking app until user grants tracking, notifications, or unrelated access. |
| **Sell/share PII** | No selling phone numbers, UDID scans, or registrations for ads (Google User Data policy). |
| **Kids Category** | Do not market as kids app unless you implement Kids Category rules. |
| **Placeholder** | No empty About/Contact, broken links, or “coming soon” core tabs at submission. |
| **Misleading metadata** | No promise of features not in build. |

---

## Apple App Store (iOS)

### Review essentials
- **Guideline 2.1** — Complete app; no crashes; **demo account** or demo mode for login.
- **Guideline 4.8** — Sign in with Apple only if you add Google/Facebook/Twitter login; **phone OTP only = OK without Apple Sign In**.
- **Guideline 5.1** — Privacy policy link in metadata **and** in app; accurate **Privacy Nutrition Labels**.
- **Guideline 5.1.1(v)** — **Account deletion in app** (OTP creates an account).
- **Guideline 5.2.3** — Third-party video (YouTube): **authorized streaming/embed only**, no downloading.
- **Guideline 2.5.4** — Background audio only for playback (radio), not unrelated tasks.
- **Guideline 1.1.6** — No fake location / prank SMS apps (not applicable if implemented seriously).

### Accessibility (Apple)
- Support **VoiceOver**: labels, traits, focus order, announcements for errors and loading.
- Respect **Dynamic Type** / larger text where possible.
- **Accessibility Nutrition Labels** in App Store Connect when available — document features (VoiceOver, Voice Control, etc.) honestly.

### iOS technical (2026 build requirements)
- **Xcode 26+** and **iOS 26 SDK** required for App Store Connect uploads since **28 April 2026** ([SDK minimum requirements](https://developer.apple.com/news/upcoming-requirements/?id=02032026a)).
- Use **ATS (HTTPS)** for all API calls (local dev exception only in debug builds).
- **Photo/Camera/Microphone** — purpose strings in `Info.plist` must match real use (upload registration files).
- **App Tracking Transparency** — only if you track across apps; avoid unnecessary analytics SDKs.
- **Push notifications** — optional; if added later, request after explaining value, not at first launch.

### iOS submission checklist
- [ ] Built with **Xcode 26+** / **iOS 26 SDK** (post–Apr 2026)
- [ ] **Age rating** questionnaire completed in App Store Connect
- [ ] Privacy Policy URL live
- [ ] App Privacy questionnaire matches data collection
- [ ] Demo credentials in App Review notes (phone + how to get OTP)
- [ ] Account deletion path tested
- [ ] VoiceOver pass on main flows
- [ ] YouTube player uses compliant API / embed
- [ ] Background radio tested (lock screen, interrupt, route change)
- [ ] No debug/dev menus in production build

---

## Google Play (Android)

### Policy essentials
- **User Data policy** — Declare all collected data in **Data safety** form; no undisclosed sharing.
- **SMS/Call log** — **Do not** request `READ_SMS`, `RECEIVE_SMS`, etc. (default handler only). Radio Udaan uses **server OTP + manual entry**.
- **Permissions** — Only permissions needed for **promoted features**; use **Photo Picker** / SAF instead of broad media read when possible (Android 13+).
- **Target API level** — As of **June 2026**, new apps and updates must **target Android 15 (API level 35)**. Existing published apps need **API 34+** minimum. Flutter: align `compileSdkVersion` / `targetSdkVersion` with Play Console before release.
- **Photo/video (2026)** — Prefer **Android Photo Picker** / SAF for registration uploads. If you declare `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` on API 33+, you need a **Play Console declaration** explaining why the picker is insufficient.
- **Deceptive behavior** — App must match store listing; no hidden features.

### Android technical
- **Foreground service** type `mediaPlayback` for radio in background (with visible notification).
- **POST_NOTIFICATIONS** — only if you show notifications; explain first on Android 13+.
- **No SMS Retriever required** — optional optimization only; manual OTP is compliant.
- **Cleartext traffic** — disable in release (`usesCleartextTraffic=false`); use HTTPS API.
- **64-bit** — required (Flutter default).

### Play submission checklist
- [ ] **targetSdkVersion 35** (Android 15) for new submission
- [ ] Data safety form: phone number, name, email, files, audio, device IDs (if any)
- [ ] Privacy policy URL
- [ ] Content rating questionnaire accurate
- [ ] No SMS/Call log permissions in manifest
- [ ] Target SDK meets Play requirements
- [ ] TalkBack pass on main flows
- [ ] Release signing + Play App Signing configured

---

## OTP & phone number (both stores)

| Approach | Store-safe? |
|----------|-------------|
| Server sends SMS; user types code in app | **Yes** (recommended) |
| READ_SMS / listen for SMS | **No** (unless default SMS app) |
| SMS Retriever API (hash, no READ_SMS) | **Yes** (optional UX improvement) |
| MSG91 via your WP API | **Yes** — disclose in privacy policy as processor |

**India operations:** MSG91 **DLT template** registration is a **legal/telecom** requirement, not an app-store rule — still required for production SMS.

---

## YouTube / in-app library (both stores)

- Use **YouTube IFrame Player API** or official embed in WebView — complies with YouTube Terms if you **do not** strip branding, block ads against ToS, or enable download.
- **Do not** present as “download videos” or offline YouTube library.
- **Do not** scrape YouTube.
- Player UI must be **accessible** (focusable controls, labels for play/pause).
- If YouTube blocks embed for a video, show clear error in-app (not external browser for primary flow unless fallback documented).

---

## Sensitive data in Radio Udaan (disclosure reminder)

| Data | Purpose | Disclose in |
|------|---------|-------------|
| Phone (E.164) | OTP login, account | Privacy policy, App Privacy, Data safety |
| Name, email, address | Event registration | Same |
| Photos/PDF/audio/video files | Registration uploads (e.g. UDID) | Same; mention storage on server |
| Device/app version | Support, abuse prevention | Same (optional collection) |
| Stream listening | Radio feature | No personal data if no login required for radio |

---

## Release coordination (Agents)

| Agent | Responsibility |
|-------|----------------|
| **14 Legal** | Privacy Policy, Terms, store questionnaire answers |
| **09 QA** | Store checklist + regression before submit |
| **06 A11y** | TalkBack/VoiceOver signoff |
| **04 Security** | Permissions audit, data flow |
| **05 Flutter** | Implement DO/DON'T in code |
| **03 WP API** | Privacy URLs, account deletion API if needed |

---

## Open items before first store submit (human + Agent 14)

1. Final **Privacy Policy** and **Terms** URLs on radioudaan.com (or approved domain).
2. **Account deletion** — implement in app + confirm WP deletes/anonymizes data (Gate D).
3. **MSG91** production + DLT template (India).
4. Confirm **no** analytics SDK until disclosures updated (or pick privacy-friendly crash tool e.g. Firebase with data safety declared).
5. **Content rating** (likely Everyone / Teen — no gambling; user-generated content via forms — answer honestly).

---

## Google Play — April 2026 (mostly N/A for v1)

From [Policy announcement: April 15, 2026](https://support.google.com/googleplay/android-developer/answer/16926792):

- **Contacts Permissions** — use Contact Picker, not broad `READ_CONTACTS`, unless core feature needs it → **we do not use contacts in v1**.
- **Location** — “location button” as minimum scope for precise location → **we do not use location in v1**.
- **Account Transfer** — Play Console ownership transfer workflow → **org/admin only**, not app code.
- **Photo/video clarifications** — reinforces picker-first approach for uploads (aligns with our DO list).

## Official reference links

- Apple App Review Guidelines (Feb 2026 UGC chat clarification): https://developer.apple.com/news/?id=d75yllv4
- Apple App Review Guidelines (full): https://developer.apple.com/app-store/review/guidelines/
- Apple SDK minimum requirements (Apr 2026): https://developer.apple.com/news/upcoming-requirements/?id=02032026a
- Google Play target API level: https://support.google.com/googleplay/android-developer/answer/11926878
- Google Play April 2026 policies: https://support.google.com/googleplay/android-developer/answer/16926792
- Apple Offering account deletion: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Google Play User Data policy: https://support.google.com/googleplay/android-developer/answer/10144311
- Google SMS/Call log permissions: https://support.google.com/googleplay/android-developer/answer/16558241
- YouTube IFrame Player API: https://developers.google.com/youtube/iframe_api_reference
- YouTube API Terms of Service: https://developers.google.com/youtube/terms/api-services-terms-of-service
