# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

StatusBake is a native SwiftUI app for managing StatusCake uptime monitoring checks, targeting both macOS and iOS from a single codebase. No third-party dependencies — pure Swift/SwiftUI/Foundation.

## Build Commands

Uses `just` (Justfile) wrapping `xcodebuild`. Requires `Local.xcconfig` with `DEVELOPMENT_TEAM` set (see `Local.xcconfig.example`).

- `just build` — build and run macOS app
- `just build --ios` — build and run on iOS simulator
- `just build --device` — build and install on connected iPhone
- `just build --dev` — faster incremental macOS build (uses `build/DerivedData`)
- `just clean` — clean build artifacts
- `just xcode` — open in Xcode
- `just release` — archive + notarize macOS build
- `just dmg` — create DMG installer
- `just release-appstore` — archive for App Store

## Architecture

**MVVM with @Observable**: `UptimeViewModel` holds all app state. `StatusCakeAPI` (singleton) handles HTTP. No dependency injection — views create their own view model with `@State`.

### Platform Split Pattern

Never mix iOS and macOS view code in the same file. Every non-trivial view is split into three files:
- `FooView.swift` — shared state, `@ViewBuilder` sections, helpers (all `internal` access)
- `FooView_macOS.swift` — `#if os(macOS)` extension providing `body` and macOS-specific properties
- `FooView_iOS.swift` — `#if os(iOS)` extension providing `body` and iOS-specific behavior

Use `#if os()` only for tiny things (single modifiers, state declarations). Substantial platform logic **must** go in the platform-specific file. When creating new views, always create separate iOS and macOS files rather than using conditional compilation in a single file.

Views following this pattern: `ContentView`, `CheckDetailView`, `CreateCheckView`, `SettingsView`.

### iOS vs macOS Editing

- **iOS**: Navigation-push editors (`EditFieldView`/`EditChipsView`) with auto-save on `.onDisappear`
- **macOS**: Inline double-tap editing

### macOS Menu Bar

`StatusBakeApp.swift` defines `AppCommands` using `FocusedValues` to wire keyboard shortcuts (Cmd+N, Cmd+R, Cmd+Delete) to view actions.

## Data Flow

1. `loadAccounts()` reads from UserDefaults (supports multi-account, auto-migrates legacy single key)
2. `fetchChecks()` iterates accounts, calls API, tags checks with account info
3. Selection triggers `fetchDetail()` (single) or `fetchSelectedDetails()` (multi, sequential with progress)
4. `fetchStatistics()` fetches history + downtime periods in parallel (`async let`), periods support pagination
5. Writes (`updateField`/`batchUpdate`/`createCheck`/`deleteSelected`) call API then re-fetch

## API Layer

- Base: `https://api.statuscake.com/v1`, Bearer token auth
- Rate limiting: configurable rps (default 4), 429 retry with `x-ratelimit-reset` backoff (max 3 retries)
- PUT/POST use `application/x-www-form-urlencoded`
- JSON decoding: `.convertFromSnakeCase`, custom ISO8601 date decoder with fractional seconds support

## Key Directories

- `StatusBake/Models/` — data models (`UptimeCheck`, `Account`, `UptimeHistory`, `Constants`)
- `StatusBake/ViewModels/` — `UptimeViewModel` (single view model for entire app)
- `StatusBake/Services/` — `StatusCakeAPI` REST client
- `StatusBake/Views/` — all SwiftUI views (platform-split pattern)
- `scripts/` — release/archive shell scripts
