#!/bin/bash
# One-time setup: pushes Apple signing + notarisation credentials into the
# GitHub repo's secrets. Re-run only if a certificate or key is rotated.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v gh >/dev/null || { echo "gh CLI required" >&2; exit 1; }

echo "Looking for a Developer ID Application certificate..."
IDENTITY="$(security find-identity -v -p codesigning \
  | grep "Developer ID Application" | head -1 \
  | sed -E 's/.*"(.*)"/\1/')" || true

if [ -z "${IDENTITY:-}" ]; then
  cat >&2 << 'MSG'
No "Developer ID Application" certificate in your keychain.

Create one first (you have the paid account, so this is free):
  Xcode > Settings > Accounts > select your team > Manage Certificates
  > "+" > Developer ID Application

Note: only the Account Holder or an Admin can create one. Then re-run this.
MSG
  exit 1
fi
echo "Found: $IDENTITY"

read -r -p "Path to exported Developer ID .p12: " P12_PATH
read -r -s -p "Password for that .p12: " P12_PASSWORD; echo
read -r -p "Path to App Store Connect API key (.p8): " P8_PATH
read -r -p "Key ID (e.g. 2X9R4HXF34): " KEY_ID
read -r -p "Issuer ID (UUID from App Store Connect): " ISSUER_ID

[ -f "$P12_PATH" ] || { echo "No such file: $P12_PATH" >&2; exit 1; }
[ -f "$P8_PATH" ]  || { echo "No such file: $P8_PATH" >&2; exit 1; }

echo "Setting secrets..."
base64 -i "$P12_PATH" | gh secret set MACOS_CERT_P12_BASE64
printf '%s' "$P12_PASSWORD"  | gh secret set MACOS_CERT_PASSWORD
printf '%s' "$IDENTITY"      | gh secret set MACOS_SIGN_IDENTITY
base64 -i "$P8_PATH"  | gh secret set MACOS_NOTARY_KEY_P8_BASE64
printf '%s' "$KEY_ID"        | gh secret set MACOS_NOTARY_KEY_ID
printf '%s' "$ISSUER_ID"     | gh secret set MACOS_NOTARY_ISSUER_ID

echo
echo "Done. Secrets set:"
gh secret list
echo
echo "Cut a release with:  git tag v1.0.0 && git push --tags"
