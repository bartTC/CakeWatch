#!/bin/bash
set -e

# Build, sign, and archive for distribution
# Usage: ./scripts/archive.sh [tag]

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

echo "Building version: $ver"

marketing_version="${ver#v}"
# Strip git describe suffix (e.g. 1.0.0-3-gabcdef → 1.0.0)
marketing_version=$(echo "$marketing_version" | sed 's/-.*//' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' || echo "$marketing_version")
build_number=$(git rev-list --count HEAD)

echo "Setting MARKETING_VERSION=$marketing_version, BUILD=$build_number"

project_file="$PROJECT/project.pbxproj"
sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $marketing_version;/g" "$project_file"
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $build_number;/g" "$project_file"

ver_dir="$BUILD_DIR/$ver"
archive_path="$ver_dir/$APP_NAME.xcarchive"
export_path="$ver_dir/export"

mkdir -p "$ver_dir"

xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=macOS' \
    -archivePath "$archive_path" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Developer ID Application"

cat > "$ver_dir/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "$archive_path" \
    -exportPath "$export_path" \
    -exportOptionsPlist "$ver_dir/ExportOptions.plist"

echo "$ver" > "$BUILD_DIR/.current_version"

echo "✓ Archive complete: $export_path/$APP_NAME.app"
