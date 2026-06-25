#!/usr/bin/env bash
# Verify radioudaan-app-api plugin before deploy or claiming "done".
# Usage: bash scripts/verify-wp-plugin.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="${ROOT}/radio-udan-wordpresss-website/wp-content/plugins/radioudaan-app-api"
MAIN="${PLUGIN}/radioudaan-app-api.php"

PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; }

echo "=============================================="
echo "Radio Udaan — WP plugin verify"
echo "PLUGIN=$PLUGIN"
echo "=============================================="
echo ""

if [[ ! -f "$MAIN" ]]; then
  echo "Plugin not found at $MAIN"
  exit 1
fi

echo "== PHP syntax (all .php files) =="
SYNTAX_ERR=0
while IFS= read -r -d '' f; do
  if ! php -l "$f" >/dev/null 2>&1; then
    bad "syntax $f"
    php -l "$f" 2>&1 || true
    SYNTAX_ERR=1
  fi
done < <(find "$PLUGIN" -name '*.php' -print0)
if [[ "$SYNTAX_ERR" -eq 0 ]]; then
  ok "php -l all plugin files"
fi

echo ""
echo "== Bootstrap requires (critical classes) =="
REQUIRED_FILES=(
  "includes/class-app-copy-catalog.php"
  "includes/class-app-branding.php"
  "includes/class-admin-app-hub.php"
  "includes/class-radioudaan-app-api.php"
)
for rel in "${REQUIRED_FILES[@]}"; do
  if grep -q "$rel" "$MAIN"; then
    ok "main requires $rel"
  else
    bad "main missing require_once for $rel"
  fi
done

echo ""
echo "== Class file exists for each require_once in main =="
MISSING=0
while IFS= read -r line; do
  path="$(echo "$line" | sed -n "s/.*'\([^']*\)'.*/\1/p")"
  if [[ -n "$path" && ! -f "${PLUGIN}/${path}" ]]; then
    bad "missing file ${path}"
    MISSING=1
  fi
done < <(grep "require_once RADIOUDAAN_APP_API_PATH" "$MAIN")
if [[ "$MISSING" -eq 0 ]]; then
  ok "all main require_once targets exist"
fi

echo ""
echo "== Copy catalog load (minimal PHP bootstrap) =="
export RU_PLUGIN_COPY_CATALOG="${PLUGIN}/includes/class-app-copy-catalog.php"
COPY_COUNT="$(php -d display_startup_errors=0 -d display_errors=0 <<'EOPHP' 2>/dev/null
<?php
define('ABSPATH', true);
require getenv('RU_PLUGIN_COPY_CATALOG');
echo count(RadioUdaan_App_Copy_Catalog::catalog_keys());
EOPHP
)"
COPY_COUNT="${COPY_COUNT//[^0-9]/}"
COPY_COUNT="${COPY_COUNT:-0}"
if [[ "${COPY_COUNT}" -ge 300 ]]; then
  ok "copy catalog loads (${COPY_COUNT} keys)"
else
  bad "copy catalog failed or too few keys (got ${COPY_COUNT}, need >= 300)"
fi

echo ""
echo "=============================================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "=============================================="

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
