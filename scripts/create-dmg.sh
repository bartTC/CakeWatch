#!/bin/bash
set -e

# Create DMG installer with drag-to-Applications window
# Usage: ./scripts/create-dmg.sh [version]
# Requires: brew install create-dmg

source "$(dirname "$0")/config.sh"

if [[ -n "$1" ]]; then
    ver="$1"
elif [[ -f "$BUILD_DIR/.current_version" ]]; then
    ver=$(cat "$BUILD_DIR/.current_version")
else
    echo "Error: No version specified"
    exit 1
fi

ver_dir="$BUILD_DIR/$ver"
app_path="$ver_dir/export/$APP_NAME.app"
dmg_path="$ver_dir/$APP_NAME-$ver.dmg"

if [[ ! -d "$app_path" ]]; then
    echo "Error: App not found at $app_path"
    echo "Run 'just archive $ver' first."
    exit 1
fi

rm -f "$dmg_path"

echo "Creating DMG for $ver..."

create-dmg \
    --volname "$APP_NAME" \
    --volicon "$app_path/Contents/Resources/AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 150 125 \
    --app-drop-link 450 125 \
    --hide-extension "$APP_NAME.app" \
    "$dmg_path" \
    "$app_path"

echo ""
echo "DMG created: $dmg_path"
