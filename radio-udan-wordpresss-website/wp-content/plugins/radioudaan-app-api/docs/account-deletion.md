# In-app account deletion (Apple Guideline 5.1.1(v))

Radio Udaan’s mobile “account” is **phone OTP login** managed by the App API plugin—not a WordPress user account.

## API

| Item | Value |
|------|--------|
| Method | `POST` |
| Path | `/wp-json/radioudaan/v1/auth/account/delete` |
| Auth | `Authorization: Bearer {token}` (same session as other protected routes) |
| Handler | `RadioUdaan_App_Api::auth_account_delete()` |
| User store | `RadioUdaan_App_Users::delete_by_phone()` → table `{prefix}ru_app_users` |

### Response (200)

```json
{
  "status": "account_deleted",
  "removed": true
}
```

- `removed: false` if no row existed (e.g. already deleted); the bearer token is still revoked.
- Client clears local session after success (Flutter: More → Delete account).

## What is deleted

| Data | Deleted? | Notes |
|------|----------|--------|
| App login profile (`wp_ru_app_users`) | **Yes** | Phone, first/last login timestamps, login count |
| Current bearer session | **Yes** | Transient `radioudaan_app_token_{token}` removed via `RadioUdaan_App_Auth::revoke_token()` |
| Other devices’ bearer tokens (same phone) | **No** | Only the token sent on the delete request is revoked; other tokens expire after 7 days |
| Pending OTP codes | **No** | Expire naturally (~5 min) |
| OTP / upload rate-limit counters | **No** | Short-lived transients (`ru_rl_*`, `otp_*`) |

## What is retained (by design)

| Data | Retained? | Notes |
|------|-----------|--------|
| Forminator event entries | **Yes** | Submissions under **Event entries**; include `_radioudaan_phone_e164` and form fields (name, documents, audio, etc.) |
| Media attached to entries | **Yes** | WordPress attachments / private upload paths referenced in Forminator |
| Staged uploads not yet submitted | **Usually expires** | Transient `radioudaan_upload_*` (24h TTL); files may remain until cron cleanup |
| Debug logs (`WP_DEBUG_LOG`) | **Maybe** | Phones masked in `RadioUdaan_App_Logger`; not purged on delete |

The Flutter app discloses this before delete: event registrations are **not** removed.

## Re-login after delete

A user may sign in again with the same phone number. OTP verify creates a **new** `wp_ru_app_users` row. Historical login stats from the deleted row are gone; **event entries from before delete remain**.

## Extension hook

After delete, WordPress fires:

```php
do_action( 'radioudaan_app_account_deleted', $phone_e164, $removed );
```

Use this (in a small custom plugin or theme) to purge additional data—for example anonymizing Forminator entries—if policy requires it. The core plugin intentionally does **not** delete registrations automatically.

## App Review notes

- Deletion is initiated **in the app** (More tab), not via email or web-only flow.
- No extra steps beyond bearer auth on the delete request.
- Privacy Policy should state that event submissions may be kept for operational/legal reasons; account deletion removes the app login record and ends the current session.
