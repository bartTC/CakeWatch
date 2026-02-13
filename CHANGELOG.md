# Changelog

## Unreleased

### Added
- Statistics tab on check detail panel with response time chart (Swift Charts) and alerts table
- "View on StatusCake" link in Statistics tab
- Tab selection (Details/Statistics) persists when switching between checks
- `.gitignore` for Xcode, macOS, and local config files
- `Local.xcconfig` for per-developer signing team configuration
- `Local.xcconfig.example` for easy onboarding

### Changed
- Settings window: separated API key and preferences into distinct sections
- Settings window: moved Done button from toolbar to bottom of sheet
- Settings window: renamed "Save & Test" to "Test Connection"
- Removed hardcoded `DEVELOPMENT_TEAM` from project file

## 0.1.0

### Added
- Initial release
- List, inspect, and edit StatusCake uptime checks
- Batch edit and delete multiple checks
- API rate limiting with configurable requests/second
- Settings panel with API key configuration and connection test
