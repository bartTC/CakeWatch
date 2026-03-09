# Changelog

## Unreleased
- Demo mode with sample uptime check data for testing and screenshots
- Simulator device selection (iPhone/iPad) with demo mode status bar overrides
- Privacy policy documenting data handling practices
- App Store metadata, review notes, and asset organization
- Accounts-changed notification to auto-reload checks
- Build configuration and bundle identifier updates

## 1.0.0

### Added
- Multi-account support for managing multiple StatusCake API keys
- Create new uptime checks via toolbar "+" button with `CreateCheckView` sheet
- Pause/resume checks directly from the detail toolbar
- Inline editing for advanced fields (find string, host, port, user agent, basic auth, status codes)
- Toggles for follow redirects, SSL alert, do not find, include header, and cookie jar
- Statistics tab with response time chart (Swift Charts) and alerts table
- Downtime timeline with grouped sections, relative dates, and timezone support
- macOS menu bar commands and keyboard shortcuts (Cmd+N, Cmd+R, Cmd+Delete)
- `FlowLayout` for displaying status code chips
- `Local.xcconfig` for per-developer signing team configuration

### Changed
- Renamed app from StatusBake to CakeWatch
- Platform-specific views split into separate files (macOS and iOS)
- iOS uses navigation-push editors with auto-save; macOS uses inline editing
- Detail view tab navigation replaced with segmented picker in toolbar
- Search field moved to sidebar placement
- URL field in detail view is now a clickable link
- Settings window: separated API key and preferences into distinct sections
- Downtime timeline switched from history API to periods API with pagination
- New app icon

## 0.1.0

### Added
- Initial release
- List, inspect, and edit StatusCake uptime checks
- Batch edit and delete multiple checks
- API rate limiting with configurable requests/second
- Settings panel with API key configuration and connection test
