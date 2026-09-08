#!/bin/bash
# One-time setup: pushes Apple signing credentials into this repo's secrets.
#
# Uses the same five secret names as blint-agentic and brainstorm, so the
# values are identical to the ones already set on those repos. GitHub secrets
# are write-only, so they cannot be copied across automatically — pull them
# from wherever you keep the originals.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v gh >/dev/null || { echo "gh CLI required" >&2; exit 1; }

echo "Setting Apple signing secrets for $(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "These are the same values as your other Mac app repos."
echo

read -r -p  "Path to Developer ID .p12:            " P12_PATH
read -r -s -p "Password for that .p12:               " P12_PASSWORD; echo
read -r -p  "Apple ID (email):                     " APPLE_ID
read -r -s -p "App-specific password (xxxx-xxxx-...):" APPLE_ID_PASSWORD; echo
read -r -p  "Apple Team ID:                        " APPLE_TEAM_ID

[ -f "$P12_PATH" ] || { echo "No such file: $P12_PATH" >&2; exit 1; }

base64 -i "$P12_PATH"           | gh secret set CERTIFICATE_P12
printf '%s' "$P12_PASSWORD"     | gh secret set CERTIFICATE_PASSWORD
printf '%s' "$APPLE_ID"         | gh secret set APPLE_ID
printf '%s' "$APPLE_ID_PASSWORD"| gh secret set APPLE_ID_PASSWORD
printf '%s' "$APPLE_TEAM_ID"    | gh secret set APPLE_TEAM_ID

echo
gh secret list
echo
echo "Cut a release with:  git tag v1.0.0 && git push --tags"
