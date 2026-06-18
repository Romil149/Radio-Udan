#!/usr/bin/env bash
# Automated staging QA for Elena — extends staging-api-smoke.sh.
# Usage: bash scripts/staging-qa-automated.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGING_BASE="${STAGING_API_BASE:-https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1}"
STAGING_BASE="${STAGING_BASE%/}"

PASS=0
FAIL=0
SMOKE_EXIT=0

ok() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; }

echo "================================================================"
echo "Radio Udaan — Staging QA (automated) — for QA sign-off"
echo "API:  $STAGING_BASE"
echo "Site: https://nexusfleck.com/radioudaan/"
echo "================================================================"
echo ""

echo "== Base smoke (staging-api-smoke.sh) =="
set +e
bash "$ROOT/scripts/staging-api-smoke.sh"
SMOKE_EXIT=$?
set -e
if [[ "$SMOKE_EXIT" -eq 0 ]]; then
  ok "staging-api-smoke.sh (all base checks)"
else
  bad "staging-api-smoke.sh exited $SMOKE_EXIT"
fi
echo ""

echo "== GET /events?status=all (items array) =="
EA="$(/usr/bin/curl -sS --connect-timeout 12 --max-time 20 -o /tmp/ru-events-all.json -w "%{http_code}" "$STAGING_BASE/events?status=all")"
if [[ "$EA" == "200" ]] && /usr/bin/python3 << 'PY'
import json, sys
d = json.load(open("/tmp/ru-events-all.json"))
if "items" not in d:
    sys.exit("response missing 'items' key")
items = d["items"]
if not isinstance(items, list):
    sys.exit("'items' is not an array")
print(f"  items count: {len(items)}")
PY
then
  ok "GET /events?status=all"
else
  bad "GET /events?status=all (HTTP $EA or invalid items array)"
fi
echo ""

echo "== GET /config (auth_policy + features) =="
CC="$(/usr/bin/curl -sS --connect-timeout 12 --max-time 20 -o /tmp/ru-qa-config.json -w "%{http_code}" "$STAGING_BASE/config")"
if [[ "$CC" == "200" ]] && /usr/bin/python3 << 'PY'
import json, sys
d = json.load(open("/tmp/ru-qa-config.json"))
if "auth_policy" not in d or not isinstance(d["auth_policy"], dict):
    sys.exit("auth_policy missing or not object")
if "features" not in d or not isinstance(d["features"], dict):
    sys.exit("features missing or not object")
ap = d["auth_policy"]
fe = d["features"]
print(f"  auth_policy keys: {', '.join(sorted(ap.keys())[:6])}{'…' if len(ap) > 6 else ''}")
print(f"  features keys: {', '.join(sorted(fe.keys()))}")
PY
then
  ok "GET /config auth_policy + features"
else
  bad "GET /config auth_policy/features (HTTP $CC or keys missing)"
fi
echo ""

echo "================================================================"
echo "Elena QA summary"
echo "----------------------------------------------------------------"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
if [[ "$FAIL" -eq 0 ]]; then
  echo "  Verdict: PASS — staging OK for full app QA"
  echo "================================================================"
  exit 0
else
  echo "  Verdict: FAIL — do not sign off; fix items above first"
  echo "================================================================"
  exit 1
fi
