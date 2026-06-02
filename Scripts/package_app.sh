#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MacOS-RobloxAccountManager"
VERSION="0.4.0"
BUILD="5"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
ICON_SOURCE="$ROOT/Assets/AppIconSource.png"
ICONSET="$DIST/AppIcon.iconset"
ICON_ICNS="$DIST/AppIcon.icns"
DMG_ROOT="$DIST/dmg-root"
DMG_MOUNT="$DIST/dmg-mount"
DMG_RW="$DIST/$APP_NAME-v$VERSION-macos-rw.dmg"
DMG_FINAL="$DIST/$APP_NAME-v$VERSION-macos.dmg"
DMG_BACKGROUND="$DMG_ROOT/.background/background.png"

cd "$ROOT"
mkdir -p "$DIST"

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

if [[ -f "$ICON_SOURCE" ]]; then
  rm -rf "$ICONSET" "$ICON_ICNS"
  mkdir -p "$ICONSET"
  sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$ICONSET" -o "$ICON_ICNS"
  cp "$ICON_ICNS" "$APP/Contents/Resources/AppIcon.icns"
else
  echo "Warning: icon source not found at $ICON_SOURCE; packaging without an app icon." >&2
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>com.github.vmmie.MacOS-RobloxAccountManager</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>MacOS Roblox Account Manager</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD</string>
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
ditto -c -k --keepParent "$APP" "$DIST/$APP_NAME-v$VERSION-macos.zip"

rm -rf "$DMG_ROOT" "$DMG_MOUNT" "$DMG_RW" "$DMG_FINAL"
mkdir -p "$DMG_ROOT/.background" "$DMG_MOUNT"
cp -R "$APP" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"
swift "$ROOT/Scripts/make_dmg_background.swift" "$DMG_BACKGROUND"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -fs HFS+ \
  -ov \
  -format UDRW \
  "$DMG_RW"

cleanup_dmg_mount() {
  hdiutil detach "$DMG_MOUNT" >/dev/null 2>&1 || true
}

trap cleanup_dmg_mount EXIT
hdiutil attach "$DMG_RW" -readwrite -noautoopen -mountpoint "$DMG_MOUNT"
osascript <<APPLESCRIPT
set dmgFolder to POSIX file "$DMG_MOUNT" as alias
set bgFile to POSIX file "$DMG_MOUNT/.background/background.png" as alias
tell application "Finder"
  open dmgFolder
  delay 1
  set current view of container window of dmgFolder to icon view
  set toolbar visible of container window of dmgFolder to false
  set statusbar visible of container window of dmgFolder to false
  set bounds of container window of dmgFolder to {200, 140, 760, 460}
  set viewOptions to the icon view options of container window of dmgFolder
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 96
  set background picture of viewOptions to bgFile
  set position of item "$APP_NAME.app" of dmgFolder to {150, 160}
  set position of item "Applications" of dmgFolder to {410, 160}
  close container window of dmgFolder
end tell
APPLESCRIPT
sync
hdiutil detach "$DMG_MOUNT"
trap - EXIT
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL"
rm -rf "$DMG_MOUNT" "$DMG_RW"

echo "$APP"
echo "$DMG_FINAL"
