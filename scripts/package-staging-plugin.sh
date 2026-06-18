#!/usr/bin/env bash
# Package radioudaan-app-api for staging upload (cPanel/FTP).
# Usage: bash scripts/package-staging-plugin.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="radioudaan-app-api"
PLUGIN_SRC="$ROOT/radio-udan-wordpresss-website/wp-content/plugins/$PLUGIN_DIR"
OUT_ZIP="$ROOT/dist/radioudaan-app-api-staging.zip"

if [[ ! -d "$PLUGIN_SRC" ]]; then
  echo "ERROR: Plugin not found: $PLUGIN_SRC" >&2
  exit 1
fi

mkdir -p "$ROOT/dist"
rm -f "$OUT_ZIP"

(
  cd "$ROOT/radio-udan-wordpresss-website/wp-content/plugins"
  /usr/bin/zip -r "$OUT_ZIP" "$PLUGIN_DIR" \
    -x "$PLUGIN_DIR/.git/*" \
    -x "$PLUGIN_DIR/.git/**/*" \
    -x "$PLUGIN_DIR/node_modules/*" \
    -x "$PLUGIN_DIR/node_modules/**/*" \
    -x "$PLUGIN_DIR/**/node_modules/*" \
    -x "$PLUGIN_DIR/**/.git/*"
)

BYTES="$(/usr/bin/stat -f%z "$OUT_ZIP" 2>/dev/null || /usr/bin/stat -c%s "$OUT_ZIP")"
echo "=============================================="
echo "Radio Udaan — Staging plugin package"
echo "=============================================="
echo "Created: $OUT_ZIP"
echo "Size:    $BYTES bytes"
echo ""
echo "Upload (cPanel File Manager or FTP)"
echo "-----------------------------------"
echo "1. Connect to staging host (nexusfleck.com)."
echo "2. Go to: public_html/radioudaan/wp-content/plugins/"
echo "   (adjust path if your WP root differs)."
echo "3. Backup existing folder: radioudaan-app-api → radioudaan-app-api.bak.\$(date)"
echo "4. Upload: dist/radioudaan-app-api-staging.zip"
echo "5. Extract the zip IN wp-content/plugins/ (NOT inside radioudaan-app-api/)."
echo "   Correct:  wp-content/plugins/radioudaan-app-api/radioudaan-app-api.php"
echo "   Wrong:    wp-content/plugins/radioudaan-app-api/radioudaan-app-api/radioudaan-app-api.php"
echo "   After extract you should have:"
echo "   wp-content/plugins/radioudaan-app-api/  (plugin files inside)"
echo "6. Verify this file exists on server:"
echo "   wp-content/plugins/radioudaan-app-api/includes/class-admin-app-hub.php"
echo "7. WP Admin → Settings → Permalinks → Save Changes (flush rewrite rules)."
echo "8. Run QA: bash scripts/staging-qa-automated.sh"
echo "=============================================="
