# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhishQS (Phish Quick Setlist) is a minimalist iOS app built with SwiftUI that allows users to quickly browse Phish setlists by year, month, and day using the Phish.net API. The app follows a hierarchical navigation pattern: Year → Month → Day → Setlist, with a focus on speed and minimal taps.

## Build and Test Commands

This is a standard Xcode iOS project. Use these commands:

- **Build**: Open `PhishQS.xcodeproj` in Xcode and use Cmd+B, or use `xcodebuild` from command line
- **Run Tests**: Use Cmd+U in Xcode, or `xcodebuild test -scheme PhishQS -destination 'platform=iOS Simulator,name=iPhone 15'`
- **Run App**: Use Cmd+R in Xcode or build and run on simulator/device

The project uses the new Swift Testing framework (not XCTest), so test files use `@Test` annotations instead of `XCTestCase`.

## Architecture and Code Organization

### Project Structure
- **Features/**: Organized by screen/feature with View and ViewModel pairs
  - `YearSelection/`: Starting screen showing years 1983-2025 (excluding hiatus years 2005-2007)
  - `MonthSelection/`: Shows months with shows for selected year
  - `DaySelection/`: Shows days with shows for selected month
  - `Setlist/`: Displays the actual setlist for selected show
  - `LatestSetlist/`: Shows the most recent show at top of year list
- **Models/**: Data models (`Show`, `SetlistItem`, response wrappers)
- **Utilities/**: API client and mock implementations
- **Resources/**: Contains `Secrets.plist` for API keys
- **Tests/**: Unit tests using Swift Testing framework

### Key Architecture Patterns

1. **MVVM Pattern**: Each view has a corresponding ViewModel extending `BaseViewModel`
2. **Dependency Injection**: ViewModels accept `PhishAPIService` protocol for testability
3. **Async/Await**: Modern Swift concurrency throughout the API layer
4. **Protocol-Oriented**: `PhishAPIService` protocol with real and mock implementations
5. **NavigationStack**: Uses SwiftUI NavigationStack for hierarchical navigation
6. **Shared Utilities**: Common functionality extracted into reusable utilities

### API Client Design
- `PhishAPIClient` singleton for production API calls
- `MockPhishAPIClient` for testing with simulated delays and error scenarios
- Comprehensive error handling with `APIError` enum
- All network calls use async/await with proper error propagation

### Shared Utilities Architecture
- **`BaseViewModel`**: Common ViewModel functionality (loading states, error handling)
- **`DateUtilities`**: Date parsing, formatting, and extraction functions
- **`APIUtilities`**: Phish show filtering and data processing
- **`StringFormatters`**: Consistent string formatting for setlists and titles

### Data Flow
1. User starts at `YearListView` (shows hardcoded years 1983-2025)
2. Each level fetches data from Phish.net API to populate the next level
3. ViewModels use shared utilities for data transformation
4. Views display loading states, errors, and retry functionality consistently
5. Views use NavigationLink for push-style navigation between levels

### Key Implementation Details
- Years 2005-2007 are filtered out (Phish hiatus period)
- Latest setlist appears at top of year list for quick access
- All ViewModels inherit from `BaseViewModel` for consistent error/loading handling
- All Views display loading spinners and error messages with retry buttons
- Date parsing and formatting handled by shared utilities
- No code duplication between ViewModels

## Known Issues

### iOS Simulator + Cloudflare Networking
- **Issue**: The Phish.net API (hosted on Cloudflare) fails in iOS Simulator with IPv6/QUIC protocol errors
- **Symptoms**: Timeouts, "connection lost", "cannot parse response" errors
- **Root Cause**: iOS Simulator has known compatibility issues with Cloudflare's modern networking (HTTP/3, QUIC, IPv6)
- **Solution**: Use physical iOS device for development and testing
- **Workarounds**: Not implemented in production code (debug files were removed for cleanliness)

### Testing Strategy
- **Physical Device**: Full functionality including API calls
- **Simulator**: Use MockPhishAPIClient for UI testing when network calls fail
- **Unit Tests**: Run on both simulator (with mocks) and device (with real API)
