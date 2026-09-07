#!/bin/bash
# Builds FloatTube and installs it into /Applications, then launches it.
set -euo pipefail
cd "$(dirname "$0")"

DEST="/Applications/FloatTube.app"

./build.sh

# Ask the running copy to quit so we're not overwriting a live bundle.
if pgrep -qf "FloatTube.app/Contents/MacOS/FloatTube"; then
  echo "Quitting the running copy..."
  osascript -e 'tell application "FloatTube" to quit' 2>/dev/null || true
  for _ in $(seq 1 20); do
    pgrep -qf "FloatTube.app/Contents/MacOS/FloatTube" || break
    sleep 0.25
  done
  pkill -f "FloatTube.app/Contents/MacOS/FloatTube" 2>/dev/null || true
fi

rm -rf "$DEST"
cp -R "build/FloatTube.app" "$DEST"

# Nothing was downloaded, but strip quarantine defensively so Gatekeeper
# never shows the "unidentified developer" prompt for a locally built app.
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

# Tell LaunchServices about it so the icon and name refresh immediately.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$DEST" 2>/dev/null || true
touch "$DEST"

echo "Installed $DEST"
open "$DEST"
