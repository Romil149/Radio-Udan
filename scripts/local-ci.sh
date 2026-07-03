#!/usr/bin/env bash
# Run GitHub Actions checks locally (when Actions minutes are exhausted).
#
# Usage:
#   bash scripts/local-ci.sh              # CI only: Flutter analyze + WP plugin lint
#   bash scripts/local-ci.sh --smoke      # + staging API smoke (needs network)
#   bash scripts/local-ci.sh --apk        # + Android release APK (staging API)
#   bash scripts/local-ci.sh --web        # + Flutter web build (staging API)
#   bash scripts/local-ci.sh --ios        # + iOS IPA (needs full Xcode + signing)
#   bash scripts/local-ci.sh --all        # Everything your machine supports
#   bash scripts/local-ci.sh --package-wp # Plugin zip for staging upload
#
# Outputs:
#   dist/app-release.apk          (--apk)
#   dist/web/                     (--web)
#   dist/*.ipa                    (--ios, if build succeeds)
#   dist/radioudaan-app-api-staging.zip (--package-wp)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${ROOT}/radio_udaan_app"
PLUGIN="${ROOT}/radio-udan-wordpresss-website/wp-content/plugins/radioudaan-app-api"
STAGING_API="${STAGING_API_BASE_URL:-https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1}"
DIST="${ROOT}/dist"

RUN_SMOKE=0
RUN_APK=0
RUN_WEB=0
RUN_IOS=0
RUN_PACKAGE_WP=0

usage() {
  sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage 0 ;;
    --smoke) RUN_SMOKE=1 ;;
    --apk) RUN_APK=1 ;;
    --web) RUN_WEB=1 ;;
    --ios) RUN_IOS=1 ;;
    --package-wp) RUN_PACKAGE_WP=1 ;;
    --all)
      RUN_SMOKE=1
      RUN_APK=1
      RUN_WEB=1
      RUN_IOS=1
      RUN_PACKAGE_WP=1
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage 1
      ;;
  esac
done

# Default: CI checks only (matches ci-flutter + ci-wp-plugin + ci-analyze).
if [[ "$RUN_SMOKE" -eq 0 && "$RUN_APK" -eq 0 && "$RUN_WEB" -eq 0 && "$RUN_IOS" -eq 0 && "$RUN_PACKAGE_WP" -eq 0 ]]; then
  : # analyze + php only
fi

banner() {
  echo ""
  echo "=============================================="
  echo "$1"
  echo "=============================================="
}

step_flutter_analyze() {
  banner "Flutter analyze (CI — Flutter / CI analyze / build gates)"
  if ! command -v flutter >/dev/null 2>&1; then
    echo "ERROR: flutter not in PATH. Install: https://docs.flutter.dev/get-started/install" >&2
    exit 1
  fi
  cd "$APP"
  flutter pub get
  dart analyze lib
  cd "$ROOT"
  echo "  OK  dart analyze lib"
}

step_wp_plugin_lint() {
  banner "WP plugin PHP lint (CI — WP plugin PHP lint)"
  bash "${ROOT}/scripts/verify-wp-plugin.sh"
}

step_staging_smoke() {
  banner "Staging API smoke (Staging API health)"
  bash "${ROOT}/scripts/staging-api-smoke.sh"
  bash "${ROOT}/scripts/staging-qa-automated.sh"
}

step_build_apk() {
  banner "Android APK — staging API (Build staging APK)"
  mkdir -p "$DIST"
  cd "$APP"
  flutter pub get
  dart analyze lib
  echo "API_BASE_URL=$STAGING_API"
  flutter build apk --release \
    --dart-define="API_BASE_URL=${STAGING_API}"
  APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
  if [[ ! -f "$APK_SRC" ]]; then
    echo "ERROR: APK not found at $APK_SRC" >&2
    exit 1
  fi
  cp "$APK_SRC" "${DIST}/Radio-Udaan-staging.apk"
  ls -lh "${DIST}/Radio-Udaan-staging.apk"
  cd "$ROOT"
  echo ""
  echo "  Install: copy ${DIST}/Radio-Udaan-staging.apk to your phone (Drive/WhatsApp)."
}

step_build_web() {
  banner "Flutter web — staging API (Build staging Web)"
  mkdir -p "$DIST"
  cd "$APP"
  flutter pub get
  dart analyze lib
  flutter build web --release \
    --dart-define="API_BASE_URL=${STAGING_API}"
  rm -rf "${DIST}/web"
  cp -R build/web "${DIST}/web"
  ls -la "${DIST}/web" | head -5
  cd "$ROOT"
  echo "  Open dist/web/index.html via a static server for Safari testing."
}

step_build_ios() {
  banner "iOS IPA — staging API (Build iOS IPA)"
  if ! xcode-select -p 2>/dev/null | grep -q Xcode.app; then
    echo "SKIP: Full Xcode required. Install from App Store, then:" >&2
    echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer" >&2
    echo "  sudo xcodebuild -runFirstLaunch" >&2
    return 1
  fi
  mkdir -p "$DIST"
  cd "$APP"
  flutter pub get
  dart analyze lib
  cd ios && pod install --repo-update && cd ..
  echo "API_BASE_URL=$STAGING_API"
  flutter build ipa --release \
    --dart-define="API_BASE_URL=${STAGING_API}"
  IPA="$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"
  if [[ -z "$IPA" ]]; then
    echo "ERROR: No IPA in build/ios/ipa/. Check signing in Xcode." >&2
    exit 1
  fi
  cp "$IPA" "${DIST}/"
  ls -lh "${DIST}/"*.ipa
  cd "$ROOT"
  echo "  Upload with Transporter app or: xcrun altool ..."
}

step_package_wp() {
  banner "Package WP plugin zip (deploy to staging)"
  if [[ -x "${ROOT}/scripts/package-staging-plugin.sh" ]]; then
    bash "${ROOT}/scripts/package-staging-plugin.sh"
  else
    mkdir -p "$DIST"
    (cd "${PLUGIN}/.." && zip -r "${DIST}/radioudaan-app-api-staging.zip" radioudaan-app-api \
      -x '*/.DS_Store' -x '*/scripts/*')
    ls -lh "${DIST}/radioudaan-app-api-staging.zip"
  fi
}

START=$(date +%s)
echo "Radio Udaan — local CI"
echo "ROOT=$ROOT"
echo "Flutter: $(flutter --version 2>/dev/null | head -1 || echo 'not found')"

step_flutter_analyze
step_wp_plugin_lint

[[ "$RUN_SMOKE" -eq 1 ]] && step_staging_smoke
[[ "$RUN_APK" -eq 1 ]] && step_build_apk
[[ "$RUN_WEB" -eq 1 ]] && step_build_web
[[ "$RUN_IOS" -eq 1 ]] && step_build_ios || true
[[ "$RUN_PACKAGE_WP" -eq 1 ]] && step_package_wp

ELAPSED=$(( $(date +%s) - START ))
banner "DONE in ${ELAPSED}s"
echo "Next: install APK / run scripts/a11y-device-qa.md on device."
