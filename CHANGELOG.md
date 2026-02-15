# Changelog

## Unreleased

### Added
- Create new uptime checks via toolbar "+" button with `CreateCheckView` sheet
- Pause/resume checks directly from the detail toolbar
- Inline editing for advanced fields (find string, host, port, user agent, basic auth, status codes)
- Toggles for follow redirects, SSL alert, do not find, include header, and cookie jar
- Additional model fields (`includeHeader`, `useJar`, `basicUsername`, `basicPassword`, `customHeader`, `postBody`, `postRaw`, `finalEndpoint`, `dnsIps`, `dnsServer`, `statusCodesCsv`, `contactGroups`, `regions`)
- `FlowLayout` for displaying status code chips
- `testTypeOptions` constant for check creation
- Justfile `build` command now supports `--dev` (fast incremental builds) and `--open` flags
- Statistics tab on check detail panel with response time chart (Swift Charts) and alerts table
- "View on StatusCake" link in Statistics tab
- Tab selection (Details/Statistics) persists when switching between checks
- `.gitignore` for Xcode, macOS, and local config files
- `Local.xcconfig` for per-developer signing team configuration
- `Local.xcconfig.example` for easy onboarding

### Changed
- Detail view tab navigation replaced with segmented `Picker` in toolbar (instead of `TabView`)
- Default detail tab changed to "statistics"
- Search field moved to sidebar placement
- URL field in detail view is now a clickable link
- `StatisticsView` now receives `checkName`, `websiteUrl`, and `uptime` props
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
