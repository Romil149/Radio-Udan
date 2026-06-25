#!/usr/bin/env bash
# Radio Udaan — one-time setup for GitHub Actions iOS → TestFlight builds.
set -euo pipefail

BUNDLE_ID="org.reactjs.native.example.Radio"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSR_DIR="${REPO_ROOT}/.ios-signing"
CSR_KEY="${CSR_DIR}/distribution.key"
CSR_FILE="${CSR_DIR}/distribution.csr"

print_help() {
  echo "=============================================="
  echo " Radio Udaan — iOS GitHub Actions setup"
  echo " Bundle ID: ${BUNDLE_ID}"
  echo "=============================================="
  echo ""
  echo "Commands:"
  echo "  bash scripts/ios-github-secrets-setup.sh csr"
  echo "  bash scripts/ios-github-secrets-setup.sh p12 path/to/distribution.cer [password]"
  echo "  bash scripts/ios-github-secrets-setup.sh encode-profile path/to/profile.mobileprovision"
  echo ""
  echo "Then verify .p12:"
  echo "  bash scripts/ios-verify-and-encode-p12.sh .ios-signing/distribution.p12"
}

if [[ "${1:-}" == "csr" ]]; then
  mkdir -p "$CSR_DIR"
  openssl genrsa -out "$CSR_KEY" 2048
  openssl req -new -key "$CSR_KEY" -out "$CSR_FILE" -subj "/CN=Radio Udaan Distribution/O=Minal Singhvi/C=IN"
  echo "Created:"
  echo "  $CSR_KEY"
  echo "  $CSR_FILE"
  echo "Upload $CSR_FILE when creating Apple Distribution certificate."
  exit 0
fi

if [[ "${1:-}" == "p12" ]]; then
  CER="${2:-}"
  if [[ -z "$CER" || ! -f "$CER" ]]; then
    echo "Usage: $0 p12 path/to/distribution.cer [password]"
    exit 1
  fi
  if [[ ! -f "$CSR_KEY" ]]; then
    echo "Missing $CSR_KEY — run: $0 csr"
    exit 1
  fi
  P12="${CSR_DIR}/distribution.p12"
  openssl x509 -inform DER -in "$CER" -out "${CSR_DIR}/distribution.pem" 2>/dev/null \
    || openssl x509 -inform PEM -in "$CER" -out "${CSR_DIR}/distribution.pem"
  if [[ -n "${3:-}" ]]; then
    P12_PASS="$3"
  else
    read -r -s -p "Password for .p12 export: " P12_PASS
    echo ""
  fi
  openssl pkcs12 -export -out "$P12" -inkey "$CSR_KEY" -in "${CSR_DIR}/distribution.pem" \
    -password "pass:${P12_PASS}" \
    -certpbe AES-256-CBC -keypbe AES-256-CBC -macalg SHA256
  echo "Created: $P12"
  echo "Run: bash scripts/ios-verify-and-encode-p12.sh $P12 '' '$P12_PASS'"
  exit 0
fi

if [[ "${1:-}" == "encode-profile" ]]; then
  PROFILE="${2:-}"
  if [[ -z "$PROFILE" || ! -f "$PROFILE" ]]; then
    echo "Usage: $0 encode-profile path/to/profile.mobileprovision"
    exit 1
  fi
  echo "IOS_PROVISIONING_PROFILE_BASE64:"
  base64 < "$PROFILE" | tr -d '\n'
  echo ""
  exit 0
fi

print_help
