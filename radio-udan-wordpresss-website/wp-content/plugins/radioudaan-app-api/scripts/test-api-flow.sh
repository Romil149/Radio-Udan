#!/usr/bin/env bash
# Quick local smoke test for radioudaan-app-api (requires https://radio/ and dev OTP).
set -euo pipefail
BASE="https://radio/wp-json/radioudaan/v1"
PHONE="+919888877766"

echo "Config:"
curl -sS "$BASE/config" | python3 -m json.tool
echo ""
TMP="$(mktemp -d)"
echo '%PDF-1.4' > "$TMP/udid.pdf"
printf 'ID3\x03\x00\x00\x00\x00\x00\x00' > "$TMP/audio.mp3"

REQ=$(curl -sS -X POST "$BASE/auth/otp/request" -H 'Content-Type: application/json' -d "{\"phone_e164\":\"$PHONE\"}")
echo "OTP request: $REQ"
RID=$(echo "$REQ" | python3 -c "import json,sys; print(json.load(sys.stdin)['request_id'])")
OTP=$(echo "$REQ" | python3 -c "import json,sys; print(json.load(sys.stdin).get('dev_otp','123456'))")
TOKEN=$(curl -sS -X POST "$BASE/auth/otp/verify" -H 'Content-Type: application/json' -d "{\"request_id\":\"$RID\",\"otp\":\"$OTP\"}" | python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")
echo "Token acquired"
curl -sS "$BASE/auth/me" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
echo ""

EVENT_ID=$(curl -sS "$BASE/events" | python3 -c "import json,sys; items=json.load(sys.stdin)['items']; print(next((i['event_id'] for i in items if i.get('event_code')=='registration-udaan-idol'), items[0]['event_id']))")
echo "Using event_id=$EVENT_ID"

UP1=$(curl -sS -X POST "$BASE/uploads" -H "Authorization: Bearer $TOKEN" -F "file=@$TMP/udid.pdf" -F "event_id=$EVENT_ID" -F 'field_key=upload-1')
UP2=$(curl -sS -X POST "$BASE/uploads" -H "Authorization: Bearer $TOKEN" -F "file=@$TMP/audio.mp3" -F "event_id=$EVENT_ID" -F 'field_key=upload-2')
echo "Uploads: $UP1 | $UP2"
U1=$(echo "$UP1" | python3 -c "import json,sys; print(json.load(sys.stdin)['items'][0]['upload_id'])")
U2=$(echo "$UP2" | python3 -c "import json,sys; print(json.load(sys.stdin)['items'][0]['upload_id'])")

curl -sS -X POST "$BASE/events/$EVENT_ID/registrations" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"payload\":{\"text-1\":\"API Test\",\"radio-1\":\"Male\",\"date-1\":\"2000-01-15\",\"text-2\":\"A\",\"text-4\":\"City\",\"text-5\":\"ST\",\"text-6\":\"123456\",\"text-7\":\"India\",\"email-1\":\"api@test.com\",\"phone-1\":\"$PHONE\",\"select-1\":\"Multiple disability\",\"number-1\":\"10\",\"upload-1\":{\"upload_id\":\"$U1\"},\"upload-2\":{\"upload_id\":\"$U2\"}},\"client\":{\"platform\":\"cli\",\"app_version\":\"0.3.0\"}}" | python3 -m json.tool

rm -rf "$TMP"
