# App Store / Play — Razorpay donations (paste into App Review notes)

## What reviewers should know

- **Product**: Radio Udaan — community radio app for blind and low-vision users in India.
- **Donations**: Voluntary charitable contributions to **Udaan Empowerment Trust** (registered nonprofit). Not digital goods, subscriptions, or in-app unlocks.
- **Payment processor**: Razorpay (India). App never stores card/UPI credentials.
- **iOS / iPad (Guideline 3.1.1 / charitable donations)**: **Safari link-out only.** The app does **not** show amount chips, create orders, or run in-app checkout. Tapping **Donate in Safari** opens the Razorpay payment page externally (`LaunchMode.externalApplication`). Default URL: `https://rzp.io/rzp/dswNW5g`. Prefer WP config `info_hub.donate.razorpay.ios_safari_payment_url` when set. Scan & Donate (UPI QR) and bank transfer remain in-app.
- **Android**: Native Razorpay checkout SDK after server order creation (`DonatePayOnlineCard`), when Razorpay is enabled in WP.
- **80G (Android native flow)**: Optional tax receipt — donor may enter PAN only when opting in. PAN encrypted on server; not logged.

## Demo / test

### iOS
1. Open **About** tab → **Donate Us**.
2. Confirm **no** Pay Online amount chips / in-app checkout.
3. Tap **Donate in Safari** → Safari opens Razorpay payment page.
4. Scan & Donate (QR) and bank details remain available.

### Android
1. Open **About** tab → **Donate Us**.
2. If **Pay Online** is visible, WP admin has Razorpay enabled with test/live keys.
3. Choose preset or custom amount → **Donate now**.
4. Complete Razorpay test payment (test cards in Razorpay docs).
5. Success message after server verification.

**Without live keys (Android)**: Scan & Donate (UPI QR) and bank transfer remain available — no payment required for review of other features. iOS still offers Safari payment link (config or default URL).

## Privacy

- Privacy Policy must mention donations, Razorpay, optional PAN for 80G receipts.
- Apple App Privacy / Google Data safety: payment info processed by Razorpay; PAN only when user opts into 80G.

## Entity

- Receiving entity: **Udaan Empowerment Trust** (shown in Safari donate copy / Razorpay checkout name from WP).
