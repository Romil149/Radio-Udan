#!/usr/bin/env bash
# Smoke test: Library tab YouTube proxy endpoints (GET, public).
# TODO: Remove route-not-found expectations once WP registers:
#   GET /library/youtube/recent
#   GET /library/youtube/playlists
#   GET /library/youtube/playlists/featured
#   GET /library/youtube/search?q=
set -uo pipefail

CURL="${CURL:-/usr/bin/curl}"
BASE="${API_BASE:-https://radio/wp-json/radioudaan/v1}"

FAILURES=0

check_youtube_get() {
  local label="$1"
  local url="$2"
  local body http_code

  body="$(/usr/bin/mktemp)"
  http_code="$("$CURL" -sS -o "$body" -w "%{http_code}" "$url" || echo "000")"

  echo "== $label =="
  echo "GET $url"
  echo "HTTP $http_code"

  if [[ "$http_code" == "404" ]]; then
    /usr/bin/head -c 400 "$body" 2>/dev/null || true
    echo ""
    echo "FAIL: route not registered (expected after WP YouTube library merge)"
    FAILURES=$((FAILURES + 1))
    /bin/rm -f "$body"
    echo ""
    return
  fi

  if ! RESULT="$(/usr/bin/python3 - "$body" "$http_code" << 'PY'
import json
import sys

path, code_s = sys.argv[1], sys.argv[2]
code = int(code_s) if code_s.isdigit() else 0

try:
    with open(path, encoding="utf-8") as f:
        raw = f.read()
except OSError as e:
    print(f"FAIL: could not read body: {e}")
    sys.exit(1)

try:
    data = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    print("FAIL: response is not JSON")
    sys.exit(1)

def api_key_graceful(d):
    if not isinstance(d, dict):
        return False
    blob = " ".join(
        str(d.get(k, ""))
        for k in ("code", "message", "error", "status")
    ).lower()
    if "items" in d and isinstance(d["items"], list) and d.get("configured") is False:
        return True
    markers = ("api key", "api_key", "youtube", "not configured", "not_configured", "missing key")
    return any(m in blob for m in markers)

if code == 200:
    if isinstance(data.get("items"), list):
        n = len(data["items"])
        print(f"PASS: 200 with items array (count={n})")
        sys.exit(0)
    if api_key_graceful(data):
        print("PASS: 200 with graceful YouTube/API-key-not-configured response")
        sys.exit(0)
    print(f"FAIL: 200 but JSON missing items[] and not a known graceful error: {list(data.keys())[:8]}")
    sys.exit(1)

if code in (501, 503) and api_key_graceful(data):
    print(f"PASS: {code} with graceful YouTube/API-key error")
    sys.exit(0)

print(f"FAIL: HTTP {code} — expected 200+items or graceful API-key error")
sys.exit(1)
PY
)"; then
    echo "$RESULT"
    FAILURES=$((FAILURES + 1))
  else
    echo "$RESULT"
  fi

  /usr/bin/python3 -m json.tool "$body" 2>/dev/null | /usr/bin/head -n 20 || /usr/bin/head -c 600 "$body"
  echo ""
  /bin/rm -f "$body"
  echo ""
}

echo "YouTube library smoke test"
echo "BASE=$BASE"
echo ""

check_youtube_get "recent" "$BASE/library/youtube/recent"
check_youtube_get "playlists" "$BASE/library/youtube/playlists"
check_youtube_get "playlists/featured" "$BASE/library/youtube/playlists/featured"
check_youtube_get "search (q=test)" "$BASE/library/youtube/search?q=test"

if [[ "$FAILURES" -gt 0 ]]; then
  echo "Summary: $FAILURES endpoint(s) FAILED."
  exit 1
fi

echo "Summary: all YouTube library checks passed."
