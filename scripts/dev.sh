#!/bin/bash
# Build and run Claude Island for development
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/DerivedData"
APP_PATH="$BUILD_DIR/Build/Products/Debug/Claude Island.app"

# Kill existing instance
pkill -f "Claude Island.app/Contents/MacOS/Claude Island" 2>/dev/null && echo "Stopped previous instance" && sleep 1 || true

echo "Building..."
xcodebuild -scheme ClaudeIsland \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    build 2>&1 | tail -3

echo "Launching..."
open "$APP_PATH"
echo "Running."
