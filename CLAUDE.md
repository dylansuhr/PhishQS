# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhishQS (Phish Quick Setlist) is a minimalist iOS app built with SwiftUI that allows users to quickly browse Phish setlists by year, month, and day using the Phish.net API. The app follows a hierarchical navigation pattern: Year → Month → Day → Setlist, with a focus on speed and minimal taps.

## Build and Test Commands

This is a standard Xcode iOS project. Use these commands:

- **Build** (default - build-only, no simulator): `xcodebuild -project PhishQS.xcodeproj -scheme PhishQS -destination 'generic/platform=iOS' build`
- **Build** (with xcbeautify if installed): `xcodebuild -project PhishQS.xcodeproj -scheme PhishQS -destination 'generic/platform=iOS' build | xcbeautify --quiet`
- **Build** (alternative): Open `PhishQS.xcodeproj` in Xcode and use Cmd+B
- **Run Tests**: Use Cmd+U in Xcode, or `xcodebuild test -scheme PhishQS -destination 'platform=iOS Simulator,name=iPhone 15'`
- **Run App**: Use Cmd+R in Xcode or build and run on simulator/device

**Note**: Default to build-only command for compilation checks. Use physical device for testing due to Cloudflare networking issues in simulator.

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

## Feature Roadmap

### High Priority
- [ ] Add link to stream show on LivePhish app
- [ ] Add Phish.net link so user can get more information on the show
- [ ] Add future tour dates button on home screen and pull future tour date data
- [ ] Add day of the week to each show (Monday, Tuesday, etc.)
- [ ] For month view, add month names (January, February) in addition to numbers for easy reading
- [ ] When user is not on latest setlist card, add "Return to Latest" button for quick navigation
- [ ] Remove all loading animations throughout the app for cleaner, more professional appearance

### Medium Priority
- [ ] For venue "runs" (same venue multiple nights), show N1/3, N2/3, N3/3 format
- [ ] Indicate show number in tour (e.g., "Summer Tour 2025 15/23")
- [ ] Implement categorization of shows by tour within year/month/day (maintain efficiency)
- [ ] Build functionality to pull data from Phish.in API and research available information
- [ ] Access song lengths for each song in a show
- [ ] Implement color scale for song lengths (green=shortest, red=longest, gradient between)
- [ ] Consider removing year list from home screen, replace with button leading to dedicated full-page year view

### Long Term Goals
- [ ] OCR feature: Take photo of any date, read date from image, open that show
- [ ] Notes section for each show with sharing capability
- [ ] Collaborative notes with friends and notifications ("listen to this Tweezer - it's fire!")

## Multi-API Architecture Plan

### Overview
Modular architecture to integrate multiple Phish data sources while maintaining clean separation of concerns and easy extensibility.

### API Priority Strategy
1. **Phish.net** - Primary source for setlist data (current implementation)
2. **Phish.in** - Song lengths, tour metadata, venue run information

### Directory Structure
```
/Services/
├── PhishNet/          # Phish.net API client (primary setlist source)
├── PhishIn/           # Phish.in API client (song lengths, tours, venue runs)
├── Core/              # Shared protocols, errors, utilities
└── APIManager.swift   # Central coordinator between all APIs
```

### Data Strategy
- **Phish.net**: Master setlist data (maintain current approach as single source of truth)
- **Phish.in**: Supplement with song durations, tour metadata, N1/N2/N3 venue run info

### Implementation Phases
**Phase 1: Foundation Restructure**
1. Create Services directory structure  
2. Move existing PhishAPIClient to Services/PhishNet/
3. Create core protocols and shared utilities
4. Update imports throughout app

**Phase 2: Phish.in Integration**
1. Implement Phish.in client focusing on tracks/tours endpoints
2. Create models for song durations and tour metadata
3. Test data integration without UI changes

**Phase 3: Central Coordination**
1. Build APIManager to coordinate between APIs
2. Update ViewModels to use new APIManager

### Benefits
- Provides song length and tour data from Phish.in
- Maintains Phish.net as setlist authority
- Modular design for easy future API additions
- Clean separation of concerns

## Session Progress Summary

### **Phase 1 Complete: Foundation Restructure** ✅
- [x] Created Services directory structure with proper organization
- [x] Moved PhishAPIClient to Services/PhishNet/ (renamed from PhishNetAPIClient for compatibility)
- [x] Created core protocols and shared utilities in Services/Core/
- [x] Built central APIManager coordinator
- [x] Updated all imports throughout app to use new structure
- [x] Fixed Xcode project file references (resolved "Servies" typo)
- [x] Moved MockPhishAPIClient to test-only target (Tests/PhishQSTests/Mocks/)
- [x] Verified main app builds successfully

### **Session Complete ✅ - Multi-API Architecture Phases 2 & 3**

**Date**: July 25, 2025
**Status**: Phase 2 & 3 of Multi-API Architecture complete, ready for Phase 4

### **Latest Session Accomplishments ✅**
- [x] **Phase 2 Complete**: Phish.in API Integration
  - Full PhishIn API client implementation with song durations, tour metadata, venue runs (N1/N2/N3)
  - Comprehensive models with conversion utilities between API formats
  - Complete mock implementation for testing
  - Protocol-compliant error handling and async/await support
- [x] **Phase 3 Complete**: Central API Coordination
  - Enhanced APIManager with multi-API coordination
  - `fetchEnhancedSetlist()` combines Phish.net setlists with Phish.in song durations and venue runs
  - Graceful fallback when Phish.in is unavailable
  - New `EnhancedSetlist` model for combined data
- [x] **Architecture Foundation**: Clean, extensible multi-API design
- [x] **Build Verification**: All code compiles successfully

### **Current Architecture ✅**
```
/Services/
├── PhishNet/          # Phish.net API client (primary setlist source) ✅
├── PhishIn/           # Phish.in API client (song lengths, tours, venue runs) ✅  
├── Core/              # Shared protocols, errors, utilities ✅
└── APIManager.swift   # Central coordinator between APIs ✅
```

### **Session Complete ✅ - Song Duration Display Implementation**

**Date**: August 21, 2025
**Status**: Song duration display fully functional with Phish.in v2 API

### **Latest Session Accomplishments ✅**
- [x] **Phish.in v2 API**: Updated to use Phish.in API v2 - no authentication required
- [x] **Song Duration Display**: Complete implementation with individual song line-by-line display (matching LivePhish format)
- [x] **UI Components**: Created `DetailedSetlistLineView` for song + duration display with right-aligned times
- [x] **Song Parsing**: Built `SongParser` utility for extracting individual songs from combined setlist lines  
- [x] **Enhanced Data Integration**: ViewModels now use `APIManager.fetchEnhancedSetlist()` for combined data
- [x] **API Authentication**: Phish.in v2 requires no API key - fully functional
- [x] **Error Handling**: Proper fallback messaging when enhanced data unavailable
- [x] **Debug Infrastructure**: Added comprehensive logging for API troubleshooting

### **Current Architecture Status ✅**
```
/Services/
├── PhishNet/          # Phish.net API client (primary setlist source) ✅
├── PhishIn/           # Phish.in API client v2 (song lengths, tours, venue runs) ✅  
├── Core/              # Shared protocols, errors, utilities ✅
└── APIManager.swift   # Central coordinator between APIs ✅

/Features/Setlist/
├── SetlistView.swift           # Individual song display with durations ✅
├── SetlistViewModel.swift      # Enhanced data integration ✅
└── DetailedSetlistLineView.swift # Song + duration component ✅

/Utilities/
└── SongParser.swift            # Song extraction utility ✅
```

### **Key Implementation Details**
- **Individual Song Display**: SetlistView now shows songs line-by-line with right-aligned durations (like LivePhish)
- **Data Pipeline**: PhishNet provides setlists → PhishIn v2 provides song durations → Combined in EnhancedSetlist
- **API v2 Benefits**: No authentication required, full song duration data available
- **User Feedback**: Clear messaging when song durations unavailable (should be rare now)

### **Research Findings - API Relationship**
- **Phish.net**: Primary setlist and metadata source (API v5) - authoritative database
- **Phish.in**: Audio recording archive with timing data (API v2) - complementary enhancement
- **Data Flow**: Services complement rather than duplicate - our multi-API architecture is correctly designed
- **API Authentication**: Phish.in v2 requires no authentication; Phish.net uses existing key

### **Ready for Next Session:**
1. **Color Scale Implementation**: Implement color coding for song lengths in SetlistView
2. **Venue Run Display**: Show N1/N2/N3 information in UI using existing VenueRun data
3. **Recording Links**: Add links to available recordings where applicable
4. **Performance Optimization**: Consider caching strategies for enhanced setlist data

### **Immediate Action Items 🚨**
1. **AccentColor Warning**: Add AccentColor to Assets.xcassets or remove reference  
2. **Test Target Fix**: Add `Show.swift` and `SetlistItem.swift` to test target in Xcode

### **Technical Debt Items**
- Mock client helper methods have placeholder implementations (low priority)
- Could benefit from more comprehensive edge case testing
- Documentation could be enhanced for complex API coordination logic

### **Code Quality**: Production-ready, well-architected, comprehensive error handling ✅

### Completed ✅
- [x] Fix LatestSetlistView swipe animations (horizontal-only movement, proper slide transitions)
- [x] Multi-API Architecture Phase 1: Foundation Restructure
- [x] Multi-API Architecture Phase 2: Phish.in Integration  
- [x] Multi-API Architecture Phase 3: Central Coordination
- [x] **Phase 4: Song Duration Display Implementation**
