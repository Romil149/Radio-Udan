#!/usr/bin/env bash
# Smoke test: forgot-password only uses verified email / verified phone channels.
set -euo pipefail
BASE="${API_BASE:-https://radio/wp-json/radioudaan/v1}"
STAMP="$(date +%s)"
EMAIL="fp-test-${STAMP}@example.com"
PHONE="+919${STAMP: -9}"
PASS="TestPass123!"

echo "== 1) Unknown email (generic ok, no OTP) =="
R1=$(curl -sS -X POST "$BASE/auth/forgot-password" \
  -H 'Content-Type: application/json' \
  -d "{\"identifier\":\"nobody-${STAMP}@example.com\"}")
echo "$R1"
echo "$R1" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('status')=='ok'; assert 'request_id' not in d"
echo "OK"
echo ""

echo "== 2) Register + verify phone (email still unverified) =="
REG=$(curl -sS -X POST "$BASE/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"FP Test\",\"email\":\"$EMAIL\",\"phone_e164\":\"$PHONE\",\"password\":\"$PASS\"}")
echo "$REG"
REQ=$(curl -sS -X POST "$BASE/auth/otp/request" \
  -H 'Content-Type: application/json' \
  -d "{\"phone_e164\":\"$PHONE\",\"purpose\":\"verify_phone\"}")
echo "OTP request: $REQ"
RID=$(echo "$REQ" | python3 -c "import json,sys; print(json.load(sys.stdin)['request_id'])")
OTP=$(echo "$REQ" | python3 -c "import json,sys; print(json.load(sys.stdin).get('dev_otp','123456'))")
curl -sS -X POST "$BASE/auth/otp/verify" \
  -H 'Content-Type: application/json' \
  -d "{\"request_id\":\"$RID\",\"otp\":\"$OTP\",\"purpose\":\"verify_phone\"}" | python3 -m json.tool
echo ""

echo "== 3) Forgot password by email (unverified — must NOT return request_id) =="
R3=$(curl -sS -X POST "$BASE/auth/forgot-password" \
  -H 'Content-Type: application/json' \
  -d "{\"identifier\":\"$EMAIL\"}")
echo "$R3"
echo "$R3" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('status')=='ok'; assert 'request_id' not in d; assert d.get('channel')!='email' or 'channel' not in d"
echo "OK (no SMS/email channel leaked in JSON)"
echo ""

echo "== 4) Forgot password by phone (verified — must return request_id) =="
R4=$(curl -sS -X POST "$BASE/auth/forgot-password" \
  -H 'Content-Type: application/json' \
  -d "{\"identifier\":\"$PHONE\"}")
echo "$R4"
echo "$R4" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('request_id'), 'expected OTP request_id for verified mobile reset'"
echo "OK"
echo ""
echo "All forgot-password channel checks passed."
