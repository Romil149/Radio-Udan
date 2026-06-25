#!/usr/bin/env bash
# Import Distribution .p12 into a CI keychain (GitHub Actions macOS runner).
set -euo pipefail

python3 <<'PY'
import base64
import os
import subprocess
import sys

cert_b64 = os.environ["BUILD_CERTIFICATE_BASE64"].strip().replace("\n", "").replace("\r", "")
password = os.environ["P12_PASSWORD"]
runner_temp = os.environ["RUNNER_TEMP"]
keychain_password = os.environ["KEYCHAIN_PASSWORD"]

cert_path = os.path.join(runner_temp, "build_certificate.p12")
cert_pem = os.path.join(runner_temp, "cert.pem")
key_pem = os.path.join(runner_temp, "key.pem")
keychain_path = os.path.join(runner_temp, "app-signing.keychain-db")

try:
    cert_bytes = base64.b64decode(cert_b64, validate=True)
except Exception as exc:
    print(f"::error::Invalid IOS_DISTRIBUTION_CERTIFICATE_BASE64: {exc}")
    sys.exit(1)

with open(cert_path, "wb") as handle:
    handle.write(cert_bytes)

print(f"Decoded .p12 size: {len(cert_bytes)} bytes")

verify = subprocess.run(
    ["openssl", "pkcs12", "-in", cert_path, "-passin", f"pass:{password}", "-noout"],
    capture_output=True,
    text=True,
)
if verify.returncode != 0:
    print("::error::Cannot open .p12 with IOS_DISTRIBUTION_CERTIFICATE_PASSWORD.")
    print(verify.stderr.strip())
    print("Re-set secrets from .ios-signing/certificate-base64.txt using:")
    print("  gh secret set IOS_DISTRIBUTION_CERTIFICATE_BASE64 < .ios-signing/certificate-base64.txt")
    sys.exit(1)

print("openssl pkcs12 verification: OK")

subprocess.run(["security", "create-keychain", "-p", keychain_password, keychain_path], check=True)
subprocess.run(["security", "set-keychain-settings", "-lut", "21600", keychain_path], check=True)
subprocess.run(["security", "unlock-keychain", "-p", keychain_password, keychain_path], check=True)
subprocess.run(["security", "list-keychain", "-d", "user", "-s", keychain_path], check=True)

subprocess.run(
    ["openssl", "pkcs12", "-in", cert_path, "-passin", f"pass:{password}", "-clcerts", "-nokeys", "-out", cert_pem],
    check=True,
)
subprocess.run(
    ["openssl", "pkcs12", "-in", cert_path, "-passin", f"pass:{password}", "-nocerts", "-nodes", "-out", key_pem],
    check=True,
)

subprocess.run(["security", "import", cert_pem, "-k", keychain_path, "-A"], check=True)
subprocess.run(
    ["security", "import", key_pem, "-k", keychain_path, "-A", "-T", "/usr/bin/codesign", "-T", "/usr/bin/security"],
    check=True,
)
subprocess.run(
    [
        "security",
        "set-key-partition-list",
        "-S",
        "apple-tool:,apple:,codesign:",
        "-s",
        "-k",
        keychain_password,
        keychain_path,
    ],
    check=True,
)

print(f"Imported signing certificate into {keychain_path}")
PY
