#!/bin/bash
# Build, deploy, and run Prompty
# After rebuilding, you must re-grant Input Monitoring + Accessibility permissions.

set -e

APP_PATH="/Applications/Prompty.app"
BINARY="$APP_PATH/Contents/MacOS/Prompty"

echo "Building Prompty..."
swift build

echo "Stopping existing instance..."
pkill -f "Prompty.app" 2>/dev/null || true
sleep 1

echo "Deploying to $APP_PATH..."
mkdir -p "$APP_PATH/Contents/MacOS"

# Only copy Info.plist if missing
if [ ! -f "$APP_PATH/Contents/Info.plist" ]; then
cat > "$APP_PATH/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.prompty.app</string>
    <key>CFBundleName</key>
    <string>Prompty</string>
    <key>CFBundleDisplayName</key>
    <string>Prompty</string>
    <key>CFBundleExecutable</key>
    <string>Prompty</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>Prompty needs Accessibility access to read and replace selected text in other apps.</string>
</dict>
</plist>
PLIST
fi

cp .build/debug/Prompty "$BINARY"
codesign --force --deep --sign - "$APP_PATH" 2>/dev/null

echo ""
echo "✅ Built and deployed to $APP_PATH"
echo ""
echo "⚠️  You need to re-grant permissions after each rebuild:"
echo "   System Settings → Privacy & Security → Input Monitoring"
echo "   Remove Prompty, add it again from /Applications, toggle ON"
echo "   Also: Accessibility → same steps"
echo ""
echo "Launching..."
open "$APP_PATH"
