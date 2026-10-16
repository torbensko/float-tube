#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${CODESIGN_IDENTITY:?Developer ID Application identity required}"
: "${APPLE_ID:?Missing APPLE_ID}"
: "${APPLE_ID_PASSWORD:?Missing APPLE_ID_PASSWORD}"
: "${APPLE_TEAM_ID:?Missing APPLE_TEAM_ID}"
[[ "$CODESIGN_IDENTITY" == 'Developer ID Application:'* ]] || exit 1
UNIVERSAL=1 ./build.sh
APP="$PWD/build/FloatTube.app"
ARCHITECTURES=" $(lipo -archs "$APP/Contents/MacOS/FloatTube") "
[[ "$ARCHITECTURES" == *' arm64 '* && "$ARCHITECTURES" == *' x86_64 '* ]]
notarize() {
  xcrun notarytool submit "$1" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" --wait --timeout 30m --output-format json > "$2"
  python3 - "$2" <<'CHECK'
import json,sys
result=json.load(open(sys.argv[1]))
if result.get('status') != 'Accepted':
    sys.exit(f"Notarization failed: {result}")
CHECK
}
# Apple ticket lookups occasionally fail transiently; keep validation mandatory.
retry() {
  local attempt
  for attempt in 1 2 3; do
    if "$@"; then return 0; fi
    if [[ "$attempt" != 3 ]]; then sleep 10; fi
  done
  return 1
}
ditto -c -k --keepParent "$APP" build/submission.zip
notarize build/submission.zip build/notary-app.json
retry xcrun stapler staple "$APP"
retry xcrun stapler validate "$APP"
spctl --assess --type execute --verbose "$APP"
./tools/make-dmg.sh "$(cat VERSION)"
notarize build/FloatTube.dmg build/notary-dmg.json
retry xcrun stapler staple build/FloatTube.dmg
retry xcrun stapler validate build/FloatTube.dmg
ditto -c -k --keepParent "$APP" build/FloatTube.zip
(cd build && shasum -a 256 FloatTube.dmg FloatTube.zip > SHA256SUMS.txt)
rm -f build/submission.zip
