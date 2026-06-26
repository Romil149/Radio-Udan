# Radio Udaan — To DO list

Track progress here. Check boxes when done: `- [x]`. Partial: note in **Status** column.

**Legend:** ✅ Done · 🟡 Partial · ⬜ Not started · ❓ Needs your decision

**Last reviewed:** 2026-06-25

---

## P0 — Deploy blockers (do first)

- [x] Re-deploy **full** `radioudaan-app-api` plugin to staging (include fixed `require_once` for copy catalog) — **local:** verified at `https://radio` (354 copy keys, 2026-06-25)
- [x] Confirm wp-admin loads (no critical error) — **local** `https://radio` PASS (2026-06-25)
- [x] Confirm `GET /config` returns **≥300** copy keys on staging — **local:** 354 ✅ · **staging:** 17 ⬜ (needs plugin upload)
- [x] Commit + push local changes (icons, WP copy, Flutter migration) — `e8d91ae` on `main` (2026-06-25)
- [x] Bump build to **2.0.0+16** and trigger CI (APK + TestFlight) — `74e2613` pushed (2026-06-25)

---

## P1 — Features & bugs

| Done | Task | Status | Notes |
|:----:|------|--------|-------|
| [x] | Add app icon | ✅ | Logo on black; Android + iOS generated; shipped in `e8d91ae` / build **+16** |
| [ ] | Everything works on Android and iOS | ⏭️ | Skipped for now — retest on build +16 when ready |
| [x] | Remove top-left **More** menu (☰) | ✅ | Removed from `main_tab_app_bar.dart`; profile top-right + bottom More tab unchanged |
| [~] | Check schedule properly | 🟡 | WP→Kolkata (you); plugin IST fallback kept; app shows dual time only if user TZ ≠ station; on-air from API |
| [x] | Live radio works in **background** | ✅ | User verified on Android + iOS (2026-06-25); report if regressions |
| [x] | Ask notification permission on **app open**, not when playing | ✅ | First-open a11y sheet on login/shell; Android media + FCM on Continue |
| [x] | If user **blocks** notification, audio should still play? | ✅ | Radio plays without permission; prompt removed from Play |
| [~] | YouTube: “video unavailable” + endless loader (mobile) | 🟡 | `youtube-nocookie.com` origin + 15s timeout + Retry only; needs device retest |
| [ ] | Event **banner / featured image** shows on event cards | 🟡 | API+UI wired; staging returns `banner_image: null`; local 1216 has image — env + where image was set |
| [x] | About Us, Privacy, Terms **stay in the app** | ✅ | WP page picker + `legal_pages` in `/config` (Elementor-aware); native HTML screen |
| [~] | **Saved** favorites — list UI + **DB** (not local only) | 🟡 | WP `/me/favorites` + Saved screen in Library; merge on login; plugin deploy + hot restart |
| [~] | Verify email — full flow working | 🟡 | Code done; staging plugin deploy + user QA |
| [~] | Event registration success/error — clear, polished UI | 🟡 | Success screen + top error banner; hot restart to test |
| [~] | Improve **Notifications** read/unread section | 🟡 | Unread styling, relative time, mark all read API, optimistic updates; hot restart |

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
