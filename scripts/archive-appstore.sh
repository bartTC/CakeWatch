#!/bin/bash
set -e

# Build and archive for Mac App Store distribution
# Usage: ./scripts/archive-appstore.sh

source "$(dirname "$0")/config.sh"

project_file="$PROJECT/project.pbxproj"

# Read version and build number from pbxproj
marketing_version=$(grep -m1 'MARKETING_VERSION' "$project_file" | sed 's/.*= //;s/;.*//')
build_number=$(grep -m1 'CURRENT_PROJECT_VERSION' "$project_file" | sed 's/.*= //;s/;.*//')

echo "Building for App Store: v${marketing_version} (${build_number})"

ver_dir="$BUILD_DIR/v${marketing_version}-appstore"

mkdir -p "$ver_dir"

archive_path_macos="$ver_dir/$APP_NAME-macOS.xcarchive"
archive_path_ios="$ver_dir/$APP_NAME-iOS.xcarchive"

echo "Archiving for macOS..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=macOS' \
    -archivePath "$archive_path_macos" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Automatic

echo "Archiving for iOS..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS' \
    -archivePath "$archive_path_ios" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Automatic

echo ""
echo "✓ App Store archives complete:"
echo "  macOS: $archive_path_macos"
echo "  iOS:   $archive_path_ios"
echo ""
echo "Next steps (manual):"
echo "  1. Open archives in Xcode Organizer:"
echo "     open $archive_path_macos"
echo "     open $archive_path_ios"
echo "  2. Click 'Distribute App' → 'App Store Connect' for each"
echo "  3. Submit for review in App Store Connect"
