# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhishQS is a hybrid iOS/Node.js project with four distinct functional components:

### **iOS App Components:**
1. **Tour Setlist Browser (Component A)**: Display of the latest Phish show setlist with color-coded song durations and venue context
2. **Tour Statistics Display (Component B)**: Pre-computed statistical cards showing longest/rarest/most-played songs from current tour
3. **Historical Show Search (Component C)**: Date-driven search and display of any historical Phish show (1983-present)
4. **Tour Calendar (Component D)**: Interactive calendar view showing tour dates across multiple months with venue badges

### **Server Components:**
- **Vercel-deployed Node.js serverless functions**: Serve pre-computed data via multiple endpoints
  - `/api/tour-statistics` - Pre-computed tour statistics for Component B
  - `/api/tour-dashboard` - Tour control data for Component A navigation
  - `/api/shows/[date]` - Individual show data for Component A display
- **Single source of truth data generation**: Handle data aggregation from Phish.net and Phish.in APIs during build time

## ✅ IMPLEMENTATION STATUS: Single Source Architecture Complete

**Phase 1 & 2 Complete** (September 2025) - **🎉 FULLY TESTED & WORKING IN XCODE**

### **Architecture Achievement:**
- **Component A**: Converted from real-time API calls to remote data fetching ✅ **WORKING**
- **Component B**: Already using single source architecture ✅ **WORKING**
- **Both components**: Now achieve 100% functionality from same data source ✅ **VERIFIED**
- **Performance**: 97% improvement (62-140ms vs 60+ seconds) ✅ **MEASURED**
- **Zero Runtime API Calls**: No calls to Phish.net/Phish.in during app usage ✅ **CONFIRMED**

### **🎯 Live Testing Results:**
- **Component A Remote Fetching**: Successfully fetched tour dashboard and show data (2025-07-27)
- **Component A Data Decoding**: 20 setlist items and 20 track durations processed correctly
- **Component B Statistics**: 62.40ms server response time with all 3 statistical cards loaded
- **Tour Identification**: "2025 Early Summer Tour" correctly identified and displayed
- **Error Resolution**: All data model mismatches fixed through comprehensive debugging

### **New Vercel API Endpoints:**
- `/api/tour-dashboard` - Serves tour control data (replaces Component A API calls)
- `/api/shows/[date]` - Serves individual show data dynamically
- `/api/tour-statistics` - Existing tour statistics endpoint (Component B)

### **iOS App Architecture:**
- `TourDashboardDataClient.swift` - New service for remote data fetching
- `LatestSetlistViewModel.swift` - Updated to use single source data
- Error-first architecture with no fallbacks for explicit troubleshooting
- Clean separation: VSCode manages JSON data files, Xcode only Swift code

### **📊 Technical Implementation Details:**
- **Data Model Fixes**: 4 critical iOS/API data structure mismatches resolved
  - Setlist items: `song` vs `songName`, `trans_mark` vs `transition`
  - Track durations: Nested `venueRun` structure vs flat `city`/`state` fields  
  - Song gaps: Multiple nullable fields made optional in iOS models
  - Recordings: Custom `CodingKeys` to ignore unneeded API fields
- **TourDashboardDataClient.swift**: New service with URLSession remote fetching
- **LatestSetlistViewModel.swift**: Converted from APIManager to single source client
- **API Endpoints**: All deployed and tested on https://phish-qs.vercel.app

### **🚀 Ready for GitHub Actions:**
Automated update pipeline will work seamlessly:
1. GitHub Actions generates fresh data files in `Server/Data/`
2. Vercel auto-deploys updated JSON files to production  
3. iOS app automatically gets latest data via remote endpoints
4. Zero downtime updates with immediate data availability

**Next Phase**: Enhanced browsing features and historical tour integration

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
- iOS target requires iOS 16.0+ and Xcode 15+
- UI tests are located in `Tests/PhishQSUITests/`
- Test files: `PhishQSTests` and `PhishQSUITests` targets
- Node.js 18+ required for server components

## App Components

### Component A: Tour Setlist Browser

**Purpose**: Interactive browser for exploring ANY setlist from the current tour, not just the latest show.

**Current Implementation**:
- **Files**: `Features/LatestSetlist/LatestSetlistViewModel.swift`, `Features/Dashboard/LatestShowHeroCard.swift`
- **Navigation**: Previous/Next arrow buttons for chronological show browsing
- **Features**: 
  - Color-coded song durations with gradients (requires Phish.in duration data)
  - Venue run badges (N1/N2/N3) and tour position indicators (Show 23/31)
  - Intelligent show caching for smooth navigation
  - **✅ SINGLE SOURCE ARCHITECTURE** - Remote data fetching via Vercel endpoints
  - **✅ ZERO API CALLS** - No runtime calls to Phish.net/Phish.in APIs

**Data Flow**:
- **✅ NEW**: Remote data fetching from `/api/tour-dashboard` and `/api/shows/[date]`
- **Primary**: Pre-generated tour data from single source of truth
- **Enhancement**: Song durations included in pre-computed data (no live API calls)
- **Tour Context**: Complete venue runs and tour positions from control file
- **Performance**: ~140ms response time vs 60+ seconds for real-time calculation

**Current Scope**: Latest show display only

**Future Evolution**: 
- Enhanced setlist presentation and interaction
- Potential features: detailed song information, audio integration, sharing capabilities
- Goal: Rich, immersive display of the most recent Phish concert

---

### Component B: Tour Statistics Display

**Purpose**: Pre-computed statistical analysis and insights from the current tour.

**Implementation**:
- **Files**: `Features/Dashboard/TourMetricCards.swift`, `Services/Core/TourStatisticsAPIClient.swift`
- **Display**: Three statistical cards in vertical layout
- **Cards**: 
  1. **Longest Songs**: Top 3 by duration with venue/date context
  2. **Rarest Songs**: Top 3 by gap (shows since last played) with historical context
  3. **Most Played Songs**: Top 3 by frequency within current tour

**Data Flow**:
- **Source**: Pre-computed server JSON via `/api/tour-statistics` endpoint
- **Performance**: ~140ms server response vs 60+ seconds local calculation
- **Caching**: 1-hour TTL via CacheManager for dashboard optimization
- **Generation**: Server uses hybrid Phish.net (gaps, tour structure) + Phish.in (durations) data

**Scope**: Current tour statistical aggregation only

---

### Component C: Historical Show Search

**Purpose**: Search and view any historical Phish show by date from ANY tour or year.

**Implementation**:
- **Files**: `Features/YearSelection/`, `Features/MonthSelection/`, `Features/DaySelection/`, `Features/Setlist/`
- **Navigation Flow**: Year → Month → Day → Full Setlist View
- **Search Pattern**: Date-driven discovery (1983-present excluding hiatus years)

**Data Flow**:
- **APIs**: Same real-time coordination as Tour Browser (Phish.net + Phish.in + tour services)
- **Performance**: On-demand API calls (no pre-computation needed)
- **Caching**: Individual show caching via CacheManager
- **Scope**: Complete historical archive access

**Features**:
- Complete setlist display with venue information
- Color-coded durations when Phish.in data available
- Venue and location context for historical shows

---

### Component D: Tour Calendar

**Purpose**: Visual calendar display showing all tour dates across multiple months with interactive navigation.

**Implementation**:
- **Files**: `Features/Calendar/TourCalendarView.swift`, `Features/Calendar/TourCalendarViewModel.swift`, `Features/Calendar/CalendarModels.swift`
- **Display**: Swipeable month-by-month calendar with tour dates marked
- **Features**:
  - Multi-month tour visualization with only tour-relevant months shown
  - Venue badges with city/state for multi-night runs
  - Color-coded tours (current and future tours)
  - Current day indicator with red circle outline
  - Smooth TabView swiping between months
  - Marquee scrolling for long venue names

**Data Flow**:
- **Source**: Tour dashboard data from `TourDashboardDataClient`
- **Processing**: Builds calendar months only for months containing tour dates
- **Display**: Interactive calendar with venue run spanning and tour color coding
- **Performance**: Efficient rendering with only necessary months displayed

**Visual Design**:
- Tour dates shown as colored circles matching tour colors
- Venue badges span across multi-night runs
- Current day has distinctive red circle outline
- Non-tour dates shown as plain text
- Consistent color system using `generateConsistentColor` function

---

## Architecture Overview

### iOS App Structure  
The iOS app follows a component-based architecture with clear functional boundaries:

#### **Component A: Tour Setlist Browser**
- **Features/LatestSetlist/**: Latest setlist display with enhanced visual features
- **Features/Dashboard/LatestShowHeroCard.swift**: Latest show card UI for dashboard integration
- **Shared**: Uses common services (APIManager, CacheManager, tour services)

#### **Component B: Tour Statistics Display**  
- **Features/Dashboard/TourMetricCards.swift**: Statistical cards UI (longest, rarest, most-played)
- **Features/TourDashboard/**: Dashboard integration and statistics presentation
- **Services/Core/TourStatisticsAPIClient.swift**: Server communication for pre-computed stats

#### **Component C: Historical Show Search**
- **Features/YearSelection/**, **Features/MonthSelection/**, **Features/DaySelection/**: Date navigation hierarchy  
- **Features/Setlist/**: Historical setlist display with detailed track views
- **Shared**: Uses common services for real-time API coordination

#### **Component D: Tour Calendar**
- **Features/Calendar/**: Complete calendar implementation with models, views, and view models
- **CalendarModels.swift**: Data structures for calendar display, venue runs, and tour configuration
- **TourCalendarView.swift**: SwiftUI calendar interface with month swiping and venue badges
- **TourCalendarViewModel.swift**: Business logic for calendar data processing and venue run detection

#### **Shared Services Layer**

**Used by ALL Components:**
- **Services/APIManager.swift**: Central coordinator between Phish.net and Phish.in APIs
- **Services/Core/CacheManager.swift**: Data persistence and cache invalidation  
- **Services/PhishNet/**: Phish.net API client and tour services
- **Services/PhishIn/**: Phish.in API client (song durations only)
- **Models/**: Shared data models (Show, SetlistItem, EnhancedSetlist, etc.)
- **Utilities/**: Helper functions and extensions

**Component-Specific Services:**
- **Component A**: `LatestSetlistViewModel` (latest setlist display logic)
- **Component B**: `TourStatisticsAPIClient` (server statistics communication)  
- **Component C**: `SetlistViewModel`, `YearListViewModel` (historical search logic)

**Shared Configuration:**
- **Services/Core/TourConfig.swift**: Centralized tour configuration (eliminates hardcoded values)
- **Services/Core/SetlistMatchingService.swift**: Position-based data matching utilities
- **Services/Core/HistoricalGapCalculator.swift**: Song gap calculations

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

### Component A: Tour Setlist Browser Data Flow
1. **Show Discovery**: `LatestSetlistViewModel` fetches latest show via Phish.net API
2. **Enhanced Data Collection**:
   - **Setlist Items**: Phish.net API provides song names, transitions, venue information
   - **Duration Enhancement**: Phish.in API provides song durations for color gradient calculation  
   - **Tour Context**: PhishNetTourService provides venue runs (N1/N2/N3) and tour positions (Show 23/31)
3. **Real-time Updates**: Live API coordination with intelligent caching via CacheManager
4. **Display**: Color-coded setlists with venue context and tour information

### Component B: Tour Statistics Data Flow  
1. **Server Pre-computation**:
   - **Data Sources**: Phish.net API (tour structure, gaps) + Phish.in API (durations)
   - **Processing**: `npm run generate-stats` calculates longest/rarest/most-played songs
   - **Storage**: Results stored in `Server/Data/tour-stats.json`
2. **API Serving**: 
   - Vercel serverless function serves via `/api/tour-statistics`
   - Cache headers set for performance (`s-maxage=3600`)
3. **iOS Consumption**: 
   - `TourStatisticsAPIClient` fetches pre-computed data (~140ms response)
   - CacheManager provides 1-hour local caching for dashboard optimization
   - Three statistical cards display instantly (no calculation wait)

### Component C: Historical Show Search Data Flow
1. **Date Navigation**: Year/Month/Day selection provides target date
2. **On-Demand Fetching**: Same real-time API coordination as Component A
   - **Setlist Data**: Phish.net API for historical show information
   - **Duration Enhancement**: Phish.in API for color gradients (when available)
   - **Context**: Tour services for historical venue/tour information
3. **Individual Caching**: Each historical show cached separately via CacheManager
4. **Display**: Complete historical setlist with venue context

## Testing
- iOS UI tests in `Tests/PhishQSUITests/`
- No server-side tests currently implemented
- Mock implementations available for API clients

## Component Development Guidelines

### Working on Individual Components

#### **Component A: Tour Setlist Browser Development**
- **Focus Area**: `Features/LatestSetlist/`, `Features/Dashboard/LatestShowHeroCard.swift`
- **Key Services**: `LatestSetlistViewModel`, `APIManager`, `CacheManager`
- **Testing**: Verify latest show display, color gradients, venue run badges
- **Future Development**: Enhanced setlist presentation, potential audio integration, sharing features
- **Data Dependencies**: Requires both Phish.net (setlists) AND Phish.in (durations) for full functionality

#### **Component B: Tour Statistics Development**  
- **Focus Area**: `Features/Dashboard/TourMetricCards.swift`, `Services/Core/TourStatisticsAPIClient.swift`
- **Key Services**: `TourStatisticsAPIClient`, pre-computed server data
- **Testing**: Verify 3 statistical cards display, server response performance
- **Server Dependency**: Requires `npm run generate-stats` and `/api/tour-statistics` endpoint
- **Development Pattern**: UI changes only - statistics logic handled server-side

#### **Component C: Historical Show Search Development**
- **Focus Area**: `Features/YearSelection/`, `Features/MonthSelection/`, `Features/DaySelection/`, `Features/Setlist/`  
- **Key Services**: `SetlistViewModel`, `YearListViewModel`, same API coordination as Component A
- **Testing**: Verify Year/Month/Day navigation flow, historical setlist display
- **Data Source**: Real-time API calls (not pre-computed like Component B)

#### **Component D: Tour Calendar Development**
- **Focus Area**: `Features/Calendar/`
- **Key Services**: `TourCalendarViewModel`, `TourDashboardDataClient`
- **Testing**: Verify calendar month generation, venue badge spanning, tour color consistency
- **Data Dependencies**: Uses tour dashboard data including future tours
- **UI Framework**: SwiftUI-based component integrated into UIKit app
- **Key Features**: Month swiping, venue run detection, current day highlighting

### Component Boundaries and Isolation

#### **Shared Resources:**
- **APIs**: All components use `APIManager` for Phish.net/Phish.in coordination
- **Caching**: All components use `CacheManager` with component-specific cache keys
- **Models**: Shared data models (`Show`, `SetlistItem`, `EnhancedSetlist`) across all components
- **Configuration**: `TourConfig.swift` provides centralized tour settings

#### **Component Independence:**
- **Component A**: Can be developed independently - latest show display logic is self-contained
- **Component B**: Completely independent - only depends on server API, not other components  
- **Component C**: Independent historical search - shares API layer but separate UI flow
- **Component D**: Self-contained calendar component - uses tour dashboard data but independent UI

#### **Cross-Component Dependencies:**
- **None**: Components do not directly depend on each other
- **Dashboard Integration**: `TourDashboardView` composes all four components but they remain independent
- **Shared Services**: Components communicate only through shared services, not direct references

### Development Best Practices

#### **Component-Specific Guidelines:**

**For Tour Setlist Browser (Component A):**
- Focus on latest show display excellence and user experience
- Maintain color gradient functionality (requires Phish.in duration data)
- Optimize for fast loading and clean presentation of latest show data
- Future UI enhancements should improve setlist readability and interaction

**For Tour Statistics (Component B):**
- Focus on UI/UX improvements - statistical logic is server-side
- Ensure proper error handling for server API failures
- Maintain 1-hour caching for dashboard performance  
- Server changes require both `generate-stats` script updates AND deployment

**For Historical Show Search (Component C):**
- Optimize for discovery patterns (Year → Month → Day flow)
- Handle missing historical data gracefully
- Consider performance for large year/month selections
- Reuse setlist display logic from other components where possible

**For Tour Calendar (Component D):**
- Maintain consistent color generation across tour dates
- Ensure venue badges properly span multi-night runs
- Keep current day indicator visually distinct (red circle outline)
- Optimize calendar month generation to only include tour-relevant months
- Test swipe navigation performance with multiple months
- Preserve marquee scrolling for long venue names

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

### Unified Color System
- **Color Generation**: Use `generateConsistentColor(for:seedText:)` for all dynamic colors
- **Tour Colors**: Generated using `tourColor(for:tourName:)` function
- **Color Palette**: Blue, orange, green, purple, teal, indigo (red/pink reserved for UI indicators)
- **Current Day Indicator**: Red circle outline is reserved exclusively for calendar current day
- **Consistency**: Same color algorithm used across venue badges, tour dates, and statistics

### Phish Song Filtering Best Practices

**CRITICAL**: Always filter for songs performed by Phish using exclusion method, not inclusion.

#### Why This Matters
The Phish.net database contains songs performed by various artists:
- **Phish originals**: `artist: "Phish"`
- **Covers performed by Phish**: `artist: "Led Zeppelin"`, `artist: "Strauss, as interpreted by Deodato"`
- **Side project songs**: `artist: "Trey Anastasio"`, `artist: "Mike Gordon"`

#### Correct Filtering Approach
```javascript
const sideProjectArtists = [
    'Trey Anastasio', 'Mike Gordon', 'Page Mcconnell', 'Page McConnell',
    'Leo Kotke/Mike Gordon', 'Mike Gordon and Leo Kottke',
    'Trey, Mike, and The Benevento/Russo Duo', 'Trey Anastasio & Don Hart'
];

// Include all songs EXCEPT side projects
const phishPerformedSongs = allSongs.filter(song =>
    song.times_played > 0 && !sideProjectArtists.includes(song.artist)
);
```

#### Results
- ✅ **Includes**: Phish originals + covers performed by Phish
- ✅ **Excludes**: Side project songs by individual band members
- ✅ **Total**: 902 songs performed by Phish vs 333 with incorrect inclusion filter

**Examples**:
- ✅ Included: "Also Sprach Zarathustra" (272 plays, artist: "Strauss, as interpreted by Deodato")
- ✅ Included: "Good Times Bad Times" (231 plays, artist: "Led Zeppelin")
- ❌ Excluded: "A Wave of Hope" (36 plays, artist: "Trey Anastasio")

### Data Pipeline Architecture for Future Features

**CRITICAL**: All new data-driven features must follow the established single source architecture to maintain performance and reliability.

#### Core Principles
1. **Single Source of Truth**: All data pre-computed and stored in `Server/Data/`
2. **GitHub Actions Integration**: Automated updates via existing 3x daily workflow
3. **Vercel Deployment**: Zero-config deployment via existing `vercel.json`
4. **Performance First**: ~140ms API responses maintained through pre-computation

#### Required Data Flow Pattern

**✅ Correct Pattern (MANDATORY)**:
```
1. Data Collection    → generate-stats.js (GitHub Actions)
2. Pre-computation    → Calculator classes via StatisticsRegistry
3. Storage           → Server/Data/*.json (single source)
4. API Serving       → /api/* endpoints (Vercel)
5. iOS Consumption   → Remote fetch from pre-computed data
```

**❌ Prohibited Pattern**:
```
1. Runtime API Calls → External APIs during app usage
2. Client Computation → Statistics calculated on iOS device
3. Multiple Sources  → Data from different endpoints/files
```

#### Implementation Checklist for New Features

**Data Collection Enhancement**:
- [ ] Add data fetching to existing `generate-stats.js` script
- [ ] Integrate with existing `npm run generate-stats` command
- [ ] Store results in `Server/Data/` directory
- [ ] No new scripts or GitHub Actions modifications

**Calculator Implementation**:
- [ ] Extend `BaseStatisticsCalculator` class
- [ ] Register in existing `StatisticsRegistry.js`
- [ ] Use only provided tour data (no external API calls)
- [ ] Add configuration to `StatisticsConfig.js`

**API Integration**:
- [ ] Enhance existing endpoint response (no new endpoints)
- [ ] Maintain existing `vercel.json` configuration
- [ ] Preserve cache headers (`s-maxage=3600`)
- [ ] Keep ~140ms response time performance

**iOS Integration**:
- [ ] Update existing data models in `SharedModels.swift`
- [ ] Use existing API client services
- [ ] Follow state-driven UI patterns
- [ ] Integrate with existing dashboard components

#### Infrastructure Compliance

**✅ Zero Infrastructure Changes Required**:
- **GitHub Actions**: Uses existing workflow, no new steps
- **Vercel Config**: Uses existing `includeFiles: "Server/Data/**"`
- **NPM Scripts**: Uses existing `npm run generate-stats`
- **API Endpoints**: Enhances existing `/api/tour-statistics`

**✅ Automatic Deployment**:
- Code changes trigger existing GitHub Actions
- Data updates stored in `Server/Data/`
- Vercel auto-deploys enhanced JSON files
- iOS app automatically receives new data

#### Performance Requirements
- **API Response**: Maintain ~140ms server response time
- **Data Storage**: Minimal additions to existing JSON files
- **Client Performance**: No impact on iOS app launch or navigation
- **Caching**: Utilize existing 1-hour cache strategy

This architecture ensures all future features integrate seamlessly with the established automated pipeline while maintaining performance and reliability standards.

### State-Driven UI Best Practices

**MANDATORY**: All UI animations and transitions must be state-driven, not timing-based.

#### Professional iOS Standard
State-driven UI is the industry standard for professional iOS apps and is required by Apple's Human Interface Guidelines. Apps like Spotify, Instagram, and Apple's own apps use state-driven patterns exclusively.

#### Core Principles
1. **📊 Data-Responsive**: UI reacts to actual state changes, not arbitrary time delays
2. **🎯 Consistent**: Eliminates race conditions and timing inconsistencies
3. **⚡ Performance-Adaptive**: Works smoothly on all device capabilities
4. **🛡️ Reliable**: No dependency on timing guesswork
5. **🔄 Maintainable**: Clear state dependencies vs buried timing constants

#### Required Pattern

**✅ Professional State-Driven (REQUIRED):**
```swift
@State private var shouldTriggerAction = false

.onChange(of: shouldTriggerAction) { _, newValue in
    if newValue && conditionsMet {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Perform UI action
        }
        shouldTriggerAction = false  // Reset state
    }
}
```

**❌ Timing-Based (FORBIDDEN):**
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
    // UI action - unreliable and unprofessional
}
```

#### Implementation Examples

**Accordion/Collapsible UI:**
```swift
@State private var isExpanded = false
@State private var shouldScrollToTop = false

Button(action: {
    let wasExpanded = isExpanded
    withAnimation(.easeInOut(duration: 0.3)) {
        isExpanded.toggle()
        if wasExpanded {
            shouldScrollToTop = true
        }
    }
})

.onChange(of: shouldScrollToTop) { _, newValue in
    if newValue && !isExpanded {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo("cardId", anchor: .top)
            }
            shouldScrollToTop = false
        }
    }
}
```

**Loading State Transitions:**
```swift
.onChange(of: dataModel.isLoading) { _, isLoading in
    if !isLoading && dataModel.hasData {
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = true
        }
    }
}
```

#### When Timing is Acceptable
Limited exceptions for essential UX requirements:
- **Minimum brand display time** (professional app launch sequences)
- **Accessibility compliance** (screen reader timing requirements)
- **Animation completion coordination** (only when SwiftUI completion callbacks unavailable)

Even in these cases, timing should be:
- Minimal and justified
- Well-documented with clear reasoning
- Combined with state checks for reliability

#### Tools and Techniques
- **SwiftUI State Management**: `@State`, `@ObservableObject`, `@Published`
- **State Observers**: `.onChange()`, `.onReceive()`
- **Animation Coordination**: `withAnimation()` with completion patterns
- **Conditional UI**: `@ViewBuilder` for state-driven view composition

#### Success Metrics
- ✅ No arbitrary timing delays in UI code
- ✅ Smooth performance across all device types
- ✅ Predictable behavior regardless of system load
- ✅ Professional user experience matching industry standards
- ✅ Easy to test and debug state transitions

**This pattern is demonstrated in `TourMetricCards.swift` accordion implementation and should be applied consistently across all new UI development.**

## Component Evolution Roadmap

### Component A: Tour Setlist Browser Evolution
**Current State**: Latest show display with color gradients and venue context
**Planned Enhancements**:
- **Enhanced Display Features**: Improve latest show presentation
  - Detailed song information and metadata
  - Audio integration for enhanced experience
  - Sharing and social features
- **Rich Content Mode**: Enhanced setlist details and context
- **Performance**: Optimize for fast loading and smooth scrolling

### Component B: Tour Statistics Evolution  
**Current State**: Three statistical cards (longest, rarest, most-played songs)
**Planned Enhancements**:
- **Additional Statistics**: Show trends, venue patterns, set length analysis
- **Interactive Charts**: Visual representations of tour progression
- **Comparison Mode**: Compare current tour to historical tours
- **Real-time Updates**: Live statistics during active touring

### Component C: Historical Show Search Evolution
**Current State**: Year/Month/Day navigation with full setlist display
**Planned Enhancements**:
- **Advanced Search**: Search by venue, song, tour name
- **Favorites System**: Save and organize favorite historical shows
- **Discovery Features**: "Shows like this one" recommendations
- **Enhanced Display**: Richer historical context and metadata

### Component D: Tour Calendar Evolution
**Current State**: Interactive calendar with tour dates, venue badges, and tour color coding
**Planned Enhancements**:
- **Show Details on Tap**: Quick access to setlist from calendar date
- **Tour Filtering**: Toggle visibility of different tours
- **Historical Tours**: Extend calendar to show past tours
- **Export Features**: Save tour calendar as image or add to device calendar
- **Venue Details**: Enhanced venue information in popover views

### Cross-Component Evolution
**Shared Enhancements**:
- **Unified Design Language**: Consistent UI/UX across all components
- **Performance Optimization**: Enhanced caching and API efficiency
- **Accessibility**: Improved accessibility features across components
- **Integration Points**: Smart connections between components (e.g., "View this show in tour context")

---

## Deployment

### Automated Deployment (GitHub Actions)
**✅ ACTIVE: Automated tour data updates via GitHub Actions**

The system automatically detects and updates tour data 3 times daily:
- **Midnight EDT**: Post-show detection for East Coast shows
- **4am EDT**: Late shows and West Coast coverage  
- **4pm EDT**: Pre-show data refresh and Phish.in retry

**Setup Requirements (One-time):**
1. **GitHub Secret Configuration**:
   - Go to Repository Settings → Secrets and variables → Actions
   - Add secret: `PHISH_NET_API_KEY` = `4771B8589CD3E53848E7`

2. **Workflow File**: Already configured in `.github/workflows/update-tour-data.yml`

3. **Manual Trigger**: Available via Actions tab → "Update Tour Data" → "Run workflow"

**How It Works:**
1. GitHub Actions runs on schedule
2. Executes: `update-tour-dashboard` → `initialize-tour-shows` → `generate-stats`
3. Commits changes only when new shows detected
4. Vercel auto-deploys updated data
5. All 4 app components update automatically

### Manual Deployment (Fallback)
- **Server**: Deployed to Vercel via `npm run deploy`
- **iOS**: Standard Xcode build and distribution process
- **Component B Dependency**: Statistics data regenerated via `npm run generate-stats` and deployment
- **Component A & C**: No deployment dependencies (use real-time APIs)
- **Component D**: Uses tour dashboard data, requires `npm run update-tour-dashboard` for data updates

---

## 🧹 Code Cleanup Process

**IMPORTANT**: Run this comprehensive cleanup process after major features or periodically to maintain professional code quality standards.

### When to Run Code Cleanup
- After implementing a new feature
- Before major releases
- When technical debt accumulates
- During slower development periods
- After multiple quick fixes or hotfixes

### Cleanup Philosophy
- **Professional Standards**: Match quality of apps like Spotify, Airbnb, Zillow
- **Clean Code**: Prioritize readability, maintainability, and simplicity
- **DRY Principle**: Don't Repeat Yourself - eliminate duplication
- **SOLID Principles**: Single responsibility, open/closed, Liskov substitution
- **Swift Best Practices**: Follow Apple's Swift API Design Guidelines
- **Performance First**: Optimize for speed and memory efficiency

---

### 📋 Comprehensive Code Cleanup Checklist

#### Phase 1: Recent Changes Audit
- [ ] Review last 5-10 commits for rushed/temporary code
- [ ] Check for TODO/FIXME comments that need addressing
- [ ] Identify any hardcoded values that should be constants
- [ ] Look for console.log/print statements to remove
- [ ] Verify all debugging code is removed
- [ ] Check for commented-out code blocks to delete

#### Phase 2: Dead Code Elimination
- [ ] **Unused Imports**: Remove all unused import statements
- [ ] **Unused Variables**: Delete variables that are never referenced
- [ ] **Unused Functions**: Remove functions with no callers
- [ ] **Unused Components**: Delete UI components not in use
- [ ] **Unused Files**: Remove obsolete files and test files
- [ ] **Legacy Code**: Remove old implementations replaced by new ones
- [ ] **Conditional Dead Code**: Remove if(false) blocks and unreachable code

#### Phase 3: Code Duplication Analysis
- [ ] **Identical Code Blocks**: Extract to shared functions
- [ ] **Similar Logic Patterns**: Create generic/template functions
- [ ] **Repeated Constants**: Move to centralized configuration
- [ ] **Copy-Paste UI**: Create reusable components
- [ ] **Similar API Calls**: Consolidate into service methods
- [ ] **Repeated Error Handling**: Create error handling utilities

#### Phase 4: Modularization & Organization
- [ ] **Large Files (>300 lines)**: Split into logical extensions/modules
- [ ] **God Classes**: Break down classes with too many responsibilities
- [ ] **Long Functions (>30 lines)**: Decompose into smaller functions
- [ ] **Deep Nesting (>3 levels)**: Refactor with early returns/guard clauses
- [ ] **File Organization**: Ensure files are in correct directories
- [ ] **Naming Consistency**: Verify consistent naming conventions

#### Phase 5: Swift/iOS Best Practices
- [ ] **Protocol Conformance**: Use extensions for protocol implementations
- [ ] **Value Types**: Prefer structs over classes where appropriate
- [ ] **Optionals**: Use guard let/if let instead of force unwrapping
- [ ] **Closures**: Use trailing closure syntax consistently
- [ ] **Access Control**: Apply proper private/internal/public modifiers
- [ ] **SwiftUI vs UIKit**: Ensure consistent framework usage
- [ ] **Async/Await**: Convert completion handlers where beneficial
- [ ] **Memory Management**: Check for retain cycles and weak references

#### Phase 6: Server/Node.js Best Practices
- [ ] **ES6+ Features**: Use modern JavaScript features consistently
- [ ] **Promise Chains**: Convert to async/await where cleaner
- [ ] **Error Handling**: Ensure try-catch blocks in async functions
- [ ] **Module Exports**: Use consistent export patterns
- [ ] **Dependencies**: Remove unused npm packages
- [ ] **Environment Variables**: No hardcoded secrets or keys

#### Phase 7: Performance Optimization
- [ ] **Image Assets**: Optimize image sizes and use correct formats
- [ ] **Network Calls**: Batch requests where possible
- [ ] **Caching Strategy**: Verify cache invalidation logic
- [ ] **Lazy Loading**: Implement for heavy components
- [ ] **Memory Leaks**: Profile and fix any memory issues
- [ ] **Algorithm Complexity**: Optimize O(n²) or worse algorithms

#### Phase 8: Data Flow Validation
- [ ] **API → Server**: Verify data collection from external APIs
- [ ] **Server → Storage**: Check data transformation and storage
- [ ] **Storage → API**: Validate data serving endpoints
- [ ] **API → iOS**: Ensure proper data decoding
- [ ] **Error States**: Handle all failure scenarios gracefully
- [ ] **Loading States**: Provide appropriate loading indicators

#### Phase 9: UI/UX Consistency
- [ ] **Color Usage**: Verify consistent color system usage
- [ ] **Typography**: Check font sizes and weights consistency
- [ ] **Spacing**: Ensure consistent padding and margins
- [ ] **Animations**: Verify state-driven (not timing-based)
- [ ] **Empty States**: Provide meaningful empty state messages
- [ ] **Error Messages**: User-friendly and actionable
- [ ] **Accessibility**: VoiceOver support and Dynamic Type

#### Phase 10: Documentation & Comments
- [ ] **File Headers**: Add/update file purpose comments
- [ ] **Complex Logic**: Add explanatory comments for non-obvious code
- [ ] **API Documentation**: Document all public methods
- [ ] **Type Definitions**: Ensure all types have clear purposes
- [ ] **README Updates**: Keep documentation current
- [ ] **CLAUDE.md Updates**: Document any new patterns or decisions

#### Phase 11: Testing & Validation
- [ ] **Build Warnings**: Resolve all compiler warnings
- [ ] **Lint Issues**: Fix all linting errors and warnings
- [ ] **Type Safety**: Ensure proper typing throughout
- [ ] **Test Coverage**: Add tests for new functionality
- [ ] **Manual Testing**: Test all user paths
- [ ] **Edge Cases**: Test boundary conditions and error states

#### Phase 12: Final Review
- [ ] **Code Review**: Self-review all changes
- [ ] **Consistency Check**: Verify adherence to project patterns
- [ ] **Performance Check**: Profile app performance
- [ ] **Memory Check**: Verify no memory leaks introduced
- [ ] **Regression Check**: Ensure existing features still work
- [ ] **Deployment Ready**: All debug code removed

#### Phase 13: Document Cleanup Results
- [ ] **Update CLEANUP_LOG.md**: Record session summary
- [ ] **Document Metrics**: Files modified, lines removed, improvements made
- [ ] **Update Action Items**: Add new items discovered during cleanup
- [ ] **Track Technical Debt**: Update debt tracker with resolved/new items
- [ ] **Note Patterns**: Document any new anti-patterns or best practices found
- [ ] **Plan Next Session**: Set focus areas for next cleanup

**IMPORTANT**: Always complete Phase 13 to maintain visibility into code quality trends and ensure action items are tracked.

---

### 🎯 Areas to Focus (Current Project Specific)

Based on recent development, prioritize these areas:

1. **Tour Statistics Cards**
   - Consolidate duplicate row components
   - Ensure consistent styling across all cards
   - Verify proper data flow from server

2. **Data Pipeline**
   - Server data collection scripts
   - Statistics calculators modularity
   - API response optimization
   - iOS data models alignment

3. **UI Components**
   - SharedUIComponents usage consistency
   - Color system application
   - State-driven animations
   - Accordion behavior patterns

4. **Service Layer**
   - API client consolidation
   - Cache management efficiency
   - Error handling consistency
   - Network request optimization

5. **Recent Features**
   - MostCommonSongsNotPlayed implementation
   - Tour calendar efficiency
   - Single source architecture adherence

---

### 📝 Cleanup Output Documentation

After cleanup, document:
1. **Lines of code removed**: Track reduction metrics
2. **Files deleted**: List obsolete files removed
3. **Performance improvements**: Measure load time changes
4. **Duplicates eliminated**: Count consolidated code blocks
5. **Warnings resolved**: Number of issues fixed
6. **Technical debt paid**: Major improvements made

---

### 🔄 Continuous Improvement

- Run lightweight cleanup after each feature
- Schedule comprehensive cleanup monthly
- Track metrics to measure code quality trends
- Update this checklist based on lessons learned
- Share cleanup results with team for visibility
- **Maintain CLEANUP_LOG.md** with all session results and action items
- Review action items from previous cleanups before starting new ones