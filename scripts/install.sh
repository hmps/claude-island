#!/bin/bash
# Build Claude Island (Release) and install to /Applications
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Claude Island.app"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME"
INSTALL_PATH="/Applications/$APP_NAME"

# Kill existing instance
pkill -f "Claude Island.app/Contents/MacOS/Claude Island" 2>/dev/null && echo "Stopped previous instance" && sleep 1 || true

echo "Building Release..."
xcodebuild -project "$PROJECT_DIR/ClaudeIsland.xcodeproj" \
    -scheme ClaudeIsland \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    clean build 2>&1 | tail -3

echo "Installing to /Applications..."
rm -rf "$INSTALL_PATH"
cp -R "$APP_PATH" "$INSTALL_PATH"
xattr -cr "$INSTALL_PATH"
codesign --force --deep --sign - "$INSTALL_PATH"

echo "Launching..."
open "$INSTALL_PATH"
echo "Done."
