#!/usr/bin/env bash
# Radio Udaan — one-time setup for GitHub Actions iOS → TestFlight builds.
# Run on any machine (Mac, Linux, or Windows Git Bash). No Xcode required for
# steps 1–3; step 2 needs openssl (pre-installed on macOS/Linux).
set -euo pipefail

BUNDLE_ID="org.reactjs.native.example.Radio"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSR_DIR="${REPO_ROOT}/.ios-signing"
CSR_KEY="${CSR_DIR}/distribution.key"
CSR_FILE="${CSR_DIR}/distribution.csr"

echo "=============================================="
echo " Radio Udaan — iOS GitHub Actions setup"
echo " Bundle ID: ${BUNDLE_ID}"
echo "=============================================="
echo ""

echo "STEP 1 — App Store Connect API key (optional — skip if you upload the IPA manually)"
echo "  Only needed for automatic TestFlight upload from GitHub."
echo "  Manual path: download .ipa artifact → Transporter on Mac → TestFlight."
echo ""
echo "  If you want auto-upload later:"
echo "  https://appstoreconnect.apple.com/access/integrations/api"
echo "  Secrets: APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_KEY_ID,"
echo "           APP_STORE_CONNECT_API_PRIVATE_KEY"
echo ""

echo "STEP 2 — Apple Distribution certificate (no Mac)"
echo "  A) Generate CSR + private key:"
echo "     bash scripts/ios-github-secrets-setup.sh csr"
echo "  B) https://developer.apple.com/account/resources/certificates/list"
echo "     + → Apple Distribution → upload distribution.csr"
echo "  C) Download distribution.cer to ${CSR_DIR}/"
echo "  D) Create .p12:"
echo "     bash scripts/ios-github-secrets-setup.sh p12 ${CSR_DIR}/distribution.cer"
echo ""
echo "  GitHub secrets:"
echo "    IOS_DISTRIBUTION_CERTIFICATE_BASE64   = base64 of .p12"
echo "    IOS_DISTRIBUTION_CERTIFICATE_PASSWORD = password you chose for .p12"
echo ""

echo "STEP 3 — App Store provisioning profile (browser)"
echo "  1. https://developer.apple.com/account/resources/profiles/list"
echo "  2. + → App Store Connect → App ID: ${BUNDLE_ID}"
echo "  3. Select your Distribution certificate → name e.g. Radio Udaan App Store"
echo "  4. Download .mobileprovision"
echo ""
echo "  GitHub secrets:"
echo "    IOS_PROVISIONING_PROFILE_BASE64 = base64 of .mobileprovision"
echo "    IOS_PROVISIONING_PROFILE_NAME   = exact profile name from portal"
echo ""

echo "STEP 4 — Team ID"
echo "  https://developer.apple.com/account → Membership details → Team ID"
echo "  GitHub secret: APPLE_TEAM_ID"
echo ""

echo "STEP 5 — Add secrets in GitHub"
echo "  https://github.com/YOUR_ORG/Radio-Udan/settings/secrets/actions"
echo "  Required (5): APPLE_TEAM_ID, IOS_DISTRIBUTION_CERTIFICATE_BASE64,"
echo "    IOS_DISTRIBUTION_CERTIFICATE_PASSWORD, IOS_PROVISIONING_PROFILE_BASE64,"
echo "    IOS_PROVISIONING_PROFILE_NAME"
echo "  Then: Actions → Build iOS IPA → Run workflow"
echo ""

echo "STEP 6 — Download IPA and upload manually"
echo "  Actions → workflow run → Artifacts → download .ipa"
echo "  Mac: Transporter app or Xcode Organizer → App Store Connect"
echo "  App Store Connect → Radio Udaan → TestFlight → add build to Internal Testing"
echo ""

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
    echo "Usage: $0 p12 path/to/distribution.cer"
    exit 1
  fi
  if [[ ! -f "$CSR_KEY" ]]; then
    echo "Missing $CSR_KEY — run: $0 csr"
    exit 1
  fi
  P12="${CSR_DIR}/distribution.p12"
  openssl x509 -inform DER -in "$CER" -out "${CSR_DIR}/distribution.pem"
  read -r -s -p "Password for .p12 export: " P12_PASS
  echo ""
  openssl pkcs12 -export -out "$P12" -inkey "$CSR_KEY" -in "${CSR_DIR}/distribution.pem" -password "pass:${P12_PASS}"
  echo ""
  echo "Created: $P12"
  echo ""
  echo "Base64 for GitHub secret IOS_DISTRIBUTION_CERTIFICATE_BASE64:"
  base64 < "$P12" | tr -d '\n'
  echo ""
  echo ""
  echo "IOS_DISTRIBUTION_CERTIFICATE_PASSWORD = (the password you just entered)"
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

echo "Commands:"
echo "  bash scripts/ios-github-secrets-setup.sh csr"
echo "  bash scripts/ios-github-secrets-setup.sh p12 path/to/distribution.cer"
echo "  bash scripts/ios-github-secrets-setup.sh encode-profile path/to/profile.mobileprovision"
