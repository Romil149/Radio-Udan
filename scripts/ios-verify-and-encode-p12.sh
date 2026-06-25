#!/usr/bin/env bash
# Verify .p12 password works, then write base64 to a file for GitHub secret copy-paste.
set -euo pipefail

P12="${1:-.ios-signing/distribution.p12}"
OUT="${2:-.ios-signing/certificate-base64.txt}"
P12_PASS="${3:-}"

if [[ ! -f "$P12" ]]; then
  echo "Missing: $P12"
  echo "Create it first:"
  echo "  bash scripts/ios-github-secrets-setup.sh csr"
  echo "  (upload CSR to Apple, download .cer)"
  echo "  bash scripts/ios-github-secrets-setup.sh p12 .ios-signing/distribution.cer"
  exit 1
fi

if [[ -z "$P12_PASS" ]]; then
  read -r -s -p "Enter the .p12 password to verify: " P12_PASS
  echo ""
fi

if ! openssl pkcs12 -in "$P12" -passin "pass:${P12_PASS}" -noout 2>/dev/null; then
  echo ""
  echo "FAILED: Password does not match this .p12 file."
  echo "Re-run: bash scripts/ios-github-secrets-setup.sh p12 .ios-signing/distribution.cer"
  echo "Use a simple password (letters + numbers only), e.g. RadioUdaan2026"
  exit 1
fi

echo "OK: Password matches the .p12 file."

base64 < "$P12" | tr -d '\n' > "$OUT"
BYTES=$(wc -c < "$OUT" | tr -d ' ')

echo ""
echo "Base64 written to: $OUT ($BYTES characters)"
echo ""
echo "GitHub secrets to update (both must be from THIS same .p12 run):"
echo "  IOS_DISTRIBUTION_CERTIFICATE_BASE64  <- copy entire file contents"
echo "  IOS_DISTRIBUTION_CERTIFICATE_PASSWORD <- password you just entered"
echo ""
echo "Tip: open $OUT in a text editor, Select All, Copy."
echo "Do not paste secrets in chat."
