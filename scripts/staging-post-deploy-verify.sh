#!/usr/bin/env bash
# Post-deploy verification for staging after FTP/cPanel plugin upload.
# For devops (Chris): run from repo root after deploy.
# Usage: bash scripts/staging-post-deploy-verify.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGING_BASE="${STAGING_API_BASE:-https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1}"
STAGING_BASE="${STAGING_BASE%/}"
MIN_ROUTES="${MIN_STAGING_ROUTES:-30}"

SECTION_PASS=0
SECTION_FAIL=0
SMOKE_EXIT=0

section_ok() { SECTION_PASS=$((SECTION_PASS + 1)); echo "  [PASS] $1"; }
section_bad() { SECTION_FAIL=$((SECTION_FAIL + 1)); echo "  [FAIL] $1"; }

echo "================================================================"
echo "Radio Udaan — Staging POST-DEPLOY verification"
echo "API: $STAGING_BASE"
echo "Site: https://nexusfleck.com/radioudaan/"
echo "Run after: radioudaan-app-api upload + Permalinks Save in WP Admin"
echo "================================================================"
echo ""

# --- 1) Full API smoke (14 checks in staging-api-smoke.sh) ---
echo "== Step 1: staging-api-smoke.sh =="
set +e
bash "$ROOT/scripts/staging-api-smoke.sh"
SMOKE_EXIT=$?
set -e
if [[ "$SMOKE_EXIT" -eq 0 ]]; then
  section_ok "staging-api-smoke.sh (14/14 checks)"
else
  section_bad "staging-api-smoke.sh exited $SMOKE_EXIT — fix failures before QA"
fi
echo ""

# --- 2) Route count ---
echo "== Step 2: Registered route count (expect >= $MIN_ROUTES) =="
ROUTES_JSON="$(/usr/bin/curl -sS --connect-timeout 12 --max-time 20 "$STAGING_BASE/")"
ROUTE_COUNT="$(echo "$ROUTES_JSON" | /usr/bin/python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('routes',{})))" 2>/dev/null || echo "0")"
if [[ "$ROUTE_COUNT" =~ ^[0-9]+$ ]] && [[ "$ROUTE_COUNT" -ge "$MIN_ROUTES" ]]; then
  section_ok "route count $ROUTE_COUNT (>= $MIN_ROUTES)"
else
  section_bad "route count $ROUTE_COUNT (need >= $MIN_ROUTES) — deploy full plugin + flush permalinks"
fi
echo ""

# --- 3) Support email + phone in /config ---
echo "== Step 3: Support contact in GET /config =="
CONFIG_HTTP="$(/usr/bin/curl -sS --connect-timeout 12 --max-time 20 -o /tmp/ru-postdeploy-config.json -w "%{http_code}" "$STAGING_BASE/config")"
CONFIG_SUPPORT_EXIT=0
/usr/bin/python3 << 'PY' || CONFIG_SUPPORT_EXIT=$?
import json, sys
if open("/tmp/ru-postdeploy-config.json").read().strip() == "":
    sys.exit("empty body")
d = json.load(open("/tmp/ru-postdeploy-config.json"))
support = d.get("support") or {}
phone = (support.get("helpline_phone") or "").strip()
email = (support.get("email") or "").strip()
if not phone:
    sys.exit("support.helpline_phone missing — WP Admin App settings")
if not email or "@" not in email:
    sys.exit("support.email missing — WP Admin App settings")
print(f"  helpline: {phone[:4]}… (redacted)")
print(f"  email: …@{email.split('@',1)[1]} (domain only)")
PY
if [[ "$CONFIG_HTTP" != "200" ]]; then
  section_bad "GET /config HTTP $CONFIG_HTTP"
elif [[ "$CONFIG_SUPPORT_EXIT" -eq 0 ]]; then
  section_ok "support helpline_phone + email present"
else
  section_bad "support contact incomplete (HTTP 200 but fields missing)"
fi
echo ""

# --- 4) privacy_policy_url ---
echo "== Step 4: privacy_policy_url in GET /config =="
PRIV_EXIT=0
/usr/bin/python3 << 'PY' || PRIV_EXIT=$?
import json, sys
d = json.load(open("/tmp/ru-postdeploy-config.json"))
privacy = (d.get("legal") or {}).get("privacy_policy_url") or d.get("privacy_policy_url")
if not privacy or not str(privacy).startswith("http"):
    sys.exit("privacy_policy_url missing or not http(s) — WP Admin / legal settings")
print(f"  url: {privacy}")
PY
if [[ "$PRIV_EXIT" -eq 0 ]]; then
  section_ok "privacy_policy_url set"
else
  section_bad "privacy_policy_url missing or invalid"
fi
echo ""

# --- Summary for devops ---
echo "================================================================"
echo "POST-DEPLOY SUMMARY (for devops)"
echo "----------------------------------------------------------------"
echo "  Smoke suite:        $([[ "$SMOKE_EXIT" -eq 0 ]] && echo PASS || echo FAIL)"
echo "  Routes (>= $MIN_ROUTES):     $([[ "$ROUTE_COUNT" -ge "$MIN_ROUTES" ]] 2>/dev/null && echo PASS || echo FAIL) ($ROUTE_COUNT)"
echo "  Support email+phone: $([[ "$CONFIG_SUPPORT_EXIT" -eq 0 && "$CONFIG_HTTP" == "200" ]] && echo PASS || echo FAIL)"
echo "  privacy_policy_url:  $([[ "$PRIV_EXIT" -eq 0 ]] && echo PASS || echo FAIL)"
echo "----------------------------------------------------------------"
# SECTION_FAIL already counts smoke as one section if failed
if [[ "$SECTION_FAIL" -eq 0 ]]; then
  echo "OVERALL: PASS — staging ready for QA (Part 4 in STAGING_QA_GUIDE.md)"
  echo "================================================================"
  exit 0
else
  echo "OVERALL: FAIL — $SECTION_FAIL verification step(s) failed. Do not hand to QA."
  echo "See STAGING_QA_GUIDE.md Part 1 (Deploy checklist)."
  echo "================================================================"
  exit 1
fi
