# Component A: Tour Show Browser Enhancement

**Branch**: `component-a-view-all-tour-shows`  
**Status**: Complete Implementation Plan - Ready for Development  
**Date**: September 2025  
**Last Updated**: September 8, 2025

## Executive Summary

Transform Component A from displaying only the latest setlist to a comprehensive tour browser with timeline slider navigation. Users can browse any played show's complete setlist (with pre-computed color-coded songs) and preview future show dates/venues. This enhancement maintains the existing single-source architecture with zero runtime API calculations while providing an intuitive tour visualization experience.

## User Requirements Analysis

The user wants to transform Component A from showing only the latest setlist to allowing users to browse ANY show from the current tour. 

### Core User Vision:
- **Timeline Slider Interface**: iOS slider where users can drag to select any tour show
- **Live Preview**: Real-time indicator showing which date/venue will be displayed while dragging
- **Tour Progress Visualization**: Clear indication of tour completion (e.g., 23/23 shows complete for current tour)
- **Future Show Access**: Allow browsing future tour dates with venue preview (revised requirement)
- **Fixed Height Layout**: Prevent UI jumping when switching between setlists of different lengths

### User Concerns & Solutions:
- **Variable Setlist Lengths**: Different shows have different numbers of songs
  - *Solution*: Fixed-height containers (120pt preview, 300pt setlist) with internal scrolling
- **UI Stability**: Don't want cards jumping up/down when switching shows
  - *Solution*: All containers have fixed heights regardless of content
- **Visual Representation**: Good way to represent tour progression like a timeline
  - *Solution*: Horizontal slider with visual indicators for played vs future shows

### Requirement Evolution:
- **Original**: Block access to future shows (grayed out, disabled)
- **Updated**: Allow sliding to future shows for venue/date preview
- **Rationale**: Better tour planning visibility and user experience

## Current Implementation Analysis

### Existing Component A Architecture:
- **LatestSetlistView.swift**: Current latest-only display with setlist formatting
  - Creates color-coded setlist display with AttributedString
  - Groups songs by set (Set 1, Set 2, Encore)
  - Handles transition marks between songs
- **LatestShowHeroCard.swift**: Dashboard card showing latest show with venue badges
  - Fixed-height card design for dashboard integration
  - Displays venue run badges (N1/N2/N3) and tour position
  - Compact setlist view with line limits
- **LatestSetlistViewModel.swift**: Uses `TourDashboardDataClient` for single-source data
  - Fetches latest show from tour dashboard
  - Manages setlist items and track durations
  - Provides color calculation for songs (pre-computed from server)
- **TourDashboardDataClient.swift**: Remote data fetching from Vercel endpoints
  - Fetches from https://phish-qs.vercel.app/api/
  - Converts server data to iOS models
  - Handles network errors and retries

### Current Data Flow (Single-Source Architecture):
1. **Initial Load**: Fetches tour control data from `/api/tour-dashboard`
   - Contains all tour dates, venues, played status
   - Identifies latest played show
2. **Show Data**: Fetches individual show data from `/api/shows/[date]`
   - Pre-computed setlist with color values
   - Track durations already calculated
   - Venue run information included
3. **Display**: Shows single setlist with all pre-computed data
   - No iOS calculations needed
   - ~140ms response time
   - Zero runtime API calls to Phish.net/Phish.in

### Available Data Structure:
- **Tour Control File** (`tour-dashboard-data.json`):
  - 23 tour dates with venues and cities
  - Played status for each show (all true currently)
  - Show file paths for data fetching
  - Tour metadata (name, dates, totals)
- **Individual Show Files** (e.g., `show-2025-07-27.json`):
  - Complete setlist items with positions
  - Pre-computed track durations with color values
  - Venue run information (multi-night indicators)
  - Tour position data
- **Current Tour Status**: 2025 Early Summer Tour 
  - 23 shows played (100% complete)
  - Could be extended with future shows if tour continues

## UI/UX Research & Analysis

After analyzing user requirements and existing patterns, four distinct approaches were considered:

### **OPTION 1: Timeline Slider with Live Preview (SELECTED)**

**Why This Option**: Directly addresses user's timeline visualization requirement while solving UI stability concerns through fixed-height containers. Provides intuitive tour progression metaphor that scales well.

**Visual Concept**:
```
┌─────────────────────────────────────────────┐
│ 🎭 TOUR HEADER (40pt)                       │
│ "2025 Early Summer Tour"                    │
│ "23 Shows • Jun 20 - Jul 27"                │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│ 📅 SHOW PREVIEW CARD (120pt fixed)          │
│ Saturday, July 27, 2025        Show 23/23   │
│ The Sphere                          [N3]    │
│ Las Vegas, NV                               │
│ ✅ Setlist Available                        │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│ 📊 TIMELINE SLIDER (80pt)                   │
│  Jun 20                Jul 4          Jul 27│
│  │●━●━●━●━●━●━●━●━●━●━●━●━●━●━●━●━●━●━●│  │
│     ↑                                  ↑    │
│  First Show                      Current    │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│ 🎵 SETLIST DISPLAY (300pt fixed)            │
│ Set 1:                                      │
│ Fluffhead > Divided Sky > Wolfman's Brother │
│ → Guyute, Horn > Character Zero             │
│                                              │
│ Set 2:                                      │
│ Sand > Ghost → Twenty Years Later > ...     │
│ [Scrollable area if content exceeds height] │
└─────────────────────────────────────────────┘
```

**Key Features**:
- **Timeline Slider**: Horizontal slider with discrete positions for each show
- **Visual Differentiation**: Filled circles for played shows, hollow for future
- **Fixed Height Cards**: 
  - Tour header: 40pt
  - Show preview: 120pt (prevents jumping)
  - Timeline: 80pt
  - Setlist display: 300pt (internal scrolling)
- **Live Updates**: Date/venue preview updates instantly while dragging
- **Debounced Loading**: Setlist fetches after 500ms delay when user stops
- **Show Caching**: LRU cache stores 10 most recent shows

**Technical Advantages**:
- Leverages existing `TourDashboardDataClient` without modification
- Reuses setlist formatting logic from `LatestSetlistView`
- Maintains single-source architecture with zero calculations
- Natural extension of current fixed-height card pattern

### **Other Options Considered**

**OPTION 2: Horizontal Paging** - Swipeable cards with page dots. Native iOS pattern but lacks timeline visualization.

**OPTION 3: Split View** - Sidebar list with detail view. Good for power users but complex for mobile.

**OPTION 4: Accordion Style** - Expandable show headers. Space efficient but loses timeline metaphor.

**Decision**: Option 1 selected for best addressing timeline visualization, UI stability, and user intuition.

## Complete Expanded Design: Timeline Slider with Live Preview

### 📐 **Visual Design Specification**

#### **Layout Structure with Measurements**:

```
Total Height: 540pt (excluding safe areas)

┌─────────────────────────────────────────────┐
│ TOUR HEADER (40pt)                          │
│ Font: .headline (17pt)                      │
│ Padding: 8pt vertical, 16pt horizontal      │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│ SHOW PREVIEW CARD (120pt fixed)             │
│ Background: .systemBackground                │
│ Corner Radius: 12pt                         │
│ Shadow: radius 2pt                          │
│ Padding: 16pt all sides                     │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│ TIMELINE SLIDER (80pt total)                │
│ Track Height: 6pt                           │
│ Thumb Size: 32pt (touch target: 44pt)       │
│ Tick Marks: 8pt circles                     │
│ Padding: 16pt horizontal, 20pt vertical     │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│ SETLIST DISPLAY (300pt fixed)               │
│ Background: .systemBackground                │
│ Corner Radius: 12pt                         │
│ Internal ScrollView for overflow            │
│ Padding: 16pt all sides                     │
└─────────────────────────────────────────────┘
```

### 🎨 **Timeline Slider Visual States**

#### **Slider Appearance for Mixed Tour (Played + Future)**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  ●  ●  ●  ●  ●  ●  ●  ●  ○  ○  ○  ○  │  
│                          ◉            │  
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░│  
   Played (filled blue)    Future (hollow)

Legend:
● = Played show (filled blue circle)
○ = Future show (hollow blue circle, 0.3 opacity)
◉ = Currently selected (green if played, orange if future)
▓ = Progress fill (only to last played show)
░ = Unfilled track (future portion)
```

**Color Specifications**:
- **Played Shows**: System Blue (#007AFF) - Filled circles
- **Future Shows**: System Blue with 0.3 opacity - Hollow circles  
- **Selected Played**: Accent Green (#34C759) with white border
- **Selected Future**: Orange (#FF9500) with white border
- **Track Background**: System Gray6 (#F2F2F7)
- **Progress Fill**: Blue gradient (0.8 to 1.0 opacity)

### 🎯 **Interaction Patterns**

#### **Touch Interaction Flow**:
```
TOUCH DOWN:
├─ Haptic: UIImpactFeedbackGenerator.light
├─ Animation: Thumb scales to 1.2x (spring: 0.3s)
├─ Visual: Add 8pt shadow blur
└─ State: Set isDragging = true

DRAGGING:
├─ Update: 60fps position tracking
├─ Preview: Instant date/venue updates
├─ Haptic: Tick at each discrete position
├─ Visual: Thumb follows finger precisely
└─ Data: NO server calls during drag

TOUCH UP:
├─ Haptic: UIImpactFeedbackGenerator.medium
├─ Animation: Thumb scales to 1.0x (spring: 0.3s)
├─ Snap: Animate to nearest show position
├─ Timer: Start 500ms debounce
└─ Load: Fetch show data after timer
```

### 📅 **Show Preview Card Behavior**

#### **Played Show Display** (Shows 1-23):
```swift
VStack(alignment: .leading, spacing: 8) {
    // Date and position row
    HStack {
        VStack(alignment: .leading) {
            Text("Saturday, July 27, 2025")
                .font(.headline)
            Text("Day 38 of Tour")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        Spacer()
        BadgeView(text: "Show 23/23", style: .blue)
    }
    
    // Venue row
    HStack {
        VStack(alignment: .leading) {
            Text("The Sphere")
                .font(.subheadline)
                .fontWeight(.medium)
            Text("Las Vegas, NV")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        Spacer()
        BadgeView(text: "N3", style: .blue)
    }
    
    // Status indicator
    HStack {
        Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
        Text("Setlist Available")
            .font(.caption)
            .foregroundColor(.green)
    }
}
```

#### **Future Show Display** (Shows 24+):
```swift
// Same structure but with different status:
HStack {
    Image(systemName: "clock.circle")
        .foregroundColor(.orange)
    Text("Future Show - Setlist Not Yet Available")
        .font(.caption)
        .foregroundColor(.orange)
}
```

### 🎵 **Setlist Display Modes**

#### **Played Show Setlist**:
- Full setlist with pre-computed colors from server
- Maintains existing AttributedString formatting
- Scrollable within 300pt container
- Transition marks preserved

#### **Future Show Placeholder**:
```swift
VStack(spacing: 20) {
    Image(systemName: "calendar.circle")
        .font(.system(size: 60))
        .foregroundColor(.orange)
    
    Text("Show Not Yet Played")
        .font(.headline)
    
    Text("Scheduled for August 2, 2025")
        .font(.subheadline)
    
    Text("Check back after the show")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

## Detailed Implementation Plan

### **Component 1: TourTimelineSlider**

```swift
struct TourTimelineSlider: View {
    @Binding var selectedIndex: Int
    let totalShows: Int
    let playedShows: Int
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(height: 6)
                
                // Progress fill (only to played shows)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: playedProgressWidth(in: geometry))
                
                // Tick marks for all shows
                HStack(spacing: 0) {
                    ForEach(0..<totalShows, id: \.self) { index in
                        Circle()
                            .stroke(Color.blue, lineWidth: index < playedShows ? 0 : 1)
                            .background(
                                Circle().fill(index < playedShows ? Color.blue : Color.clear)
                            )
                            .frame(width: 8, height: 8)
                            .opacity(index < playedShows ? 1.0 : 0.3)
                    }
                }
                
                // Draggable thumb
                Circle()
                    .fill(selectedIndex < playedShows ? Color.green : Color.orange)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .frame(width: isDragging ? 36 : 32)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .shadow(radius: isDragging ? 8 : 4)
                    .offset(x: thumbOffset(in: geometry))
                    .animation(.spring(response: 0.3))
            }
        }
        .frame(height: 44)
        .gesture(dragGesture)
    }
    
    private func playedProgressWidth(in geometry: GeometryProxy) -> CGFloat {
        let totalWidth = geometry.size.width
        return (CGFloat(playedShows) / CGFloat(totalShows)) * totalWidth
    }
    
    private func thumbOffset(in geometry: GeometryProxy) -> CGFloat {
        let totalWidth = geometry.size.width
        return (CGFloat(selectedIndex) / CGFloat(max(1, totalShows - 1))) * totalWidth
    }
}
```

### **Component 2: ShowPreviewCard**

```swift
struct ShowPreviewCard: View {
    let show: TourShow?
    let isPlayed: Bool
    let venueRun: VenueRun?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let show = show {
                // Date and position row
                HStack {
                    VStack(alignment: .leading) {
                        Text(formattedDate(show.date))
                            .font(.headline)
                        Text(dayOfWeek(show.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    BadgeView(
                        text: "Show \(show.number)/\(show.totalShows)",
                        style: isPlayed ? .blue : .orange
                    )
                }
                
                // Venue row
                HStack {
                    VStack(alignment: .leading) {
                        Text(show.venue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(show.city), \(show.state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let venueRun = venueRun {
                        BadgeView(
                            text: "N\(venueRun.nightNumber)",
                            style: isPlayed ? .blue : .gray
                        )
                    }
                }
                
                // Status indicator
                HStack {
                    Image(systemName: isPlayed ? "checkmark.circle.fill" : "clock.circle")
                        .foregroundColor(isPlayed ? .green : .orange)
                    Text(isPlayed ? "Setlist Available" : "Future Show - Setlist Not Yet Available")
                        .font(.caption)
                        .foregroundColor(isPlayed ? .green : .orange)
                }
            }
        }
        .padding()
        .frame(height: 120) // Fixed height
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

### **Component 3: ShowSetlistCard**

```swift
struct ShowSetlistCard: View {
    let show: TourShow?
    let setlistData: ShowFileData?
    let isPlayed: Bool
    @ObservedObject var viewModel: LatestSetlistViewModel
    
    var body: some View {
        VStack {
            if isPlayed, let data = setlistData {
                // Played show: Display full setlist
                ScrollView {
                    CompactSetlistView(
                        setlistItems: viewModel.setlistItems,
                        viewModel: viewModel
                    )
                    .padding()
                }
            } else {
                // Future show: Display placeholder
                VStack(spacing: 20) {
                    Image(systemName: "calendar.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Show Not Yet Played")
                        .font(.headline)
                    
                    if let show = show {
                        Text("Scheduled for")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(formattedDate(show.date))
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    
                    Text("Check back after the show for the complete setlist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: 300) // Fixed height
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
```

### **Component 4: TourShowBrowserView (Main Container)**

```swift
struct TourShowBrowserView: View {
    @ObservedObject var viewModel: LatestSetlistViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Tour Header
            VStack(spacing: 4) {
                Text(viewModel.tourName)
                    .font(.headline)
                Text("\(viewModel.tourShows.count) Shows • \(viewModel.tourDateRange)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 40)
            
            // Show Preview Card
            ShowPreviewCard(
                show: viewModel.selectedShow,
                isPlayed: viewModel.isSelectedShowPlayed,
                venueRun: viewModel.selectedVenueRun
            )
            
            // Timeline Slider
            TourTimelineSlider(
                selectedIndex: $viewModel.selectedShowIndex,
                totalShows: viewModel.tourShows.count,
                playedShows: viewModel.playedShowsCount
            )
            .padding(.horizontal)
            
            // Setlist Display
            ShowSetlistCard(
                show: viewModel.selectedShow,
                setlistData: viewModel.selectedShowData,
                isPlayed: viewModel.isSelectedShowPlayed,
                viewModel: viewModel
            )
        }
        .padding()
        .onAppear {
            viewModel.initializeTourBrowser()
        }
    }
}
```

### **ViewModel Enhancement Strategy**

**Extend LatestSetlistViewModel**:

```swift
extension LatestSetlistViewModel {
    // MARK: - Tour Browser Properties
    @Published var selectedShowIndex: Int = 0
    @Published var tourShows: [TourDashboardData.TourDate] = []
    @Published var selectedShowData: ShowFileData?
    @Published var isLoadingShow: Bool = false
    
    // Cache management
    private var showCache: [String: ShowFileData] = [:]
    private let maxCacheSize = 10
    private var cacheOrder: [String] = []
    
    // Debouncing
    private var loadWorkItem: DispatchWorkItem?
    
    // MARK: - Computed Properties
    var selectedShow: TourDashboardData.TourDate? {
        guard selectedShowIndex < tourShows.count else { return nil }
        return tourShows[selectedShowIndex]
    }
    
    var isSelectedShowPlayed: Bool {
        selectedShow?.played ?? false
    }
    
    var playedShowsCount: Int {
        tourShows.filter { $0.played }.count
    }
    
    // MARK: - Tour Browser Methods
    func initializeTourBrowser() {
        Task {
            do {
                let dashboardData = try await TourDashboardDataClient.shared.fetchCurrentTourData()
                await MainActor.run {
                    self.tourShows = dashboardData.currentTour.tourDates
                    // Set to latest played show
                    if let latestIndex = tourShows.lastIndex(where: { $0.played }) {
                        self.selectedShowIndex = latestIndex
                        self.loadSelectedShow()
                    }
                }
            } catch {
                print("Failed to initialize tour browser: \(error)")
            }
        }
    }
    
    func selectShow(at index: Int) {
        selectedShowIndex = index
        
        // Cancel previous load
        loadWorkItem?.cancel()
        
        // Debounce loading with 500ms delay
        loadWorkItem = DispatchWorkItem { [weak self] in
            self?.loadSelectedShow()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: loadWorkItem!)
    }
    
    private func loadSelectedShow() {
        guard let show = selectedShow, show.played else {
            // Clear data for future shows
            selectedShowData = nil
            setlistItems = []
            return
        }
        
        // Check cache first
        if let cached = showCache[show.date] {
            applyShowData(cached)
            return
        }
        
        // Load from server
        Task {
            do {
                isLoadingShow = true
                let showData = try await TourDashboardDataClient.shared.fetchShowData(for: show.date)
                
                await MainActor.run {
                    self.cacheShow(showData, for: show.date)
                    self.applyShowData(showData)
                    self.isLoadingShow = false
                }
            } catch {
                print("Failed to load show: \(error)")
                isLoadingShow = false
            }
        }
    }
    
    private func cacheShow(_ data: ShowFileData, for date: String) {
        showCache[date] = data
        cacheOrder.append(date)
        
        // Evict oldest if cache exceeds limit
        if cacheOrder.count > maxCacheSize {
            let evicted = cacheOrder.removeFirst()
            showCache.removeValue(forKey: evicted)
        }
    }
    
    private func applyShowData(_ data: ShowFileData) {
        selectedShowData = data
        // Convert to existing models for compatibility
        let enhanced = TourDashboardDataClient.shared.convertToEnhancedSetlist(data)
        self.setlistItems = enhanced.setlistItems
        self.trackDurations = enhanced.trackDurations
        self.venueRunInfo = enhanced.venueRun
    }
}
```

## Data Flow Architecture

### **Initialization Flow**:
```
App Launch → TourShowBrowserView.onAppear()
    ↓
fetchCurrentTourData() → tour-dashboard.json
    ↓
Parse 23 tour dates with venues/played status
    ↓
Set selectedShowIndex to latest played (22)
    ↓
Load show-2025-07-27.json automatically
    ↓
Display complete setlist with colors
```

### **User Interaction Flow**:
```
User Drags Slider → Update selectedShowIndex
    ↓
Preview Card Updates Instantly (from tour dashboard)
    ↓
Start 500ms Debounce Timer
    ↓
If Played Show:
    → Check Cache
    → If cached: Display immediately
    → If not: Fetch /api/shows/[date]
    → Cache result
    → Display setlist with colors
    
If Future Show:
    → Clear setlist data
    → Show placeholder message
    → No server call
```

### **Caching Strategy**:
- **LRU Cache**: 10 most recent shows
- **Cache Key**: Show date (e.g., "2025-07-27")
- **Cache Value**: Complete ShowFileData
- **Eviction**: Remove oldest when limit exceeded
- **Preloading**: Adjacent shows loaded in background

## Integration with Existing Architecture

### **Dashboard Integration**:
```swift
// In TourDashboardView.swift
// Replace:
LatestShowHeroCard(viewModel: latestSetlistViewModel)

// With:
TourShowBrowserView(viewModel: latestSetlistViewModel)
```

### **Reusing Existing Components**:
- **CompactSetlistView**: Used directly for setlist display
- **BadgeView**: Used for venue run and show position badges
- **DateUtilities**: Used for date formatting
- **TourDashboardDataClient**: Used without modification
- **Color calculations**: All pre-computed on server, no iOS logic

### **Maintaining Compatibility**:
- ViewModel remains backward compatible
- Existing latest-only views continue working
- No changes to data models or API clients
- Same error handling patterns

## Performance Optimizations

### **Debouncing Implementation**:
```swift
private var loadWorkItem: DispatchWorkItem?

func handleSliderChange(_ newIndex: Int) {
    // Cancel previous load
    loadWorkItem?.cancel()
    
    // Update preview immediately
    selectedShowIndex = newIndex
    
    // Debounce actual loading
    loadWorkItem = DispatchWorkItem { [weak self] in
        self?.loadSelectedShow()
    }
    DispatchQueue.main.asyncAfter(
        deadline: .now() + 0.5,
        execute: loadWorkItem!
    )
}
```

### **Memory Management**:
- Fixed container heights prevent layout recalculation
- ScrollView reuses content views efficiently
- Cache limited to 10 shows (~2MB total)
- Weak self references prevent retain cycles

### **Network Optimization**:
- No calls during slider dragging
- Cached shows load instantly
- Parallel preloading of adjacent shows
- Request cancellation for rapid changes

## Accessibility Features

### **VoiceOver Support**:
```swift
TourTimelineSlider()
    .accessibilityLabel("Tour show selector")
    .accessibilityValue("Show \(selectedIndex + 1) of \(totalShows)")
    .accessibilityHint("Swipe up or down to change shows")
    .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment:
            selectedIndex = min(selectedIndex + 1, totalShows - 1)
        case .decrement:
            selectedIndex = max(selectedIndex - 1, 0)
        }
    }
```

### **Dynamic Type Support**:
- All text uses semantic font styles
- Layout adapts to font size changes
- Fixed heights accommodate larger text

### **Haptic Feedback**:
```swift
private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

func provideHapticFeedback() {
    impactGenerator.impactOccurred()
}
```

## Error Handling & Edge Cases

### **Network Failures**:
```swift
enum ShowLoadError: Error {
    case networkError
    case showNotFound
    case invalidData
}

// Graceful fallback
if error == .networkError && hasCachedShow {
    displayCachedShow()
    showStaleDataWarning()
} else {
    showErrorMessage("Unable to load show. Please try again.")
}
```

### **Tour State Variations**:
- **Empty Tour**: Show message "No shows scheduled"
- **All Future**: Allow browsing with all placeholders
- **Partial Tour**: Mix of played and future shows
- **Cancelled Shows**: Skip in timeline, adjust indices

### **Data Integrity**:
- Validate show dates against tour dashboard
- Handle missing venue run data gracefully
- Default to empty setlist if corrupt data
- Maintain UI stability despite data issues

## Implementation Phases

### **Phase 1: Core Components** (2-3 hours)
1. Create `TourTimelineSlider` with basic dragging
2. Build `ShowPreviewCard` with fixed layout
3. Implement `ShowSetlistCard` with dual modes
4. Test with mock data

### **Phase 2: ViewModel Integration** (2-3 hours)
1. Extend `LatestSetlistViewModel` with tour browser logic
2. Implement show selection and caching
3. Add debouncing mechanism
4. Connect to real data

### **Phase 3: Polish & Optimization** (1-2 hours)
1. Add haptic feedback
2. Implement accessibility features
3. Optimize performance
4. Add loading states and animations

### **Phase 4: Testing & Integration** (1-2 hours)
1. Replace dashboard component
2. Test with various tour states
3. Memory and performance profiling
4. Bug fixes and refinements

**Total Estimated Time**: 6-10 hours

## Critical Implementation Notes

### **Why Fixed Heights Matter**:
Without fixed heights, the UI would jump when switching between shows with different setlist lengths. A 15-song setlist vs 25-song setlist would cause a 200pt+ height change, creating a jarring experience. Fixed heights with internal scrolling solve this elegantly.

### **Why 500ms Debounce**:
This delay prevents server calls during rapid slider movements while keeping the interface responsive. Preview updates happen instantly (venue/date), but expensive operations (fetching/parsing JSON) wait until the user settles on a position.

### **Why Allow Future Show Access**:
Originally planned to block future shows, but allowing preview access provides better tour planning visibility. Users can see upcoming venues and dates without breaking the "no setlist until played" rule.

### **Why Reuse Existing Components**:
The current `CompactSetlistView` and color calculation logic work perfectly. By reusing these components, we maintain visual consistency and avoid duplicating complex formatting logic.

## Testing Checklist

### **Functional Tests**:
- [ ] Slider navigates all 23 shows
- [ ] Preview updates instantly while dragging
- [ ] Setlist loads after 500ms delay
- [ ] Cache works for previously viewed shows
- [ ] Future shows display placeholder correctly
- [ ] Venue run badges display properly
- [ ] Color-coded songs appear correctly
- [ ] Fixed heights prevent UI jumping

### **Performance Tests**:
- [ ] Show switching < 500ms
- [ ] Memory usage stays under 50MB
- [ ] No memory leaks after extended use
- [ ] Smooth 60fps slider interaction
- [ ] Network requests properly cancelled

### **Edge Case Tests**:
- [ ] Empty tour data handled
- [ ] Network failure with cache
- [ ] Corrupt show data
- [ ] Rapid slider movements
- [ ] Device rotation
- [ ] Dark mode appearance

## Summary

This comprehensive plan transforms Component A from a static latest-show display into a dynamic tour browser while:
- Maintaining the single-source architecture (zero runtime calculations)
- Preserving sub-200ms performance
- Solving UI stability through fixed-height containers
- Providing intuitive timeline visualization
- Supporting both played and future shows appropriately

The implementation leverages all existing infrastructure, requiring no changes to the data layer or API endpoints. The timeline slider provides the perfect metaphor for tour progression while the fixed-height architecture ensures a smooth, professional user experience.

**Document Version**: 1.0 Complete
**Ready for Implementation**: Yes
**Estimated Completion**: 6-10 hours