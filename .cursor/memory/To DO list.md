# Radio Udaan — To DO list

Track progress here. Check boxes when done: `- [x]`. Partial: note in **Status** column.

**Legend:** ✅ Done · 🟡 Partial · ⬜ Not started · ❓ Needs your decision

**Last reviewed:** 2026-06-25

---

## P0 — Deploy blockers (do first)

- [x] Re-deploy **full** `radioudaan-app-api` plugin to staging (include fixed `require_once` for copy catalog) — **local:** verified at `https://radio` (354 copy keys, 2026-06-25)
- [x] Confirm wp-admin loads (no critical error) — **local** `https://radio` PASS (2026-06-25)
- [x] Confirm `GET /config` returns **≥300** copy keys on staging — **local:** 354 ✅ · **staging:** 17 ⬜ (needs plugin upload)
- [ ] Commit + push local changes (icons, WP copy, Flutter migration)
- [ ] Bump build to **2.0.0+16** and trigger CI (APK + TestFlight)

---

## P1 — Features & bugs

| Done | Task | Status | Notes |
|:----:|------|--------|-------|
| [ ] | Add app icon | 🟡 | Generated locally (`flutter_launcher_icons`); not committed / not in TestFlight |
| [ ] | Everything works on Android and iOS | 🟡 | TestFlight 2.0.0+15 OK; large local changes unshipped; full device QA open |
| [x] | Remove top-left **More** menu (☰) | ✅ | Removed from `main_tab_app_bar.dart`; profile top-right + bottom More tab unchanged |
| [ ] | Check schedule properly | 🟡 | Schedule API + UI exist; needs QA on real broadcast data |
| [ ] | Live radio works in **background** | 🟡 | `audio_service` + Android FGS wired; needs iOS + Android device QA |
| [ ] | Ask notification permission on **app open**, not when playing | ⬜ | Today: media permission on play; push in `push_notification_service` — redesign needed |
| [ ] | If user **blocks** notification, audio should still play? | ❓ | Product decision — Android 13+ FGS may need notification; document + graceful fallback |
| [ ] | YouTube: “video unavailable” + endless loader (mobile) | ⬜ | Open bug — embed/API/device investigation |
| [ ] | Events page shows **website event page** | ⬜ | Today: API cards only; no WP page content in app |
| [ ] | About Us, Privacy, Terms **stay in the app** | 🟡 | Today: external browser via `url_launcher`; need in-app WebView screens |
| [ ] | Verify email — full flow working | 🟡 | Screen + routes exist; E2E on staging needs QA |
| [ ] | **Saved** favorites — list UI + **DB** (not local only) | ⬜ | Can save shows/videos; no Saved screen; radio/library = local storage; need WP API |
| [ ] | Event registration success/error — clear, polished UI | 🟡 | Messages + `liveRegion` exist; improve visual design |
| [ ] | Improve **Notifications** read/unread section | ⬜ | Needs UX suggestion + implementation |

---

## P2 — Accessibility & quality bar

| Done | Task | Status | Notes |
|:----:|------|--------|-------|
| [ ] | Test **VoiceOver** (iOS) on all main flows | 🟡 | June 2026 audit done; manual sign-off required |
| [ ] | Test **TalkBack** (Android) on all main flows | 🟡 | Same as above |
| [ ] | All screens **responsive** | 🟡 | Phone-first; tablet/desktop not verified |
| [ ] | All screens **accessible** | 🟡 | Semantics in place; device verification open |
| [ ] | All screens **secure** | 🟡 | Baseline OK; full security pass not done |
| [ ] | All screens **fast** | 🟡 | Config cache / SWR; perf not fully profiled |
| [ ] | All screens **easy to use** | ⬜ | User testing |
| [ ] | All screens **easy to maintain** | 🟡 | WP copy migration in progress locally |
| [ ] | All screens **easy to test** | 🟡 | `staging-api-smoke.sh`, `verify-wp-plugin.sh`, verification gate rule |
| [ ] | All screens **easy to deploy** | 🟡 | GitHub CI; WP deploy manual |
| [ ] | All screens **easy to scale** | ⬜ | Not assessed |

---

## P3 — Platforms & production

| Done | Task | Status | Notes |
|:----:|------|--------|-------|
| [ ] | **iPad** layout / UX | ⬜ | |
| [ ] | **Mac desktop** (Flutter) | 🟡 | Web runs; native macOS not targeted |
| [ ] | **Android tablet** | ⬜ | |
| [ ] | **Desktop / web** tester build | 🟡 | `flutter run -d chrome --web-port=8765` + staging API |
| [ ] | Test **live production** build end-to-end | ⬜ | Production MSG91, policies, store metadata |

---

## Verification (run before marking any P1 item “done”)

```bash
cd radio_udaan_app && dart analyze lib
bash scripts/verify-wp-plugin.sh
bash scripts/staging-api-smoke.sh
```

See `.cursor/rules/verification-gate.mdc` and `.cursor/memory/release-state.md`.

---

## Your backlog (add new items below)

- [ ] 
- [ ] 
- [ ] 

---

## Completed (move items here when done)

- [x] Fix WP fatal: missing `require_once` for `class-app-copy-catalog.php` (local, 2026-06-25)
- [x] Add mandatory verification pipeline rule (`verification-gate.mdc`)
