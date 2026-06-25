# iOS push notification setup (Radio Udaan)

Firebase project: **`radio-udan-2412a`**  
iOS bundle ID: **`org.reactjs.native.example.Radio`** (App Store Connect app `1439057220`)

This doc covers operator steps to enable APNs → FCM → app delivery. **Do not commit APNs keys, service account JSON, or `.p8` files to git.**

---

## 0. GitHub Actions → iOS IPA (manual TestFlight upload)

Workflow: `.github/workflows/build-ios-testflight.yml` (job name: **Build iOS IPA**)  
Setup script: `bash scripts/ios-github-secrets-setup.sh`

**GitHub secrets required (5):** `APPLE_TEAM_ID`, `IOS_DISTRIBUTION_CERTIFICATE_BASE64`, `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_PROVISIONING_PROFILE_NAME`

**No App Store Connect API key** unless you add automatic upload later.

After the workflow: **Actions** → run → **Artifacts** → download `.ipa` → upload with **Transporter** (Mac) → **TestFlight**.

---

## 1. Apple Developer — APNs authentication key

1. Sign in to [Apple Developer](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles**.
2. **Keys** → **+** → name e.g. `Radio Udaan APNs` → enable **Apple Push Notifications service (APNs)** → Continue → Register.
3. Download the **`.p8`** file once (cannot re-download). Store it in a password manager or secure vault — **not in the repo**.
4. Note the **Key ID** and your **Team ID** (Membership details).

The App ID `org.reactjs.native.example.Radio` must have **Push Notifications** capability enabled (Xcode or Developer portal).

---

## 2. Firebase Console — upload APNs key

1. Open [Firebase Console](https://console.firebase.google.com/) → project **`radio-udan-2412a`**.
2. **Project settings** (gear) → **Cloud Messaging** tab.
3. Under **Apple app configuration**, select the iOS app (`org.reactjs.native.example.Radio`).
4. **APNs Authentication Key** → Upload:
   - `.p8` file
   - **Key ID**
   - **Team ID**
5. Save. FCM can now relay messages to iOS devices via APNs.

Alternative (not preferred): APNs certificates — auth keys do not expire yearly.

---

## 3. Verify in-repo iOS config (already wired)

| Item | Location | Expected |
|------|----------|----------|
| Firebase plist | `radio_udaan_app/ios/Runner/GoogleService-Info.plist` | `PROJECT_ID` = `radio-udan-2412a`, `BUNDLE_ID` = `org.reactjs.native.example.Radio` |
| Dart options | `radio_udaan_app/lib/firebase_options.dart` | `iosBundleId: 'org.reactjs.native.example.Radio'` |
| Firebase init | `radio_udaan_app/ios/Runner/AppDelegate.swift` | `FirebaseApp.configure()` in `didFinishLaunchingWithOptions` |
| Background mode | `radio_udaan_app/ios/Runner/Info.plist` | `UIBackgroundModes` includes `remote-notification` |
| Client | `radio_udaan_app/lib/core/push/push_notification_service.dart` | Requests permission, registers FCM token with WP API |

After changing `GoogleService-Info.plist`, run `flutterfire configure` only if regenerating from Firebase — otherwise hand-edit bundle/project IDs to match.

---

## 4. WordPress server (FCM HTTP v1)

Push delivery from campaigns/admin uses the **Firebase service account JSON** in WP admin (Settings → Notifications), not the APNs key.

- APNs key → Firebase ↔ Apple
- Service account JSON → WordPress ↔ FCM HTTP v1

See `.cursor/memory/decisions.md` (FCM HTTP v1) and `class-app-fcm-sender.php`.

---

## 5. End-to-end test (physical iPhone recommended)

Push is unreliable on the **iOS Simulator**; use a real device for QA.

1. Build and run on device:  
   `cd radio_udaan_app && flutter run -d <device-id>`
2. Sign in; accept notification permission when prompted.
3. Confirm device registers: WP admin or API — user has a row in `ru_app_devices` with `platform=ios`.
4. WP Admin → **Radio Udaan App** → **Send notification** → target that user or all devices.
5. Expect notification when app is backgrounded; foreground shows via `flutter_local_notifications`.

**Troubleshooting**

| Symptom | Check |
|---------|--------|
| No token in WP | APNs key uploaded in Firebase? Permission granted on device? |
| Token but no delivery | Service account JSON in WP? Invalid tokens pruned in logs? |
| Works on Android, not iOS | Almost always missing/wrong APNs key in Firebase |

---

## 6. Secrets policy

| Secret | Store | Never commit |
|--------|-------|--------------|
| APNs `.p8` key | 1Password / CI secret | ✓ |
| Firebase service account JSON | WP admin or `wp-config.php` constant | ✓ |
| `GoogleService-Info.plist` | In repo (client config; restrict repo access) | API keys are public client keys — still no private keys in plist |

Do not paste Key ID, Team ID, tokens, or `.p8` contents into issues, chat logs, or memory files.

---

## 7. Release checklist (App Store)

- [ ] Push Notifications capability on App ID + provisioning profile
- [ ] APNs auth key uploaded in Firebase for production
- [ ] Test on TestFlight build (not just debug)
- [ ] Privacy copy mentions optional notifications if required by App Review
