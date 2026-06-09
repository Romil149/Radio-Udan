#!/usr/bin/env bash
# End-to-end registration API smoke (no secrets in repo).
#
# Exercises: health → config → OTP → open events → form schema → optional
# validation-only registration POST (empty required fields → expect HTTP 400).
#
# Full happy-path registration (uploads + complete payload) is in:
#   scripts/test-api-flow.sh
# That script creates minimal PDF/MP3 fixtures and submits a real entry.
# This script does NOT upload files; use test-api-flow.sh for a full submit.
#
# Environment (set in shell or .env.local — never commit secrets):
#   API_BASE   Base URL (default: https://radio/wp-json/radioudaan/v1)
#   PHONE      E.164 phone for OTP (required unless E2E_SKIP_AUTH=1)
#   OTP        OTP code; if unset, uses dev_otp from request response when present
#   EVENT_ID   ru_event post ID; if unset, first item from GET /events?status=open
#   E2E_SKIP_SUBMIT=1   Skip POST /registrations (schema + auth only)
#   E2E_SKIP_AUTH=1     Skip OTP; no Bearer token (form/events still public)
#
# Usage:
#   export PHONE='+919888877766'
#   ./scripts/e2e-registration.sh
#
set -euo pipefail

API_BASE="${API_BASE:-https://radio/wp-json/radioudaan/v1}"
API_BASE="${API_BASE%/}"

step() { printf '\n==> %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

curl_json() {
  local method="$1"
  local url="$2"
  shift 2
  curl -sS -w '\n__HTTP_CODE__:%{http_code}' -X "$method" "$url" "$@"
}

http_code_from() {
  sed -n 's/^__HTTP_CODE__://p' | tail -1
}

body_from() {
  sed '/^__HTTP_CODE__:/d'
}

pretty() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool 2>/dev/null || cat
  else
    cat
  fi
}

# --- health ---
step "GET /health"
RAW=$(curl_json GET "$API_BASE/health")
CODE=$(echo "$RAW" | http_code_from)
BODY=$(echo "$RAW" | body_from)
echo "$BODY" | pretty
[[ "$CODE" == "200" ]] || fail "health returned HTTP $CODE"

# --- config ---
step "GET /config"
RAW=$(curl_json GET "$API_BASE/config")
CODE=$(echo "$RAW" | http_code_from)
BODY=$(echo "$RAW" | body_from)
echo "$BODY" | pretty
[[ "$CODE" == "200" ]] || fail "config returned HTTP $CODE"

TOKEN=""
if [[ "${E2E_SKIP_AUTH:-}" != "1" ]]; then
  [[ -n "${PHONE:-}" ]] || fail "PHONE is required (E.164). Example: export PHONE='+919888877766'"

  step "POST /auth/otp/request"
  REQ_RAW=$(curl_json POST "$API_BASE/auth/otp/request" \
    -H 'Content-Type: application/json' \
    -d "{\"phone_e164\":\"$PHONE\"}")
  REQ_CODE=$(echo "$REQ_RAW" | http_code_from)
  REQ_BODY=$(echo "$REQ_RAW" | body_from)
  echo "$REQ_BODY" | pretty
  [[ "$REQ_CODE" == "200" || "$REQ_CODE" == "201" ]] || fail "otp/request returned HTTP $REQ_CODE"

  RID=$(echo "$REQ_BODY" | python3 -c "import json,sys; print(json.load(sys.stdin)['request_id'])")
  if [[ -n "${OTP:-}" ]]; then
    USE_OTP="$OTP"
  else
    USE_OTP=$(echo "$REQ_BODY" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('dev_otp') or '')")
    [[ -n "$USE_OTP" ]] || fail "OTP not set and response had no dev_otp (set OTP= or enable dev OTP on server)"
  fi

  step "POST /auth/otp/verify"
  VER_RAW=$(curl_json POST "$API_BASE/auth/otp/verify" \
    -H 'Content-Type: application/json' \
    -d "{\"request_id\":\"$RID\",\"otp\":\"$USE_OTP\"}")
  VER_CODE=$(echo "$VER_RAW" | http_code_from)
  VER_BODY=$(echo "$VER_RAW" | body_from)
  echo "$VER_BODY" | pretty
  [[ "$VER_CODE" == "200" || "$VER_CODE" == "201" ]] || fail "otp/verify returned HTTP $VER_CODE"

  TOKEN=$(echo "$VER_BODY" | python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")
  step "GET /auth/me"
  ME_RAW=$(curl_json GET "$API_BASE/auth/me" -H "Authorization: Bearer $TOKEN")
  ME_CODE=$(echo "$ME_RAW" | http_code_from)
  echo "$ME_RAW" | body_from | pretty
  [[ "$ME_CODE" == "200" ]] || fail "auth/me returned HTTP $ME_CODE"
else
  step "Skipping auth (E2E_SKIP_AUTH=1)"
fi

# --- open events ---
step "GET /events?status=open"
EV_RAW=$(curl_json GET "$API_BASE/events?status=open")
EV_CODE=$(echo "$EV_RAW" | http_code_from)
EV_BODY=$(echo "$EV_RAW" | body_from)
echo "$EV_BODY" | pretty
[[ "$EV_CODE" == "200" ]] || fail "events returned HTTP $EV_CODE"

if [[ -n "${EVENT_ID:-}" ]]; then
  EID="$EVENT_ID"
else
  EID=$(echo "$EV_BODY" | python3 -c "import json,sys; items=json.load(sys.stdin).get('items') or []; print(items[0]['event_id'] if items else '')")
  [[ -n "$EID" ]] || fail "no open events and EVENT_ID not set"
fi
echo "Using event_id=$EID"

# --- form schema ---
step "GET /events/$EID/form"
FORM_RAW=$(curl_json GET "$API_BASE/events/$EID/form")
FORM_CODE=$(echo "$FORM_RAW" | http_code_from)
FORM_BODY=$(echo "$FORM_RAW" | body_from)
echo "$FORM_BODY" | pretty
[[ "$FORM_CODE" == "200" ]] || fail "form schema returned HTTP $FORM_CODE"

REQ_COUNT=$(echo "$FORM_BODY" | python3 -c "import json,sys; f=json.load(sys.stdin).get('fields') or []; print(sum(1 for x in f if x.get('required')))")
echo "Required fields in schema: $REQ_COUNT"

if [[ "${E2E_SKIP_SUBMIT:-}" == "1" ]]; then
  step "Skipping registration POST (E2E_SKIP_SUBMIT=1)"
  echo "For full registration with uploads, run: scripts/test-api-flow.sh"
  exit 0
fi

[[ -n "$TOKEN" ]] || fail "registration POST requires auth; unset E2E_SKIP_AUTH or provide PHONE/OTP"

step "POST /events/$EID/registrations (missing required fields — expect validation 400)"
SUB_RAW=$(curl_json POST "$API_BASE/events/$EID/registrations" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"payload":{"__e2e_validation_probe":true},"client":{"platform":"e2e","app_version":"0.0.0-e2e"}}')
SUB_CODE=$(echo "$SUB_RAW" | http_code_from)
SUB_BODY=$(echo "$SUB_RAW" | body_from)
echo "$SUB_BODY" | pretty

if [[ "$SUB_CODE" == "400" ]]; then
  echo "OK: validation rejected empty required fields (HTTP 400)."
elif [[ "$SUB_CODE" == "200" || "$SUB_CODE" == "201" ]]; then
  echo "NOTE: server accepted empty payload (no required fields?). Compare with test-api-flow.sh for full submit."
else
  fail "registration POST returned HTTP $SUB_CODE (expected 400 for empty required fields)"
fi

echo ""
echo "Done. Full registration (files + payload): scripts/test-api-flow.sh"
