#!/bin/bash
set -e

# Build and archive for Mac App Store distribution
# Usage: ./scripts/archive-appstore.sh [tag]

source "$(dirname "$0")/config.sh"

tag="${1:-}"
original_ref=""

if [[ -n "$tag" ]]; then
    ver="$tag"

    if ! git rev-parse "$tag" >/dev/null 2>&1; then
        echo "Error: Tag '$tag' not found"
        echo "Available tags:"
        git tag -l | sort -V | tail -10
        exit 1
    fi

    original_ref=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse HEAD)
    echo "Checking out tag: $tag"
    git checkout "$tag" --quiet
else
    ver=$(git describe --tags --always 2>/dev/null || echo "dev")
fi

cleanup() {
    if [[ -n "$original_ref" ]]; then
        echo "Returning to: $original_ref"
        git checkout "$original_ref" --quiet
    fi
}
trap cleanup EXIT

echo "Building for App Store: $ver"

marketing_version="${ver#v}"
# Strip git describe suffix (e.g. 1.0.0-3-gabcdef → 1.0.0)
marketing_version=$(echo "$marketing_version" | sed 's/-.*//' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' || echo "$marketing_version")
build_number=$(git rev-list --count HEAD)

echo "Setting MARKETING_VERSION=$marketing_version, BUILD=$build_number"

project_file="$PROJECT/project.pbxproj"
sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $marketing_version;/g" "$project_file"
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $build_number;/g" "$project_file"

ver_dir="$BUILD_DIR/$ver-appstore"
archive_path="$ver_dir/$APP_NAME.xcarchive"

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
    CODE_SIGN_STYLE=Automatic \
    MARKETING_VERSION="$marketing_version" \
    CURRENT_PROJECT_VERSION="$build_number"

echo "Archiving for iOS..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS' \
    -archivePath "$archive_path_ios" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    MARKETING_VERSION="$marketing_version" \
    CURRENT_PROJECT_VERSION="$build_number"

echo "$ver-appstore" > "$BUILD_DIR/.current_version_appstore"

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
