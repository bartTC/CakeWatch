scheme := "StatusBake"
config := "Release"
archive_path := "build/StatusBake.xcarchive"
export_path := "build"

# Build the app (debug)
build:
    xcodebuild build -scheme {{scheme}} -destination 'platform=macOS'

# Create a release archive and export the .app
archive:
    rm -rf {{archive_path}} {{export_path}}/StatusBake.app
    xcodebuild archive \
        -scheme {{scheme}} \
        -configuration {{config}} \
        -archivePath {{archive_path}} \
        -destination 'platform=macOS'
    xcodebuild -exportArchive \
        -archivePath {{archive_path}} \
        -exportPath {{export_path}} \
        -exportOptionsPlist ExportOptions.plist
    @echo "Exported to {{export_path}}/StatusBake.app"

# Clean build artifacts
clean:
    rm -rf build/
    xcodebuild clean -scheme {{scheme}}
