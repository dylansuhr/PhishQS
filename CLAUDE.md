# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhishQS is a hybrid iOS/Node.js project consisting of:
- **iOS App**: Swift/UIKit minimalist app for browsing Phish setlists
- **Server Components**: Vercel-deployed Node.js serverless functions for tour statistics

## Plan and Review

Before you begin, write a detailed implementation plan in a file named claude/tasks/TASK_NAME.md.

This plan should include:

A clear, detailed breakdown of the implementation steps.

The reasoning behind your approach.

A list of specific tasks.

Focus on a Minimum Viable Product (MVP) to avoid over-planning. Once the plan is ready, please ask me to review it. Do not proceed with implementation until I have approved the plan.

## While Implementing

As you work, keep the plan updated. After you complete a task, append a detailed description of the changes you've made to the plan. This ensures that the progress and next steps are clear and can be easily handed over to other engineers if needed.

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
  - `Core/`: Shared services including caching, tour statistics, and API protocols
  - `PhishNet/`, `PhishIn/`: API client implementations

- **Models/**: Data models for shows, setlists, and tour statistics

- **Utilities/**: Helper functions and extensions

### Server Structure
Node.js serverless functions follow iOS architectural patterns:

- **Server/API/**: Vercel serverless function endpoints
  - `tour-statistics.js`: Main API endpoint serving pre-computed tour data

- **Server/Services/**: Business logic services (mirrors iOS Services pattern)
  - `TourStatisticsService.js`: Core tour statistics calculations

- **Server/Models/**: Data models matching iOS model structure
  - `TourStatistics.js`: Tour statistics model definitions

- **Server/Scripts/**: Data generation and maintenance scripts
  - `generate-stats.js`: Creates tour statistics JSON from API data

- **Server/Data/**: Generated JSON data files served by APIs

## Key Design Patterns

### Multi-API Strategy
The app uses a hybrid approach combining two specialized APIs to provide comprehensive tour data:

**Phish.net API** (Primary setlist source):
- Shows by year and setlist data
- Song gap calculations (shows since last played)
- Venue names, cities, states that match setlist context
- Transition marks between songs (→, >, etc.)
- Official authoritative Phish database

**Phish.in API** (Audio and performance enhancement):
- Song durations (only available source)
- Tour organization and naming
- Venue runs calculation (N1/N2/N3 multi-night indicators)
- Audio recording links

**Why both APIs are required**:
- Neither API alone provides complete data needed for tour statistics
- Phish.net has no duration data; Phish.in has no gap data
- Each API specializes in different aspects of show information

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
- Server pre-computes all statistics to avoid slow real-time calculation
- Statistics stored in `Server/Data/tour-stats.json`
- `TourStatisticsService` handles complex calculations including gap analysis
- `HistoricalGapCalculator` manages song gap calculations

## API Configuration

### Server Environment
- Node.js 18+ required
- Uses ES modules (`"type": "module"` in package.json)
- Vercel configuration in `vercel.json` with CORS headers

### API Endpoints
- `/api/tour-statistics`: Returns pre-computed tour statistics
- Requires API keys for Phish.net and Phish.in (configured in generate-stats.js)

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
   - Fetch show dates and setlists from Phish.net API
   - Fetch song durations and tour metadata from Phish.in API
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

## Deployment
- Server: Deployed to Vercel via `npm run deploy`
- iOS: Standard Xcode build and distribution process
- Statistics data regenerated via GitHub Actions or manual script execution