# App Store / Play — Razorpay donations (paste into App Review notes)

## What reviewers should know

- **Product**: Radio Udaan — community radio app for blind and low-vision users in India.
- **Donations**: Voluntary charitable contributions to **Udaan Empowerment Trust** (registered nonprofit). Not digital goods, subscriptions, or in-app unlocks.
- **Payment processor**: Razorpay (India). Server creates orders; app never stores card/UPI credentials.
- **iOS**: Payment opens in **Safari** via Razorpay Payment Link (Guideline 3.2.2 charitable donation flow). User returns via deep link `radioudaan://donate/verify` or taps “I completed payment”.
- **Android**: Native Razorpay checkout SDK after server order creation.
- **80G**: Optional tax receipt — donor may enter PAN only when opting in. PAN encrypted on server; not logged.

## Demo / test

1. Open **About** tab → **Donate Us**.
2. If **Pay Online** is visible, WP admin has Razorpay enabled with test/live keys.
3. Choose preset or custom amount → **Donate now**.
4. Complete Razorpay test payment (test cards in Razorpay docs).
5. Success message after server verification.

**Without live keys**: Scan & Donate (UPI QR) and bank transfer remain available — no payment required for review of other features.

## Privacy

- Privacy Policy must mention donations, Razorpay, optional PAN for 80G receipts.
- Apple App Privacy / Google Data safety: payment info processed by Razorpay; PAN only when user opts into 80G.

## Entity

- Receiving entity name in Razorpay dashboard must match trust name shown in app checkout (`checkout_name` from WP config).
