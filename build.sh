#!/bin/bash
# Builds FloatTube.app into ./build. No Xcode project required.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/FloatTube.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

VERSION="1.0"
BUILD_NUM="$(date +%Y%m%d%H%M)"

cat > "$APP/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>              <string>FloatTube</string>
  <key>CFBundleDisplayName</key>       <string>FloatTube</string>
  <key>CFBundleIdentifier</key>        <string>dev.blint.floattube</string>
  <key>CFBundleExecutable</key>        <string>FloatTube</string>
  <key>CFBundleIconFile</key>          <string>FloatTube</string>
  <key>CFBundlePackageType</key>       <string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key>           <string>${BUILD_NUM}</string>
  <key>LSMinimumSystemVersion</key>    <string>13.0</string>
  <key>LSApplicationCategoryType</key> <string>public.app-category.entertainment</string>
  <key>NSHighResolutionCapable</key>   <true/>
  <key>NSSupportsAutomaticTermination</key> <false/>
  <key>NSSupportsSuddenTermination</key>    <false/>
</dict>
</plist>
PLIST

cp Resources/FloatTube.icns "$APP/Contents/Resources/FloatTube.icns"

BIN="$APP/Contents/MacOS/FloatTube"

if [ "${UNIVERSAL:-0}" = "1" ]; then
  # Release builds cover Intel too, since people we share with may be on one.
  for ARCH in arm64 x86_64; do
    swiftc -O -target ${ARCH}-apple-macos13.0 \
      -framework Cocoa -framework WebKit \
      -o "build/FloatTube-${ARCH}" Sources/main.swift
  done
  lipo -create -output "$BIN" build/FloatTube-arm64 build/FloatTube-x86_64
  rm -f build/FloatTube-arm64 build/FloatTube-x86_64
else
  swiftc -O -target arm64-apple-macos13.0 \
    -framework Cocoa -framework WebKit \
    -o "$BIN" Sources/main.swift
fi

# Ad-hoc ("-") by default, which keeps the bundle identity stable between local
# builds so the persistent cookie store survives. CI overrides this with a
# Developer ID so the result can be notarised.
IDENTITY="${CODESIGN_IDENTITY:--}"
SIGN_ARGS=(--force --options runtime --sign "$IDENTITY")
[ "$IDENTITY" = "-" ] || SIGN_ARGS+=(--timestamp)   # timestamping needs a real identity
codesign "${SIGN_ARGS[@]}" "$APP"
codesign --verify --strict "$APP"

echo "Built $APP"
