# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhishQS is a hybrid iOS/Node.js project with three distinct functional components:

### **iOS App Components:**
1. **Tour Setlist Browser**: Interactive navigation through all shows from the current tour (with Previous/Next arrows, future enhanced browsing)
2. **Tour Statistics Display**: Pre-computed statistical cards showing longest/rarest/most-played songs from current tour
3. **Historical Show Search**: Date-driven search and display of any historical Phish show (1983-present)

### **Server Components:**
- **Vercel-deployed Node.js serverless functions**: Pre-compute and serve tour statistics via `/api/tour-statistics`
- **Multi-API coordination services**: Handle real-time data aggregation from Phish.net and Phish.in APIs

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
  - Real-time API coordination between Phish.net and Phish.in

**Data Flow**:
- **Primary**: Phish.net API for setlists, venues, dates, tour organization
- **Enhancement**: Phish.in API for song durations (enables color gradients)
- **Tour Context**: PhishNetTourService for venue runs and tour positions
- **Performance**: Live API calls with tour-scoped caching via CacheManager

**Current Scope**: Current tour only (not historical tours - that's Component C)

**Future Evolution**: 
- Current arrow navigation is foundation for enhanced browsing UI
- Potential interfaces: horizontal scroll view, slider with position indicator, swipe-based carousel
- Goal: Intuitive "flipping through" all setlists from current tour

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

## Architecture Overview

### iOS App Structure  
The iOS app follows a component-based architecture with clear functional boundaries:

#### **Component A: Tour Setlist Browser**
- **Features/LatestSetlist/**: Tour navigation and setlist display (Note: "Latest" naming is historical - component handles all tour shows)
- **Features/Dashboard/LatestShowHeroCard.swift**: Tour show browser card UI
- **Shared**: Uses common services (APIManager, CacheManager, tour services)

#### **Component B: Tour Statistics Display**  
- **Features/Dashboard/TourMetricCards.swift**: Statistical cards UI (longest, rarest, most-played)
- **Features/TourDashboard/**: Dashboard integration and statistics presentation
- **Services/Core/TourStatisticsAPIClient.swift**: Server communication for pre-computed stats

#### **Component C: Historical Show Search**
- **Features/YearSelection/**, **Features/MonthSelection/**, **Features/DaySelection/**: Date navigation hierarchy  
- **Features/Setlist/**: Historical setlist display with detailed track views
- **Shared**: Uses common services for real-time API coordination

#### **Shared Services Layer**

**Used by ALL Components:**
- **Services/APIManager.swift**: Central coordinator between Phish.net and Phish.in APIs
- **Services/Core/CacheManager.swift**: Data persistence and cache invalidation  
- **Services/PhishNet/**: Phish.net API client and tour services
- **Services/PhishIn/**: Phish.in API client (song durations only)
- **Models/**: Shared data models (Show, SetlistItem, EnhancedSetlist, etc.)
- **Utilities/**: Helper functions and extensions

**Component-Specific Services:**
- **Component A**: `LatestSetlistViewModel` (tour navigation logic)
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
3. **Navigation Support**: Shows cached for Previous/Next navigation efficiency
4. **Real-time Updates**: Live API coordination with intelligent caching via CacheManager
5. **Display**: Color-coded setlists with venue context and navigation controls

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
- **Testing**: Verify Previous/Next navigation, color gradients, venue run badges
- **Future Development**: Enhanced browsing UI (scroll view, slider, carousel) to replace arrow navigation
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

### Component Boundaries and Isolation

#### **Shared Resources:**
- **APIs**: All components use `APIManager` for Phish.net/Phish.in coordination
- **Caching**: All components use `CacheManager` with component-specific cache keys
- **Models**: Shared data models (`Show`, `SetlistItem`, `EnhancedSetlist`) across all components
- **Configuration**: `TourConfig.swift` provides centralized tour settings

#### **Component Independence:**
- **Component A**: Can be developed independently - tour navigation logic is self-contained
- **Component B**: Completely independent - only depends on server API, not other components  
- **Component C**: Independent historical search - shares API layer but separate UI flow

#### **Cross-Component Dependencies:**
- **None**: Components do not directly depend on each other
- **Dashboard Integration**: `TourDashboardView` composes all three components but they remain independent
- **Shared Services**: Components communicate only through shared services, not direct references

### Development Best Practices

#### **Component-Specific Guidelines:**

**For Tour Setlist Browser (Component A):**
- Preserve existing navigation logic while adding new browsing interfaces
- Maintain color gradient functionality (requires Phish.in duration data)
- Test show caching for smooth navigation performance
- Future UI enhancements should complement existing arrow navigation

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

## Component Evolution Roadmap

### Component A: Tour Setlist Browser Evolution
**Current State**: Previous/Next arrow navigation with color gradients and venue context
**Planned Enhancements**:
- **Enhanced Browsing UI**: Replace arrows with intuitive interfaces
  - Horizontal scroll view with show cards
  - Slider with position indicator and show preview
  - Swipe-based carousel navigation
- **Show Overview Mode**: Quick preview of all tour shows
- **Performance**: Optimize for larger tours (30+ shows)

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

### Cross-Component Evolution
**Shared Enhancements**:
- **Unified Design Language**: Consistent UI/UX across all components
- **Performance Optimization**: Enhanced caching and API efficiency
- **Accessibility**: Improved accessibility features across components
- **Integration Points**: Smart connections between components (e.g., "View this show in tour context")

---

## Deployment
- **Server**: Deployed to Vercel via `npm run deploy`
- **iOS**: Standard Xcode build and distribution process  
- **Component B Dependency**: Statistics data regenerated via `npm run generate-stats` and deployment
- **Component A & C**: No deployment dependencies (use real-time APIs)