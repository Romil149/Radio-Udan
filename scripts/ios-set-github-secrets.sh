#!/usr/bin/env bash
# Push iOS signing secrets to GitHub from local files (avoids copy-paste errors).
set -euo pipefail

REPO="${1:-Romil149/Radio-Udan}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
B64_FILE="${ROOT}/.ios-signing/certificate-base64.txt"
P12_FILE="${ROOT}/.ios-signing/distribution.p12"
PASSWORD="${2:-RadioUdaan2026}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Install GitHub CLI: https://cli.github.com/"
  echo "Then run: gh auth login"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Run: gh auth login"
  exit 1
fi

if [[ ! -f "$P12_FILE" ]]; then
  echo "Missing $P12_FILE"
  exit 1
fi

bash "${ROOT}/scripts/ios-verify-and-encode-p12.sh" "$P12_FILE" "$B64_FILE" "$PASSWORD"

echo "Setting GitHub secrets on $REPO ..."
gh secret set IOS_DISTRIBUTION_CERTIFICATE_BASE64 --repo "$REPO" < "$B64_FILE"
printf '%s' "$PASSWORD" | gh secret set IOS_DISTRIBUTION_CERTIFICATE_PASSWORD --repo "$REPO"

echo "Done. Secrets set without manual copy-paste."
echo "Trigger build: GitHub Actions → Build iOS IPA → Run workflow"
