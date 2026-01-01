# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhishQS is a hybrid iOS/Node.js project with four distinct functional components:

**iOS App Components:**
1. **Tour Setlist Browser (Component A)**: Display of the latest Phish show setlist with color-coded song durations and venue context
2. **Tour Statistics Display (Component B)**: Pre-computed statistical cards showing longest/rarest/most-played songs from current tour
3. **Historical Show Search (Component C)**: Date-driven search and display of any historical Phish show (1983-present)
4. **Tour Calendar (Component D)**: Interactive calendar view showing tour dates across multiple months with venue badges

**Server Components:**
- **Vercel-deployed Node.js serverless functions**: Serve pre-computed data via multiple endpoints
  - `/api/tour-statistics` - Pre-computed tour statistics for Component B
  - `/api/tour-dashboard` - Tour control data for Component A navigation
  - `/api/shows/[date]` - Individual show data for Component A display
- **Single source of truth data generation**: Handle data aggregation from Phish.net and Phish.in APIs during build time

## Current Status

**Single Source Architecture**: All data pre-computed on server, fetched by iOS app (~140ms response times).

**API Endpoints**:
- `/api/tour-dashboard` - Tour control data
- `/api/shows/[date]` - Individual show data
- `/api/tour-statistics` - Pre-computed statistics

**Automated Updates**: GitHub Actions runs 3x daily to update tour data, auto-deployed via Vercel.

## Development Workflow

**Plan First**: Before implementing features, create a brief plan outlining your approach and key tasks.

**Track Progress**: Use the TodoWrite tool for complex multi-step tasks to maintain visibility.

**Stay Focused**: Complete one task at a time, marking items done as you progress.

## Development Commands

### Server/Node.js Commands
```bash
npm run dev                        # Start Vercel development server
npm run generate-stats             # Generate tour statistics JSON data
npm run update-tour-dashboard      # Update tour dashboard data
npm run initialize-tour-shows      # Initialize all tour shows data
npm run initialize-remaining-shows # Quick initialize remaining shows
npm run deploy                     # Deploy to Vercel production

# Development workflow
vercel dev                         # Alternative way to start dev server
node Server/Scripts/generate-stats.js  # Direct script execution
```

### iOS Development
```bash
# Build and run in Xcode
open PhishQS.xcodeproj             # Open project in Xcode
# Press Cmd+R to build and run
# Press Cmd+U to run tests

# Build from command line (optional)
xcodebuild -scheme PhishQS -configuration Debug -sdk iphonesimulator build
xcodebuild -scheme PhishQS test

# Common development tasks
xcodebuild -list                   # List available schemes and targets
xcodebuild clean                   # Clean build artifacts
```

**Requirements:**
- iOS target requires iOS 17.0+ and Xcode 15+
- UI tests are located in `Tests/PhishQSUITests/`
- Test files: `PhishQSTests` and `PhishQSUITests` targets
- Node.js 18+ required for server components

## App Components

**Component A: Tour Setlist Browser**
- Latest show setlist with color-coded durations
- Venue run badges (N1/N2/N3) and tour position
- Files: `Features/LatestSetlist/`

**Component B: Tour Statistics Display**
- Pre-computed cards: Longest, Rarest, Most Played songs
- Server-generated via `/api/tour-statistics`
- Files: `Features/Dashboard/TourMetricCards.swift`

**Component C: Historical Show Search**
- Year → Month → Day navigation
- Real-time API calls for historical shows
- Files: `Features/YearSelection/`, `Features/Setlist/`

**Component D: Tour Calendar**
- SwiftUI calendar with tour dates
- Multi-night venue badges, tour colors
- Files: `Features/Calendar/`

## Architecture Overview

### iOS App
- **Features/**: UI components organized by feature
- **Services/**: API clients and business logic
- **Models/**: Shared data structures
- **Utilities/**: Helper functions

### Server (Node.js)
- **Server/API/**: Vercel endpoints
- **Server/Services/**: Business logic
- **Server/Scripts/**: Data generation
- **Server/Data/**: Pre-computed JSON files

### Key Services
- `APIManager`: Coordinates Phish.net/Phish.in APIs
- `CacheManager`: Local data caching
- `TourConfig`: Centralized configuration
- `TourStatisticsAPIClient`: Fetches pre-computed stats

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

### Tour Statistics Logic

**Statistics Types**:
- **Longest Songs**: By duration from Phish.in
- **Rarest Songs**: By gap (shows since last played) from Phish.net
- **Most Played**: By frequency in current tour

**Updates**: Statistics auto-update when new shows are detected (3x daily via GitHub Actions).

**Performance**: Pre-computation reduces response time from 60+ seconds to ~140ms.

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

**Pre-computed Data** (Components A, B):
1. Server fetches from Phish.net/Phish.in APIs
2. Generates JSON files in `Server/Data/`
3. Serves via Vercel endpoints
4. iOS app fetches and caches

**Real-time Data** (Component C):
1. iOS app makes direct API calls
2. Caches individual shows
3. Displays with color gradients when available

## Testing
- iOS UI tests in `Tests/PhishQSUITests/`
- No server-side tests currently implemented
- Mock implementations available for API clients

## Component Development Guidelines

### Component Quick Reference

**A - Tour Setlist Browser**: `Features/LatestSetlist/` - Shows latest setlist with durations
**B - Tour Statistics**: `Features/Dashboard/TourMetricCards.swift` - Pre-computed stats cards
**C - Historical Search**: `Features/YearSelection/` - Year→Month→Day show browser
**D - Tour Calendar**: `Features/Calendar/` - SwiftUI calendar with tour dates

### Component Architecture

**Shared Services**: All components use `APIManager`, `CacheManager`, and shared data models.

**Independence**: Each component (A, B, C, D) can be developed independently with no cross-dependencies.

**Integration**: Components communicate only through shared services, not direct references.

### Development Guidelines

**Key Patterns**:
- Use `TourConfig` for tour-related values (no hardcoding)
- Use `SetlistMatchingService` for API data matching
- Break large ViewModels into extensions by functionality
- Use state-driven UI patterns (no timing-based animations)

**API Rules**:
- Phish.net: Tour structure, setlists, gaps
- Phish.in: Audio data only (durations, recordings)
- Never mix venue names from different APIs for the same show

**UI Consistency**:
- Use `generateConsistentColor()` for dynamic colors
- Red/pink reserved for UI indicators only
- Follow existing component patterns

### Song Filtering Pattern

Filter songs by excluding side projects, not by including only `artist: "Phish"`:

```javascript
const sideProjectArtists = ['Trey Anastasio', 'Mike Gordon', ...];
const phishSongs = allSongs.filter(song =>
    song.times_played > 0 && !sideProjectArtists.includes(song.artist)
);
```

This correctly includes Phish originals + covers (902 songs) while excluding solo projects.

### Data Pipeline Pattern

New data features follow the single source architecture:

1. **Generate**: Pre-compute data via `generate-stats.js`
2. **Store**: Save to `Server/Data/*.json`
3. **Serve**: API endpoints from `/api/*`
4. **Consume**: iOS app fetches pre-computed data

**Key Rule**: No runtime API calls to external services. All data must be pre-computed for ~140ms response times.

### State-Driven UI Pattern

**IMPORTANT**: Use state-driven UI patterns, not timing-based animations. React to data changes rather than arbitrary delays.

```swift
// Good: State-driven
.onChange(of: dataModel.isLoading) { _, isLoading in
    if !isLoading {
        withAnimation { showContent = true }
    }
}

// Bad: Timing-based
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { ... }
```


## Deployment

**Automated**: GitHub Actions runs 3x daily (midnight, 4am, 4pm EDT) to update tour data.

**Manual**:
- Server: `npm run deploy`
- Data refresh: `npm run generate-stats`
- iOS: Standard Xcode deployment

---

## 🚀 Quick Post-Feature Cleanup (5 minutes)

After implementing any feature, take 5 minutes to:

1. **Remove Debug Code**
   - Delete all console.log/SwiftLogger.debug statements
   - Remove commented-out code blocks
   - Clean up any TODO/FIXME comments you added

2. **Check Your Changes**
   - Remove unused imports in files you modified
   - Ensure consistent naming conventions
   - Verify error handling is in place

3. **Run Validation**
   - Execute lint/typecheck commands
   - Test your feature works as expected
   - Review your commits for any temporary code

4. **Follow Project Patterns**
   - Ensure state-driven UI (no timing-based animations)
   - Use existing services and utilities
   - Match the code style of surrounding files

This keeps the codebase clean without disrupting your development flow.