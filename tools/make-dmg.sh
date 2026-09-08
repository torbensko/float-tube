#!/bin/bash
# Packages build/FloatTube.app into a distributable .dmg
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-dev}"
APP="build/FloatTube.app"
DMG="build/FloatTube.dmg"   # unversioned: keeps the "latest download" URL stable

[ -d "$APP" ] || { echo "No $APP — run ./build.sh first" >&2; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"    # drag-to-install target

rm -f "$DMG"
hdiutil create -volname "FloatTube" -srcfolder "$STAGE" \
  -ov -format UDZO -quiet "$DMG"

IDENTITY="${CODESIGN_IDENTITY:-}"
if [ -n "$IDENTITY" ] && [ "$IDENTITY" != "-" ]; then
  codesign --force --timestamp --sign "$IDENTITY" "$DMG"
fi

echo "Built $DMG"
