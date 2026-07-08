# Radio Udaan — VoiceOver / TalkBack device QA (release gate)

**Build:** staging APK/IPA with blind-user navigation a11y changes  
**Platforms:** iOS VoiceOver + Android TalkBack  
**Pass:** All steps below without duplicate speech, silent errors, or focus traps

## 1. Cold start → Live tab

1. Force-quit app; cold launch.
2. Complete OTP login if needed.
3. Confirm landing on **Live** tab.
4. Rotor / headings: screen title spoken as landmark.

## 2. Tab cycle (5 tabs)

Switch: Live → Library → Events → About → More.

| Check | Pass |
|-------|------|
| Each tab switch announces tab name once | ☐ |
| More tab with unread badge includes count in label | ☐ |
| Headings rotor lists active tab title | ☐ |
| No duplicate focus on tab content pane + first control | ☐ |

## 3. Radio (Live)

| Check | Pass |
|-------|------|
| Hero card: one stop (title + hosts merged) | ☐ |
| Play/Stop within ≤3 swipes from tab bar | ☐ |
| Open Schedule → hears modal title “Schedule” | ☐ |
| Share failure/success spoken (not SnackBar-only) | ☐ |

## 4. Library → player

| Check | Pass |
|-------|------|
| Video card: one semantic action (play/open) | ☐ |
| Player: Play, Pause, Open in YouTube only (no WebView controls) | ☐ |
| Description readable as single semantics node | ☐ |
| Embed error: spoken + Open in YouTube available | ☐ |

## 5. Events → registration

| Check | Pass |
|-------|------|
| Event card: one stop to Register | ☐ |
| Registration top bar shows **event title** (not app name) | ☐ |
| Context banner: summary + schedule before first field | ☐ |
| Form intro: “Registration for {title}, page 1 of N” | ☐ |
| Page next/back announces new page | ☐ |
| No focus trap in multi-page form | ☐ |

## 6. More → settings → back

| Check | Pass |
|-------|------|
| Legal/About HTML: h1–h4 in headings rotor | ☐ |
| Country picker opens as named modal | ☐ |
| Copy-to-clipboard actions spoken | ☐ |

## 7. Deep link (optional)

`radioudaan://event/{id}` or `/event/{id}`:

| Check | Pass |
|-------|------|
| Announces “Opening registration for {event}” | ☐ |
| Lands on registration with event context | ☐ |

## Sign-off

| Role | Name | Date | Result |
|------|------|------|--------|
| QA | | | PASS / FAIL |
| Real device | | | PASS / FAIL |
| Validator | | | PASS / FAIL |

Log results in `.cursor/memory/bugs-found.md` and `.cursor/memory/task-history.md`.
