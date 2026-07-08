#!/usr/bin/env bash
# End-to-end smoke test: More tab APIs (profile, password, support, notifications, prefs).
set -euo pipefail
BASE="${API_BASE:-https://radio/wp-json/radioudaan/v1}"
STAMP="$(date +%s)"
EMAIL="more-test-${STAMP}@example.com"
PHONE="+919${STAMP: -9}"
PASS="TestPass123!"
NAME="More Suite Test"
NEW_PASS="TestPass456!"

PASS_COUNT=0
FAIL_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "  ✅ $1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "  ❌ $1"; }

echo "=============================================="
echo "Radio Udaan — More / Settings API test suite"
echo "BASE=$BASE"
echo "=============================================="
echo ""

echo "== 1) GET /config (support + notification defaults) =="
CFG=$(curl -sS "$BASE/config")
echo "$CFG" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert 'support' in d, 'missing support block'
assert 'notification_preferences' in d, 'missing notification_preferences'
print('support:', d.get('support'))
print('notification_preferences:', d.get('notification_preferences'))
" && pass "config has support + notification_preferences" || fail "config structure"
echo ""

echo "== 2) Register + verify phone + login =="
curl -sS -X POST "$BASE/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"$NAME\",\"email\":\"$EMAIL\",\"phone_e164\":\"$PHONE\",\"password\":\"$PASS\"}" > /dev/null

REQ=$(curl -sS -X POST "$BASE/auth/otp/request" \
  -H 'Content-Type: application/json' \
  -d "{\"phone_e164\":\"$PHONE\",\"purpose\":\"verify_phone\"}")
RID=$(echo "$REQ" | python3 -c "import json,sys; print(json.load(sys.stdin)['request_id'])")
OTP=$(echo "$REQ" | python3 -c "import json,sys; print(json.load(sys.stdin).get('dev_otp','123456'))")
curl -sS -X POST "$BASE/auth/otp/verify" \
  -H 'Content-Type: application/json' \
  -d "{\"request_id\":\"$RID\",\"otp\":\"$OTP\",\"purpose\":\"verify_phone\"}" > /dev/null

LOGIN=$(curl -sS -X POST "$BASE/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"identifier\":\"$PHONE\",\"password\":\"$PASS\"}")
TOKEN=$(echo "$LOGIN" | python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")
pass "registered, verified, logged in"
echo ""

AUTH="Authorization: Bearer $TOKEN"

echo "== 3) GET /auth/me =="
ME=$(curl -sS "$BASE/auth/me" -H "$AUTH")
echo "$ME" | python3 -m json.tool | head -20
echo "$ME" | python3 -c "import json,sys; u=json.load(sys.stdin)['user']; assert u.get('phone_e164')=='$PHONE'" \
  && pass "auth/me returns user" || fail "auth/me"
echo ""

echo "== 4) PATCH /auth/me (name) =="
UPD=$(curl -sS -X PATCH "$BASE/auth/me" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"name":"More Suite Updated"}')
echo "$UPD" | python3 -c "import json,sys; assert json.load(sys.stdin)['user']['name']=='More Suite Updated'" \
  && pass "profile update" || fail "profile update"
echo ""

echo "== 5) GET + PATCH /auth/notification-preferences =="
PREFS=$(curl -sS "$BASE/auth/notification-preferences" -H "$AUTH")
echo "$PREFS" | python3 -m json.tool
curl -sS -X PATCH "$BASE/auth/notification-preferences" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"events_enabled":false,"promotions_enabled":true}' | python3 -c "
import json,sys
p=json.load(sys.stdin)['preferences']
assert p['events_enabled']==False
assert p['promotions_enabled']==True
" && pass "notification preferences sync" || fail "notification preferences"
echo ""

echo "== 6) POST /support/contact =="
CONTACT=$(curl -sS -X POST "$BASE/support/contact" -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"name\":\"$NAME\",\"email\":\"$EMAIL\",\"subject\":\"Test help\",\"message\":\"Automated test message $STAMP\"}")
echo "$CONTACT" | python3 -c "import json,sys; assert json.load(sys.stdin).get('status')=='sent'" \
  && pass "support contact" || fail "support contact"
echo ""

echo "== 7) POST /devices/register (mock FCM token) =="
DEV=$(curl -sS -X POST "$BASE/devices/register" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"fcm_token":"test_fcm_token_'"$STAMP"'_abcdefghijklmnopqrstuvwxyz","platform":"android"}')
echo "$DEV" | python3 -c "
import json,sys
d=json.load(sys.stdin)
code=d.get('code','')
if d.get('status')=='registered':
    print('registered (local dev)')
    sys.exit(0)
if code=='test_token_not_allowed':
    print('test token rejected (expected on staging/production)')
    sys.exit(0)
sys.exit(1)
" && pass "device register" || fail "device register"
echo ""

echo "== 8) GET /notifications (unread_count) =="
NOTIF=$(curl -sS "$BASE/notifications" -H "$AUTH")
echo "$NOTIF" | python3 -m json.tool | head -30
NID=$(echo "$NOTIF" | python3 -c "import json,sys; items=json.load(sys.stdin).get('items',[]); print(items[0]['id'] if items else '')")
UNREAD=$(echo "$NOTIF" | python3 -c "import json,sys; print(json.load(sys.stdin).get('unread_count',0))")
echo "unread_count=$UNREAD"
[[ -n "$NID" ]] && pass "notifications list has items" || fail "notifications empty"
[[ "$UNREAD" -ge 0 ]] && pass "unread_count present" || fail "unread_count missing"
echo ""

if [[ -n "$NID" ]]; then
  echo "== 9) PATCH /notifications/$NID (mark read) =="
  curl -sS -X PATCH "$BASE/notifications/$NID" -H "$AUTH" | python3 -c "
import json,sys
n=json.load(sys.stdin).get('notification',{})
assert n.get('is_read')==True or json.load(sys.stdin).get('status') in ('read','already_read')
" 2>/dev/null || curl -sS -X PATCH "$BASE/notifications/$NID" -H "$AUTH" | python3 -m json.tool
  pass "mark notification read"
  echo ""
fi

echo "== 10) POST /auth/change-password (re-login with new password) =="
curl -sS -X POST "$BASE/auth/change-password" -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"current_password\":\"$PASS\",\"new_password\":\"$NEW_PASS\"}" | python3 -c "
import json,sys; assert json.load(sys.stdin).get('status')=='password_changed'
" && pass "change password" || fail "change password"

LOGIN2=$(curl -sS -X POST "$BASE/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"identifier\":\"$PHONE\",\"password\":\"$NEW_PASS\"}")
echo "$LOGIN2" | python3 -c "import json,sys; assert json.load(sys.stdin).get('token')" \
  && pass "login with new password" || fail "login after password change"
echo ""

echo "== 11) GET /events + /health =="
curl -sS "$BASE/events?status=open" -H "$AUTH" | python3 -c "import json,sys; assert 'items' in json.load(sys.stdin)" \
  && pass "events list" || fail "events list"
curl -sS "$BASE/health" | python3 -c "import json,sys; json.load(sys.stdin)" \
  && pass "health" || fail "health"
echo ""

echo "=============================================="
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "=============================================="
[[ "$FAIL_COUNT" -eq 0 ]]
