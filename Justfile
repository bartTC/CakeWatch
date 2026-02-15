# StatusBake - Build & Release Commands
# Usage: just <command>

set dotenv-load

scheme := "StatusBake"
build_dir := "build"

default:
    @just --list

# Show current version from git
version:
    @git describe --tags --always 2>/dev/null || echo "untagged"

# =============================================================================
# Development
# =============================================================================

# Build the app (use --dev for faster incremental builds, --open to launch)
build *flags:
    #!/usr/bin/env bash
    args="-scheme {{scheme}} -destination 'platform=macOS'"
    if [[ "{{flags}}" == *"--dev"* ]]; then
        args="$args -configuration Debug -derivedDataPath build/DerivedData -skipPackagePluginValidation -skipMacroValidation"
    fi
    eval xcodebuild build $args
    if [[ "{{flags}}" == *"--open"* ]]; then
        if [[ "{{flags}}" == *"--dev"* ]]; then
            app="build/DerivedData/Build/Products/Debug/{{scheme}}.app"
        else
            app=$(xcodebuild -scheme {{scheme}} -showBuildSettings 2>/dev/null | grep -m1 ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/{{scheme}}.app
        fi
        pkill -x "{{scheme}}" 2>/dev/null && sleep 0.5
        open "$app"
    fi

# Clean build artifacts
clean:
    rm -rf "{{build_dir}}"
    xcodebuild clean -scheme {{scheme}}

# Open project in Xcode
xcode:
    open StatusBake.xcodeproj

# =============================================================================
# Release (requires APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD in .env)
# =============================================================================

# Build and sign for distribution (optionally specify a tag)
archive tag="":
    ./scripts/archive.sh {{tag}}

# Submit for notarization
submit version="":
    ./scripts/submit.sh {{version}}

# Check notarization status
status id="":
    #!/usr/bin/env bash
    submission_id="{{id}}"
    [[ -z "$submission_id" && -f "{{build_dir}}/.current_version" ]] && \
        submission_id=$(cat "{{build_dir}}/$(cat {{build_dir}}/.current_version)/.submission_id" 2>/dev/null)
    [[ -z "$submission_id" ]] && { echo "No submission ID"; exit 1; }
    xcrun notarytool info "$submission_id" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD"

# Wait for notarization
wait id="":
    #!/usr/bin/env bash
    submission_id="{{id}}"
    [[ -z "$submission_id" && -f "{{build_dir}}/.current_version" ]] && \
        submission_id=$(cat "{{build_dir}}/$(cat {{build_dir}}/.current_version)/.submission_id" 2>/dev/null)
    xcrun notarytool wait "$submission_id" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD"

# Staple ticket and create final zip
staple version="":
    ./scripts/staple.sh {{version}}

# Release pipeline: archive and submit for notarization
release tag="":
    #!/usr/bin/env bash
    set -e
    just archive {{tag}}
    just submit
    echo ""
    echo "Submitted for notarization. Next steps:"
    echo "  just status              # Check notarization status"
    echo "  just staple              # Staple after approval"
    echo "  just dmg                 # Create DMG installer"

# Show notarization history
history:
    xcrun notarytool history --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD"

# Get notarization log
log id:
    xcrun notarytool log {{id}} --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD"

# List available builds
builds:
    @ls -d {{build_dir}}/v* {{build_dir}}/dev 2>/dev/null | xargs -I{} basename {} | sort -V || echo "(none)"

# Create DMG installer (requires create-dmg: brew install create-dmg)
dmg version="":
    ./scripts/create-dmg.sh {{version}}

# =============================================================================
# App Store (requires Apple Distribution certificate)
# =============================================================================

# Build and sign for App Store, then upload manually via Xcode Organizer
release-appstore tag="":
    ./scripts/archive-appstore.sh {{tag}}
