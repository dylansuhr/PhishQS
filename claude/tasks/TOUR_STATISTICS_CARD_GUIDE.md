# Tour Statistics Card Implementation Guide

This guide outlines the procedure for creating a new tour statistics card, using the **Songs Per Set** card as a reference implementation.

## Overview

Tour statistics cards display pre-computed data from the current Phish tour. The data flows through a pipeline:

```
Phish.net/Phish.in APIs → Server Calculator → tour-stats.json → Vercel API → iOS App
```

## Data Flow Architecture

### 1. Data Generation (Server-side)

**GitHub Actions** runs 3x daily (midnight, 4am, 4pm EDT) to:
1. Fetch latest show data from Phish.net API
2. Run all registered calculators
3. Update `Server/Data/tour-stats.json`
4. Auto-deploy to Vercel

### 2. Data Storage

All pre-computed statistics are stored in a single file:
- **Location**: `Server/Data/tour-stats.json`
- **Served by**: `/api/tour-statistics` endpoint
- **Cache**: 1 hour (`s-maxage=3600`)

### 3. Data Consumption (iOS)

The iOS app fetches from the Vercel API endpoint and decodes into Swift models.

---

## Step-by-Step Implementation

### Step 1: Create the Calculator (Server)

**File**: `Server/Services/StatisticsCalculators/[YourCalculator].js`

Calculators extend `BaseStatisticsCalculator` and implement two methods:

```javascript
import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';

export class SetSongStatsCalculator extends BaseStatisticsCalculator {
    constructor() {
        super();
        this.name = 'SetSongStatsCalculator';
    }

    // Called once per show during processing
    processShow(show, dataContainer) {
        // Extract and accumulate data from each show
        // Store intermediate results in dataContainer
    }

    // Called after all shows processed
    generateResults(dataContainer, tourName, context = {}) {
        // Compute final statistics from accumulated data
        // Return the result object
    }
}
```

**Example** (`SetSongStatsCalculator.js`):
- `processShow()`: Counts songs per set for each show
- `generateResults()`: Finds min/max per set type, handles ties

### Step 2: Register the Calculator

**File**: `Server/Services/StatisticsRegistry.js`

```javascript
import { SetSongStatsCalculator } from './StatisticsCalculators/SetSongStatsCalculator.js';

// In registerBuiltInCalculators():
this.registerCalculator('setSongStats', {
    name: 'Songs Per Set',
    calculatorClass: SetSongStatsCalculator,
    resultType: 'SetSongStats',
    enabled: true,
    priority: 5  // Lower = runs first
});
```

### Step 3: Update TourStatisticsService

**File**: `Server/Services/TourStatisticsService.js`

Add the new stat to the `TourSongStatistics` constructor call:

```javascript
const setSongStats = calculatorResults.setSongStats || {};

return new TourSongStatistics(
    longestSongs,
    rarestSongs,
    mostPlayedSongs,
    tourName,
    mostCommonSongsNotPlayed,
    setSongStats  // Add new stat here
);
```

### Step 4: Update TourStatistics Model (Server)

**File**: `Server/Models/TourStatistics.js`

```javascript
constructor(longestSongs, rarestSongs, mostPlayedSongs, tourName,
            mostCommonSongsNotPlayed = [], setSongStats = {}) {
    // ...existing fields...
    this.setSongStats = setSongStats;
}
```

### Step 5: Generate and Verify Data

```bash
# Generate new statistics
npm run generate-stats

# Verify the JSON structure
cat Server/Data/tour-stats.json | jq '.setSongStats'
```

**Expected output structure** (Songs Per Set example):
```json
{
  "setSongStats": {
    "1": {
      "min": { "count": 7, "shows": [{ "date": "...", "venue": "...", ... }] },
      "max": { "count": 11, "shows": [...] }
    },
    "2": { "min": {...}, "max": {...} },
    "e": { "min": {...}, "max": {...} }
  }
}
```

### Step 6: Add iOS Models

**File**: `Models/TourStatisticsModels.swift`

```swift
// Add new model structs
struct SetSongShow: Codable {
    let date: String
    let venue: String
    let city: String
    let state: String
    let venueRun: String?

    // Computed properties for display
    var formattedDate: String { ... }
    var venueDisplayText: String { ... }
}

struct SetSongExtreme: Codable {
    let count: Int
    let shows: [SetSongShow]
}

struct SetSongStats: Codable {
    let min: SetSongExtreme
    let max: SetSongExtreme
}

// Add to TourSongStatistics:
let setSongStats: [String: SetSongStats]?
```

### Step 7: Create the Card UI

**File**: `Features/Dashboard/[YourCard].swift`

Follow existing card patterns:
- White background, 16pt padding, 12pt corner radius
- Header: `.subheadline`, `.semibold`, `.secondary`, `.uppercase`
- Use `ExpandableCardButton` for collapsible content
- Match colors with other cards (indigo for this card)

```swift
struct SongsPerSetCard: View {
    let setSongStats: [String: SetSongStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("SONGS PER SET")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            // Content...
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
```

### Step 8: Add Card to Dashboard

**File**: `Features/Dashboard/TourStatisticsCards.swift`

```swift
var body: some View {
    if let stats = statistics, stats.hasData {
        VStack(alignment: .leading, spacing: 16) {
            LongestSongsCard(...)

            // Insert new card in desired position
            if let setSongStats = stats.setSongStats, !setSongStats.isEmpty {
                SongsPerSetCard(setSongStats: setSongStats)
            }

            RarestSongsCard(...)
            // ...
        }
    }
}
```

### Step 9: Deploy

```bash
# Deploy to Vercel
npm run deploy

# Verify API returns new data
curl -s "https://phish-qs.vercel.app/api/tour-statistics" | jq '.setSongStats'
```

---

## File Summary

| Layer | File | Purpose |
|-------|------|---------|
| Server | `StatisticsCalculators/[Name]Calculator.js` | Compute statistics |
| Server | `StatisticsRegistry.js` | Register calculator |
| Server | `TourStatisticsService.js` | Orchestrate calculation |
| Server | `Models/TourStatistics.js` | Server model |
| Server | `Data/tour-stats.json` | Pre-computed data |
| iOS | `Models/TourStatisticsModels.swift` | Swift models |
| iOS | `Features/Dashboard/[Name]Card.swift` | Card UI |
| iOS | `Features/Dashboard/TourStatisticsCards.swift` | Card integration |

---

## Automatic Updates

Once deployed, the card updates automatically:

1. **GitHub Actions** (`update-tour-data.yml`) runs 3x daily
2. Checks for new shows via Phish.net API
3. If new data detected:
   - Runs `npm run generate-stats`
   - Commits updated `tour-stats.json`
   - Vercel auto-deploys on commit
4. iOS app fetches fresh data on next launch

---

## Testing Checklist

- [ ] `npm run generate-stats` completes without errors
- [ ] `tour-stats.json` contains expected structure
- [ ] iOS build succeeds
- [ ] Card displays correctly with real data
- [ ] Card handles empty/missing data gracefully
- [ ] `npm run deploy` succeeds
- [ ] API endpoint returns new data

---

## Example: Songs Per Set Card

**Branch**: `set-length`

**Commits**:
1. `Add Songs Per Set metric card` - Full pipeline (server + iOS)
2. `Add tabbed navigation and collapsible ties` - UI enhancements

**Features**:
- Tabbed navigation (Set 1, Set 2, Encore always visible; Set 3 dynamic)
- Collapsible tie lists (show first 2, "+ X more" expands)
- Haptic feedback and smooth animations
