#!/usr/bin/env bash
# Staging API smoke test — run after every deploy to nexusfleck.
# Usage: bash scripts/staging-api-smoke.sh
set -euo pipefail

STAGING_BASE="${STAGING_API_BASE:-https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1}"
STAGING_BASE="${STAGING_BASE%/}"

PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; }

echo "=============================================="
echo "Radio Udaan — Staging API smoke"
echo "BASE=$STAGING_BASE"
echo "Site: https://nexusfleck.com/radioudaan/"
echo "=============================================="
echo ""

echo "== Required routes (must match local plugin) =="
ROUTES_JSON="$(/usr/bin/curl -sS "$STAGING_BASE/")"
REQUIRED=(
  "/radioudaan/v1/auth/otp/request"
  "/radioudaan/v1/auth/otp/verify"
  "/radioudaan/v1/auth/change-password"
  "/radioudaan/v1/auth/notification-preferences"
  "/radioudaan/v1/devices/register"
  "/radioudaan/v1/library/youtube/playlists"
  "/radioudaan/v1/library/youtube/playlists/featured"
  "/radioudaan/v1/library/youtube/recent"
  "/radioudaan/v1/library/youtube/search"
  "/radioudaan/v1/library/schedule"
)
for r in "${REQUIRED[@]}"; do
  if echo "$ROUTES_JSON" | /usr/bin/python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if '$r' in d.get('routes',{}) else 1)"; then
    ok "route $r"
  else
    bad "route missing $r"
  fi
done
echo ""

echo "== GET /health =="
HC="$(/usr/bin/curl -sS -o /tmp/ru-health.json -w "%{http_code}" "$STAGING_BASE/health")"
if [[ "$HC" == "200" ]] && /usr/bin/python3 -c "import json; d=json.load(open('/tmp/ru-health.json')); assert d.get('status')=='ok'"; then
  ok "GET /health"
else
  bad "GET /health (HTTP $HC)"
fi

echo "== GET /config =="
CC="$(/usr/bin/curl -sS -o /tmp/ru-config.json -w "%{http_code}" "$STAGING_BASE/config")"
if [[ "$CC" == "200" ]] && /usr/bin/python3 << 'PY'
import json, sys
d = json.load(open("/tmp/ru-config.json"))
assert d.get("branding", {}).get("app_name"), "branding.app_name"
assert d.get("stream_url"), "stream_url"
assert d.get("api_base_url", "").startswith("https://"), "api_base_url https"
support = d.get("support") or {}
if not (support.get("helpline_phone") or support.get("email")):
    sys.exit("support helpline/email empty — set in WP Admin → Radio Udaan App")
legal = d.get("legal") or {}
privacy = legal.get("privacy_policy_url") or d.get("privacy_policy_url")
if not privacy or not str(privacy).startswith("https://"):
    sys.exit("privacy_policy_url missing — set in WP Admin")
PY
then
  ok "GET /config"
else
  bad "GET /config (HTTP $CC or missing support/legal)"
fi

echo "== GET /events?status=open =="
EC="$(/usr/bin/curl -sS -o /tmp/ru-events.json -w "%{http_code}" "$STAGING_BASE/events?status=open")"
if [[ "$EC" == "200" ]] && /usr/bin/python3 << 'PY'
import json, sys
d = json.load(open("/tmp/ru-events.json"))
items = d.get("items", d.get("events", []))
assert len(items) >= 1, "no open events"
first = items[0]
eid = first.get("event_id") or first.get("id")
assert eid, "event_id missing on first item"
PY
then
  ok "GET /events"
else
  bad "GET /events (HTTP $EC or no open events)"
fi

echo ""
echo "=============================================="
echo "Results: $PASS passed, $FAIL failed"
echo "=============================================="
if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "Staging is NOT ready for full app QA until failures are fixed."
  echo "See STAGING_QA_GUIDE.md → Part 1 (Deploy checklist)."
  exit 1
fi
