#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="NetPulse"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
MIN_MACOS="13.0"

echo "Building $APP_NAME..."

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

SWIFT_FILES="$PROJECT_DIR"/Sources/*.swift
FRAMEWORKS="-framework Cocoa -framework SwiftUI -framework ServiceManagement -lsqlite3"

# Compile for arm64
echo "  Compiling arm64..."
swiftc \
    -o "$BUILD_DIR/${APP_NAME}_arm64" \
    $FRAMEWORKS \
    -target arm64-apple-macos${MIN_MACOS} \
    -O \
    $SWIFT_FILES

# Compile for x86_64
echo "  Compiling x86_64..."
swiftc \
    -o "$BUILD_DIR/${APP_NAME}_x86_64" \
    $FRAMEWORKS \
    -target x86_64-apple-macos${MIN_MACOS} \
    -O \
    $SWIFT_FILES

# Create universal binary
echo "  Creating universal binary..."
lipo -create \
    "$BUILD_DIR/${APP_NAME}_arm64" \
    "$BUILD_DIR/${APP_NAME}_x86_64" \
    -output "$BUILD_DIR/$APP_NAME"

rm "$BUILD_DIR/${APP_NAME}_arm64" "$BUILD_DIR/${APP_NAME}_x86_64"

echo "  Compiled successfully (universal: arm64 + x86_64)"

# Create .app bundle
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

mv "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"
cp "$PROJECT_DIR/Resources/icon.png" "$APP_BUNDLE/Contents/Resources/"

# Create .icns
ICONSET_DIR="/tmp/NetPulse_build.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

ICON_SRC="$PROJECT_DIR/Resources/icon.png"
sips -z 16 16 "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
sips -z 32 32 "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
sips -z 32 32 "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
sips -z 64 64 "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
sips -z 128 128 "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
sips -z 256 256 "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
sips -z 256 256 "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
sips -z 512 512 "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
sips -z 512 512 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1
sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1

iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" 2>/dev/null || true
rm -rf "$ICONSET_DIR"

# Verify
ARCHS=$(lipo -info "$APP_BUNDLE/Contents/MacOS/$APP_NAME" 2>/dev/null | awk -F': ' '{print $NF}')
SIZE=$(du -sh "$APP_BUNDLE" | awk '{print $1}')

echo ""
echo "Built: $APP_BUNDLE"
echo "Size:  $SIZE"
echo "Arch:  $ARCHS"
echo "Run:   open \"$APP_BUNDLE\""
