# StatusBake

A native macOS app for managing and monitoring your [StatusCake](https://www.statuscake.com/) uptime checks.

## Features

- View all uptime checks with status, name, and uptime percentage
- Inspect and edit check configuration (check rate, timeout, trigger rate, etc.)
- Batch edit and delete multiple checks at once
- Response time charts and downtime alerts per check
- Built-in API rate limiting with configurable requests/second

## Requirements

- macOS 26.2+
- Xcode 26.2+
- A [StatusCake](https://www.statuscake.com/) account and API key

## Setup

1. Clone the repository
2. Copy the example config and add your Apple Developer Team ID:
   ```
   cp Local.xcconfig.example Local.xcconfig
   ```
   Edit `Local.xcconfig` and replace `YOUR_TEAM_ID` with your actual team ID.
3. Open `StatusBake.xcodeproj` in Xcode
4. Build and run

On first launch, you'll be prompted to enter your StatusCake API key in Settings.

## Architecture

The app follows an MVVM pattern:

- **Models** — `UptimeCheck`, `UptimeHistory` (API response types)
- **Views** — `ContentView`, `CheckDetailView`, `StatisticsView`, `BatchConfigView`, `SettingsView`
- **ViewModels** — `UptimeViewModel` (state management and API orchestration)
- **Services** — `StatusCakeAPI` (HTTP client with retry and rate limiting)

## License

MIT
