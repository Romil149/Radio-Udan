# Secrets transfer checklist (staging → production)

Use **Radio Udaan App → Transfer secrets** in wp-admin. Do not commit the JSON file or email it.

## Steps

1. **Export on staging** ([nexusfleck radioudaan](https://nexusfleck.com/radioudaan/wp-admin/))
   - Open **Radio Udaan App → Transfer secrets**
   - Leave **Include secret values** checked (required for a real credential move)
   - Optionally check **Include copy overrides** if staging has custom copy
   - Click **Download secrets JSON** → save `radioudaan-app-secrets-YYYY-MM-DD.json` locally (not in git)

2. **Import on production** ([radioudaan.com](https://radioudaan.com/wp-admin/))
   - Deploy the plugin build that includes `class-admin-secrets-transfer.php` first
   - Open **Transfer secrets** → choose the JSON file
   - Defaults: import secrets, connection/URLs, donate, push (copy overrides off)
   - Leave **Rewrite staging URLs → production** checked so `https://nexusfleck.com/radioudaan` becomes `https://radioudaan.com` (including `…/wp-json/radioudaan/v1`)
   - Click **Import secrets** → confirm the success notice count

3. **Verify health**
   - Settings → Notifications: FCM project ID present; run FCM test if available
   - Settings → Connection: API base URL is `https://radioudaan.com/wp-json/radioudaan/v1`
   - Public config copy key count (expect ≥300 when full catalog is live):

```bash
curl -sS "https://radioudaan.com/wp-json/radioudaan/v1/config" | python3 -c "import json,sys; c=json.load(sys.stdin).get('copy',{}); print(len(c)); sys.exit(0 if len(c)>=300 else 1)"
```

4. **Delete the JSON** from your machine (and Downloads) after a successful import.

5. **App publish** — bake production API base in CI / release builds (`https://radioudaan.com/wp-json/radioudaan/v1`). Do not ship a TestFlight/APK still pointed at staging.

## What is in the JSON

| Group | Included |
|-------|----------|
| Secrets | MSG91 auth/sender/template, FCM service account + project id, Razorpay key id/secret/webhook secret, YouTube API key + channel |
| Connection | API base URL, stream URL, privacy/terms/about/contact/store URLs, support helpline + email |
| Donate | Razorpay enabled/checkout/presets, 80G flags/text/PAN/reg (not signatory attachment), UPI + bank fields + donate copy (not QR attachment id) |
| Push | Events / library / promotions notification defaults |
| Optional | `radioudaan_copy_overrides` when export checkbox is on |

Redacted export (secrets checkbox off): secret fields listed as `[REDACTED]`; import always skips `[REDACTED]` and empty secret strings.

## What is NOT in the JSON

- Flutter Firebase files (`google-services.json`, `GoogleService-Info.plist`)
- APNs Auth Key (Firebase Console)
- GitHub Actions signing / store secrets
- Media attachment IDs (logo, donate QR, 80G signatory) — re-upload on production
- Dev OTP / rate-limit / upload MIME settings (not part of this transfer)
- Sample JSON with real keys (never create one in the repo)

## Operator reminders

- Capability: `manage_options` only; all actions use nonces
- Never log secret values; admin notices report counts only
- After import, plugin invalidates `RadioUdaan_App_Config` cache when available
