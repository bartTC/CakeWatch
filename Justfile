# CakeWatch - Build & Release Commands
# Usage: just <command>

set dotenv-load

scheme := "CakeWatch"
build_dir := "build"

default:
    @just --list

# Show current version from git
version:
    @git describe --tags --always 2>/dev/null || echo "untagged"

# =============================================================================
# Development
# =============================================================================

# Build and run the app (--ios for simulator, --device for physical iPhone, default macOS; --dev for faster incremental builds)
build *flags:
    #!/usr/bin/env bash
    set -e
    if [[ "{{flags}}" == *"--device"* ]]; then
        # Build and run on a connected physical iPhone
        tmpjson=$(mktemp /tmp/devices.XXXXXX.json)
        xcrun devicectl list devices --json-output "$tmpjson" 2>/dev/null
        device_id=$(python3 -c "
    import json,sys
    data=json.load(open('$tmpjson'))
    for d in data.get('result',{}).get('devices',[]):
        conn=d.get('connectionProperties',{})
        if conn.get('transportType','')=='wired' and 'iPhone' in d.get('deviceProperties',{}).get('name',''):
            print(d['identifier']); sys.exit()
    for d in data.get('result',{}).get('devices',[]):
        if 'iPhone' in d.get('deviceProperties',{}).get('name','') and d.get('visibilityClass','')=='default':
            print(d['identifier']); sys.exit()
    " 2>/dev/null)
        rm -f "$tmpjson"
        if [[ -z "$device_id" ]]; then
            echo "No connected iPhone found. Connect via USB and trust the device."
            exit 1
        fi
        echo "Building for device $device_id..."
        xcodebuild build -scheme {{scheme}} -destination "generic/platform=iOS" -allowProvisioningUpdates
        echo "Installing on device..."
        app_path=$(xcodebuild -scheme {{scheme}} -destination "generic/platform=iOS" -showBuildSettings 2>/dev/null | grep -m1 ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/{{scheme}}.app
        xcrun devicectl device install app --device "$device_id" "$app_path"
        xcrun devicectl device process launch --device "$device_id" elephanthouse.CakeWatchApp
    elif [[ "{{flags}}" == *"--ios"* ]]; then
        # Find a booted simulator or boot the first available iPhone
        booted=$(xcrun simctl list devices booted -j | python3 -c "
    import json,sys
    data=json.load(sys.stdin)
    for runtime,devs in data.get('devices',{}).items():
        for d in devs:
            if d['state']=='Booted' and 'iPhone' in d['name']:
                print(d['udid']); sys.exit()
    " 2>/dev/null || true)
        if [[ -z "$booted" ]]; then
            udid=$(xcrun simctl list devices available -j | python3 -c "
    import json,sys
    data=json.load(sys.stdin)
    for runtime,devs in sorted(data.get('devices',{}).items(), reverse=True):
        for d in devs:
            if d['isAvailable'] and 'iPhone' in d['name']:
                print(d['udid']); sys.exit()
    ")
            echo "Booting simulator $udid..."
            xcrun simctl boot "$udid"
            booted="$udid"
        fi
        open -a Simulator
        xcodebuild build -scheme {{scheme}} -sdk iphonesimulator -destination "id=$booted"
        # Install and launch on simulator
        app_path=$(xcodebuild -scheme {{scheme}} -sdk iphonesimulator -destination "id=$booted" -showBuildSettings 2>/dev/null | grep -m1 ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/{{scheme}}.app
        xcrun simctl install "$booted" "$app_path"
        xcrun simctl launch "$booted" elephanthouse.CakeWatchApp
    else
        args="-scheme {{scheme}} -destination 'platform=macOS'"
        if [[ "{{flags}}" == *"--dev"* ]]; then
            args="$args -configuration Debug -derivedDataPath build/DerivedData -skipPackagePluginValidation -skipMacroValidation"
        fi
        eval xcodebuild build $args
        if [[ "{{flags}}" == *"--dev"* ]]; then
            app="build/DerivedData/Build/Products/Debug/{{scheme}}.app"
        else
            app=$(xcodebuild -scheme {{scheme}} -showBuildSettings 2>/dev/null | grep -m1 ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/{{scheme}}.app
        fi
        pkill -x "{{scheme}}" 2>/dev/null && sleep 0.5
        open "$app"
    fi

# Run tests
test:
    xcodebuild test -scheme {{scheme}} -destination 'platform=macOS' -only-testing CakeWatchTests

# Clean build artifacts
clean:
    rm -rf "{{build_dir}}"
    xcodebuild clean -scheme {{scheme}}

# Open project in Xcode
xcode:
    open CakeWatch.xcodeproj

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
