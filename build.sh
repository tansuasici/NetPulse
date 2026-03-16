#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="NetPulse"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Compile
swiftc \
    -o "$BUILD_DIR/$APP_NAME" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework ServiceManagement \
    -lsqlite3 \
    -target arm64-apple-macos13.0 \
    -O \
    "$PROJECT_DIR"/Sources/*.swift

echo "Compiled successfully"

# Create .app bundle
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Move binary
mv "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Copy icon
cp "$PROJECT_DIR/Resources/icon.png" "$APP_BUNDLE/Contents/Resources/"

# Create .icns if iconutil is available
ICONSET_DIR="/tmp/NetPulse_build.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

ICON_SRC="$PROJECT_DIR/Resources/icon.png"
for size in 16 32 64 128 256 512 1024; do
    sips -z $size $size "$ICON_SRC" --out "$ICONSET_DIR/icon_${size}x${size}.png" > /dev/null 2>&1 || true
done

# Create proper iconset naming
cp "$ICONSET_DIR/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png" 2>/dev/null || true
cp "$ICONSET_DIR/icon_32x32.png" "$ICONSET_DIR/icon_16x16@2x.png" 2>/dev/null || true
cp "$ICONSET_DIR/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png" 2>/dev/null || true
cp "$ICONSET_DIR/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png" 2>/dev/null || true
cp "$ICONSET_DIR/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png" 2>/dev/null || true
cp "$ICONSET_DIR/icon_256x256.png" "$ICONSET_DIR/icon_128x128@2x.png" 2>/dev/null || true
cp "$ICONSET_DIR/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png" 2>/dev/null || true
cp "$ICONSET_DIR/icon_512x512.png" "$ICONSET_DIR/icon_256x256@2x.png" 2>/dev/null || true
cp "$ICONSET_DIR/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png" 2>/dev/null || true
cp "$ICONSET_DIR/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png" 2>/dev/null || true

# Remove non-standard names
rm -f "$ICONSET_DIR/icon_64x64.png" "$ICONSET_DIR/icon_1024x1024.png"

iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" 2>/dev/null || true
rm -rf "$ICONSET_DIR"

echo ""
echo "Built: $APP_BUNDLE"
echo "Run:   open \"$APP_BUNDLE\""
