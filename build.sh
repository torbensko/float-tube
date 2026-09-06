#!/bin/bash
# Builds FloatTube.app. No Xcode project required.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/FloatTube.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>FloatTube</string>
  <key>CFBundleDisplayName</key>     <string>FloatTube</string>
  <key>CFBundleIdentifier</key>      <string>dev.blint.floattube</string>
  <key>CFBundleExecutable</key>      <string>FloatTube</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>CFBundleShortVersionString</key> <string>0.1</string>
  <key>CFBundleVersion</key>         <string>1</string>
  <key>LSMinimumSystemVersion</key>  <string>13.0</string>
  <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
EOF

swiftc -O \
  -target arm64-apple-macos13.0 \
  -framework Cocoa -framework WebKit \
  -o "$APP/Contents/MacOS/FloatTube" \
  Sources/main.swift

# Ad-hoc sign so macOS keeps the app's identity stable between builds —
# without this the persistent cookie store can get thrown away.
codesign --force --sign - "$APP"

echo "Built $APP"
