#!/usr/bin/env bash
# Load-test PLAN for registration/OTP endpoints — does NOT hammer staging.
# Always exits 0 (documentation + dry-run counters only).
# Usage: bash scripts/load-test-registration-plan.sh
# Optional: DRY_RUN_ITERATIONS=5 bash scripts/load-test-registration-plan.sh
set -uo pipefail

STAGING_BASE="${STAGING_API_BASE:-https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1}"
STAGING_BASE="${STAGING_BASE%/}"
DRY_RUN_ITERATIONS="${DRY_RUN_ITERATIONS:-3}"

echo "================================================================"
echo "Radio Udaan — Registration load test PLAN (no full 10k run)"
echo "Target (when executed for real): $STAGING_BASE"
echo "Mode: PLAN + dry-run ($DRY_RUN_ITERATIONS simulated iterations)"
echo "================================================================"
echo ""

cat << 'GUIDE'
## Safety rules (staging)

1. Coordinate with backend before any load above ~10 req/min on OTP routes.
2. MSG91 / SMS provider billing and rate limits apply — never loop 10k OTP sends.
3. Prefer load against a dedicated test WP + mock OTP provider, not production SMS.
4. Watch for HTTP 429 from WordPress/plugin rate limiters; back off exponentially.
5. Do not use real user phone numbers; use +9198xxxxxxxx test range if API allows.
6. Registration POST creates DB rows — use unique emails/phones per virtual user.

## Recommended approach

| Tool   | Use case                                      |
|--------|-----------------------------------------------|
| k6     | Scripted VUs, thresholds, JSON metrics        |
| curl   | Single-thread sanity before k6                |
| bash   | Small bounded loops with sleep (this template)|

## k6 template (save as scripts/k6-registration.js — NOT run by this script)

  import http from 'k6/http';
  import { sleep, check } from 'k6';

  export const options = {
    stages: [
      { duration: '30s', target: 5 },   // ramp
      { duration: '1m', target: 5 },    // steady — keep low on staging
      { duration: '15s', target: 0 },
    ],
    thresholds: {
      http_req_failed: ['rate<0.05'],
      http_req_duration: ['p(95)<3000'],
    },
  };

  const BASE = __ENV.STAGING_API_BASE || 'https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1';

  export default function () {
    const id = `${__VU}-${__ITER}-${Date.now()}`;
    const body = JSON.stringify({
      name: 'Load Test',
      email: `load-${id}@example.com`,
      phone_e164: `+9199${String(id).slice(-9).padStart(9, '0')}`,
      password: 'TestPass123!',
    });
    const res = http.post(`${BASE}/auth/register`, body, {
      headers: { 'Content-Type': 'application/json' },
    });
    check(res, { 'register accepted or rate limited': (r) => r.status === 200 || r.status === 429 });
    sleep(1); // ~1 RPS per VU max
  }

  Run (only after approval):
    k6 run -e STAGING_API_BASE="$STAGING_BASE" scripts/k6-registration.js

## curl one-shot (manual)

  curl -sS -X POST "$STAGING_BASE/auth/register" \\
    -H 'Content-Type: application/json' \\
    -d '{"name":"Probe","email":"probe-UNIQUE@example.com","phone_e164":"+919876543210","password":"TestPass123"}'

## bash bounded loop template (rate-aware)

  for i in $(seq 1 20); do
    STAMP=$(date +%s)-$i
    curl -sS -o /dev/null -w "%{http_code}\\n" -X POST "$STAGING_BASE/auth/register" \\
      -H 'Content-Type: application/json' \\
      -d "{\\"name\\":\\"Load\\",\\"email\\":\\"load-$STAMP@example.com\\",\\"phone_e164\\":\\"+9198${STAMP: -9}\\",\\"password\\":\\"TestPass123\\"}"
    sleep 2   # 0.5 req/s — increase only with explicit approval
  done

GUIDE

echo ""
echo "== Dry-run: would issue $DRY_RUN_ITERATIONS registration POSTs (not sending) =="
for i in $(seq 1 "$DRY_RUN_ITERATIONS"); do
  STAMP="$(date +%s)-$i"
  echo "  [dry-run $i/$DRY_RUN_ITERATIONS] POST .../auth/register email=load-${STAMP}@example.com (skipped)"
done

echo ""
echo "== Preflight: GET /health (single request, read-only) =="
if command -v curl >/dev/null 2>&1; then
  HC="$(/usr/bin/curl -sS --connect-timeout 8 --max-time 15 -o /dev/null -w "%{http_code}" "$STAGING_BASE/health" 2>/dev/null || echo "000")"
  echo "  HTTP $HC on GET /health"
else
  echo "  curl not found — skip preflight"
fi

echo ""
echo "Plan complete. No load generated. Exit 0."
exit 0
