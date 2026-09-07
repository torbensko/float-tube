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

swiftc -O \
  -target arm64-apple-macos13.0 \
  -framework Cocoa -framework WebKit \
  -o "$APP/Contents/MacOS/FloatTube" \
  Sources/main.swift

# Ad-hoc sign so macOS keeps the app's identity stable between builds —
# without this the persistent cookie store can get thrown away.
codesign --force --sign - "$APP"

echo "Built $APP"
