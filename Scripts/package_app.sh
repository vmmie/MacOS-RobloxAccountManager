#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MacOS-RobloxAccountManager"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"

cd "$ROOT"

if swift build -c release --triple arm64-apple-macosx14.0 && swift build -c release --triple x86_64-apple-macosx14.0; then
  EXECUTABLE="$DIST/$APP_NAME-universal"
  lipo -create \
    "$ROOT/.build/arm64-apple-macosx/release/$APP_NAME" \
    "$ROOT/.build/x86_64-apple-macosx/release/$APP_NAME" \
    -output "$EXECUTABLE"
else
  echo "Universal build failed; falling back to host architecture." >&2
  swift build -c release
  EXECUTABLE="$ROOT/.build/release/$APP_NAME"
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$EXECUTABLE" "$APP/Contents/MacOS/$APP_NAME"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>com.github.vmmie.MacOS-RobloxAccountManager</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>MacOS Roblox Account Manager</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.2.0</string>
  <key>CFBundleVersion</key>
  <string>2</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

chmod +x "$APP/Contents/MacOS/$APP_NAME"
xattr -cr "$APP" 2>/dev/null || true
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
ditto -c -k --keepParent "$APP" "$DIST/$APP_NAME-v0.2.0-macos.zip"
echo "$APP"
