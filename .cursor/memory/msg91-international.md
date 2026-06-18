# MSG91 international E.164 support (Radio Udaan)

**Last reviewed:** 2026-06-13  
**Scope:** OTP SMS for worldwide app users

## Current architecture

- **App + API:** Accept any valid E.164 (`+[1-9]\d{7,14}`). Flutter uses country picker; default India.
- **OTP service:** `RadioUdaan_Otp_Service` generates OTP, stores transient, fires `radioudaan_app_api_send_otp`.
- **SMS provider:** Single implementation — `RadioUdaan_Otp_Msg91`.

## What MSG91 integration does today

| Setting | Source |
|---------|--------|
| Auth key | `radioudaan_msg91_auth_key` or `RADIOUDAAN_MSG91_AUTH_KEY` |
| Sender ID | `radioudaan_msg91_sender_id` (default `RADIO`) |
| DLT template | `radioudaan_msg91_template_id` (India TRAI) |

**Send path:**
1. Skip if MSG91 not configured or dev OTP enabled.
2. Strip `+` and non-digits from E.164 → `mobiles` field.
3. POST plain-text message to `https://api.msg91.com/api/sendhttp.php`.
4. Attach `DLT_TE_ID` when template ID set.
5. Log HTTP errors only when `WP_DEBUG`; **never fail the OTP API response**.

**OTP purposes (all use same SMS path):** `login`, `verify_phone`, `reset_password`.

## India vs international

| Number | Example | Expected today |
|--------|---------|----------------|
| India | `+919876543210` → `919876543210` | Works if MSG91 + DLT configured |
| US | `+14155551234` → `14155551234` | Unreliable / likely fails on sendhttp + DLT |
| Other | `+44…`, `+971…`, etc. | Same risk |

## Risks (non-+91)

1. User receives `request_id` but no SMS (silent failure).
2. DLT template invalid for non-India destinations.
3. Registration stuck at phone verification.
4. App marketed worldwide; SMS backend India-only.

## Provider abstraction hook

`do_action( 'radioudaan_app_api_send_otp', $phone_e164, $otp )` — add country-aware dispatcher or second provider without changing OTP verify logic.

## Recommended paths

### 1. MSG91 international (preferred if staying on MSG91)
- Enable international SMS on MSG91 account.
- Use MSG91 Flow / v5 API for non-India; keep sendhttp + DLT for +91 only.
- Do not send `DLT_TE_ID` for non-India numbers.

### 2. Twilio fallback
- Hook same action; route by country code prefix.
- India → MSG91; rest → Twilio Verify or Messages API.

### 3. Email-only interim (non-India)
- Reject or redirect SMS OTP when country ≠ 91.
- Use existing email verification + forgot-password email flows.
- Extend `auth_policy` in GET `/config` for app UX.

### 4. Operational (any path)
- Surface SMS send failures to API (stop returning success when provider fails).
- Admin dashboard: show domestic vs intl provider status.

## Related files

- `includes/class-otp-msg91.php` — MSG91 send
- `includes/class-otp-service.php` — OTP façade + E.164 validation
- `includes/class-app-password-auth.php` — registration / forgot password
- `radio_udaan_app/lib/core/utils/phone_e164.dart` — client E.164
