# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhishQS is a hybrid iOS/Node.js project consisting of:
- **iOS App**: Swift/UIKit minimalist app for browsing Phish setlists
- **Server Components**: Vercel-deployed Node.js serverless functions for tour statistics

## Plan and Review

**IMPORTANT**: Reference and follow this process at the beginning of every coding session.

Before you begin any implementation work, write a detailed implementation plan in a file named `claude/tasks/TASK_NAME.md`.

This plan should include:
- A clear, detailed breakdown of the implementation steps
- The reasoning behind your approach
- A list of specific tasks with acceptance criteria
- Identification of any dependencies or prerequisites

Focus on a Minimum Viable Product (MVP) to avoid over-planning. Once the plan is ready, please ask me to review it. **Do not proceed with implementation until I have approved the plan.**

## While Implementing

**IMPORTANT**: Keep the plan updated throughout the implementation process.

As you work:
1. Use the TodoWrite tool to track progress on implementation tasks
2. After completing each task, append a detailed description of the changes you've made to the plan
3. Update the plan if you discover new requirements or need to adjust the approach
4. Mark tasks as completed in your todo list immediately after finishing them

This ensures that progress and next steps are clear and can be easily handed over to other engineers if needed.

## Development Commands

### Server/Node.js Commands
```bash
npm run dev                # Start Vercel development server
npm run generate-stats     # Generate tour statistics JSON data
npm run deploy             # Deploy to Vercel production
```

### iOS Development
- Use Xcode to build and run the iOS app
- iOS target requires iOS 16.0+ and Xcode 15+
- UI tests are located in `Tests/PhishQSUITests/`

## Architecture Overview

### iOS App Structure
The iOS app follows a feature-based architecture with clear separation of concerns:

- **Features/**: Feature modules with view-viewmodel pairs
  - `Dashboard/`: Main dashboard with latest show cards
  - `Setlist/`: Setlist display with detailed track views
  - `MonthSelection/`, `DaySelection/`, `YearSelection/`: Navigation hierarchy
  - `TourDashboard/`: Tour-specific statistics view
  - `LatestSetlist/`: Latest show information

- **Services/**: Core business logic and API clients
  - `APIManager.swift`: Central coordinator between different API services
  - `Core/`: Shared services including:
    - `TourConfig.swift`: Centralized tour configuration (eliminates hardcoded values)
    - `SetlistMatchingService.swift`: Shared position-based data matching utilities
    - `CacheManager.swift`: Data persistence and cache invalidation
    - `TourStatisticsService.swift`: Core tour statistics calculations
    - `HistoricalGapCalculator.swift`: Song gap calculations
  - `PhishNet/`: Phish.net API client and tour services
  - `PhishIn/`: Phish.in API client (audio data only)

- **Models/**: Data models for shows, setlists, and tour statistics

- **Utilities/**: Helper functions and extensions

### Server Structure
Node.js serverless functions follow iOS architectural patterns:

- **Server/API/**: Vercel serverless function endpoints
  - `tour-statistics.js`: Main API endpoint serving pre-computed tour data

- **Server/Services/**: Business logic services (mirrors iOS Services pattern)
  - `TourStatisticsService.js`: Core tour statistics calculations
  - `PhishNetTourService.js`: Phish.net tour data operations
  - `TourScheduleService.js`: Complete tour schedule management
  - `EnhancedSetlistService.js`: Multi-API setlist data coordination
  - `StatisticsRegistry.js`: Modular calculator registry for extensible statistics
  - `StatisticsCalculators/`: Individual calculator modules (longest songs, rarest songs, etc.)

- **Server/Models/**: Data models matching iOS model structure
  - `TourStatistics.js`: Tour statistics model definitions

- **Server/Scripts/**: Data generation and maintenance scripts
  - `generate-stats.js`: Creates tour statistics JSON from API data

- **Server/Data/**: Generated JSON data files served by APIs
  - `tour-stats.json`: Pre-computed tour statistics
  - `tour-schedules.json`: Complete tour schedule data for accurate position calculations

## Key Design Patterns

### Multi-API Strategy
The app uses a hybrid approach combining two specialized APIs to provide comprehensive tour data:

**Phish.net API** (Primary tour and setlist authority):
- Shows by year and setlist data
- Song gap calculations (shows since last played)
- Venue names, cities, states that match setlist context
- Transition marks between songs (→, >, etc.)
- **Tour organization and show counts** (complete schedules including future shows)
- **Venue runs calculation** (N1/N2/N3 multi-night indicators)
- Official authoritative Phish database

**Phish.in API** (Audio enhancement only - RESTRICTED USAGE):
- **Song durations ONLY** (their unique strength)
- Audio recording links
- **Usage Restriction**: Only used for audio timing data, NOT for tour organization

**Why both APIs are required**:
- Phish.net provides complete tour structure but lacks song duration data
- Phish.in provides song durations but lacks gap calculations and complete tour schedules
- **Migration Result**: Phish.net is now the tour authority; Phish.in is limited to audio enhancement only

### Caching Strategy
- `CacheManager.swift` handles data persistence and cache invalidation
- Server responses include cache headers (`s-maxage=3600`)

### Tour Statistics Business Logic
Core tour statistics are calculated using specific algorithms and update rules:

**Top 3 Longest Songs**:
- Ranked by duration (longest first)
- Updates during active tour: new songs replace shortest of current top 3 if longer
- Displays: song name, duration, show date, venue name
- Data source: Song durations from Phish.in API

**Top 3 Rarest Songs (Biggest Gaps)**:
- Ranked by gap size (shows since last played before current tour)
- Updates during active tour: new songs replace lowest gap if higher
- Displays: song name, gap number, tour show date/venue, last played date
- Data source: Gap calculations from Phish.net API

**Tour Transition Logic**:
- Tour determined by which tour the latest setlist belongs to
- Between tours: continue showing stats from most recently completed tour
- New tour: statistics reset and begin tracking new tour automatically
- Latest setlist always shows most recent Phish concert

**Performance Strategy**:
- Server pre-computes all statistics to avoid slow real-time calculation (~140ms vs 60+ seconds)
- Statistics stored in `Server/Data/tour-stats.json`
- **API Optimization**: 97% improvement using `/v5/shows/showyear/` endpoint (44 responses vs 1,437)
- **Tour Position Accuracy**: Now shows correct totals (e.g., "Show 23/31" vs "Show 23/23")
- `TourStatisticsService` handles complex calculations including gap analysis
- `StatisticsRegistry` enables modular calculator architecture

## API Configuration

### Server Environment
- Node.js 18+ required
- Uses ES modules (`"type": "module"` in package.json)
- Vercel configuration in `vercel.json` with CORS headers

### API Endpoints
- `/api/tour-statistics`: Returns pre-computed tour statistics

### API Keys and Configuration
- **Phish.net API**: Requires API key for statistics generation (configured in generate-stats.js)
- **Phish.in API**: No API key required
- API keys should be configured as environment variables for production deployment

## Critical API Rules

### Venue-Date Consistency Rule
**CRITICAL**: If you display a date, the corresponding venue MUST come from the same API source.

**Why this matters**:
- Show date from Phish.net + venue name from Phish.in = potentially different venue names
- This creates data inconsistencies and user confusion
- Each API may format venue names differently for the same physical location

**Implementation**:
- Use Phish.net as the setlist authority (dates, venues, song order)
- Enhance with Phish.in data (durations, tour structure) but maintain venue-date pairing
- Validate venue-date matching when combining API responses
- Never mix venue names from different APIs for the same show

## Data Flow

### Tour Statistics Pipeline
1. **Multi-API Data Collection**:
   - **Primary**: Fetch show dates, setlists, and tour organization from Phish.net API
   - **Enhancement**: Fetch song durations from Phish.in API (audio data only)
   - **Tour Context**: Use TourScheduleService for complete tour schedules and accurate positions
   - Apply venue-date consistency rules during data combination

2. **Statistics Calculation**:
   - `TourStatisticsService` processes all tour shows
   - Calculate top 3 longest songs using Phish.in duration data
   - Calculate top 3 rarest songs using Phish.net gap data
   - Apply tour transition logic for current vs completed tours

3. **Pre-computation and Storage**:
   - `npm run generate-stats` creates tour data JSON
   - Statistics stored in `Server/Data/tour-stats.json`
   - Eliminates real-time calculation delays

4. **API Serving**: 
   - Vercel functions serve pre-computed data via `/api/tour-statistics`
   - Cache headers set for performance (`s-maxage=3600`)

5. **iOS Consumption**: 
   - App fetches data via `APIManager` and caches locally via `CacheManager`
   - ViewModels update SwiftUI views with fetched data
   - Tour dashboard displays statistics instantly (no calculation wait)

## Testing
- iOS UI tests in `Tests/PhishQSUITests/`
- No server-side tests currently implemented
- Mock implementations available for API clients

## Development Best Practices

### Tour-Related Functionality
- **Use TourConfig** for any new tour-related functionality instead of hardcoding values
- **Update TourConfig** when tours change (single point of configuration)
- Examples: tour names, show counts, year references

### Data Matching
- **Use SetlistMatchingService** for any position-based data matching between APIs
- Handles duplicate song names correctly using position-based matching with name validation
- Provides duration color calculation and gap information matching utilities

### ViewModel Organization
- **Follow Extension Pattern** for organizing large ViewModels into focused components
- Break ViewModels into extensions by functionality (Navigation, DataProcessing, TourStatistics, Core)
- Example: `LatestSetlistViewModel+Navigation.swift`, `LatestSetlistViewModel+TourStatistics.swift`

### API Usage Restrictions
- **Maintain Phish.in Restrictions**: Keep Phish.in usage limited to audio data only (durations, recordings)
- **Use Phish.net for Tour Data**: All tour organization, show counts, venue runs come from Phish.net
- **Respect Venue-Date Consistency Rule**: If displaying a date, corresponding venue must come from same API source

### Configuration Management
- Use centralized services instead of hardcoded values throughout the codebase
- Leverage the modular calculator architecture for adding new statistics types
- Follow the established service layer patterns for API coordination

## Deployment
- Server: Deployed to Vercel via `npm run deploy`
- iOS: Standard Xcode build and distribution process
- Statistics data regenerated via GitHub Actions or manual script execution