# Plan: Tour Debuts Dashboard Card

## Goal
Create a new Tour Debuts dashboard card that lists songs that debuted (first time ever played) during the current tour. The card follows the same UI/styling pattern as "Biggest Song Gaps" (RarestSongsCard) and is positioned directly above it in the dashboard.

## Detection Logic

**Key Finding**: From analysis of 429 historical debut footnotes across 11 years:
- Pattern: `footnote.toLowerCase().startsWith('debut')` safely captures:
  - "Phish debut..." (161 instances)
  - "Debut." (165 instances)
- Side project debuts ("TAB debut", "Mike Gordon debut") are already filtered out because they have different `artist_name` values in the setlist data

## Implementation Steps

### Step 1: Create Calculator (Server)

**File**: `Server/Services/StatisticsCalculators/DebutsCalculator.js`

```javascript
import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';

export class DebutsCalculator extends BaseStatisticsCalculator {
    constructor(config = {}) {
        super(config);
        this.calculatorType = 'Debuts';
    }

    initializeDataContainer() {
        return {
            debuts: [],
            latestShowDate: null
        };
    }

    processShow(show, dataContainer) {
        // Track latest show date for empty state
        if (!dataContainer.latestShowDate || show.showDate > dataContainer.latestShowDate) {
            dataContainer.latestShowDate = show.showDate;
        }

        // Check each song's footnote for debut
        if (show.setlistItems && Array.isArray(show.setlistItems)) {
            show.setlistItems.forEach(item => {
                const footnote = (item.footnote || '').toLowerCase();
                if (footnote.startsWith('debut') || footnote.startsWith('phish debut')) {
                    dataContainer.debuts.push({
                        songId: item.songid,
                        songName: item.song,
                        footnote: item.footnote,
                        showDate: show.showDate,
                        venue: show.setlistItems?.[0]?.venue,
                        venueRun: show.venueRun,
                        city: show.showVenueInfo?.city,
                        state: show.showVenueInfo?.state,
                        tourPosition: show.tourPosition
                    });
                }
            });
        }
    }

    generateResults(dataContainer, tourName, context = {}) {
        const { debuts, latestShowDate } = dataContainer;

        // Sort by date (most recent first), then by song name
        const sortedDebuts = debuts.sort((a, b) => {
            if (a.showDate !== b.showDate) return b.showDate.localeCompare(a.showDate);
            return a.songName.localeCompare(b.songName);
        });

        return { songs: sortedDebuts, latestShowDate };
    }
}
```

### Step 2: Register Calculator

**File**: `Server/Services/StatisticsRegistry.js`

Add import and registration (priority 1.5 = between longestSongs and rarestSongs):
```javascript
import { DebutsCalculator } from './StatisticsCalculators/DebutsCalculator.js';

this.registerCalculator('debuts', {
    name: 'Tour Debuts',
    description: 'Identifies songs debuted during the current tour',
    dataSource: 'Phish.net setlist footnotes',
    calculatorClass: DebutsCalculator,
    resultType: 'DebutsStats',
    enabled: true,
    priority: 1.5
});
```

### Step 3: Update TourStatisticsService

**File**: `Server/Services/TourStatisticsService.js`

Add debuts to the result construction:
```javascript
const debuts = calculatorResults.debuts || { songs: [], latestShowDate: null };
```

### Step 4: Update Server Model

**File**: `Server/Models/TourStatistics.js`

Add to TourSongStatistics constructor and include `debuts` field.

### Step 5: Add iOS Models

**File**: `Models/TourStatisticsModels.swift`

```swift
/// Debut song information for tour statistics
struct DebutInfo: Codable, Identifiable {
    let id: Int
    let songId: Int
    let songName: String
    let footnote: String
    let showDate: String
    let venue: String?
    let venueRun: VenueRun?
    let city: String?
    let state: String?
    let tourPosition: TourShowPosition?

    var formattedDate: String {
        DateUtilities.formatDateForDisplay(showDate) ?? showDate
    }

    var venueDisplayText: String? {
        guard let venue = venue else { return nil }
        if let venueRun = venueRun, venueRun.totalNights > 1 {
            return "\(venue), N\(venueRun.nightNumber)"
        }
        return venue
    }
}

struct DebutsStats: Codable {
    let songs: [DebutInfo]
    let latestShowDate: String?
}
```

Add to TourSongStatistics:
```swift
let debuts: DebutsStats?
```

### Step 6: Create Card UI

**File**: `Features/Dashboard/DebutsCard.swift`

- Use MetricCard wrapper with title "Tour Debuts"
- Purple accent color (distinguishes from orange gaps, blue durations, green counts)
- "DEBUT" pill badge on right side of each row
- Empty state: "No debuts through [formatted date]" (italic, secondary)
- **Shows top 3 debuts by default**, expands to 10 max with "Show More" button
- Uses same `ExpandableCardButton` pattern as RarestSongsCard:
  ```swift
  ForEach(Array(debuts.songs.prefix(isExpanded ? 10 : 3).enumerated()), ...)
  ExpandableCardButton(itemCount: debuts.songs.count, threshold: 3, ...)
  ```

### Step 7: Add Card to Dashboard

**File**: `Features/Dashboard/TourStatisticsCards.swift`

Insert DebutsCard above RarestSongsCard:
```swift
if let debuts = stats.debuts {
    DebutsCard(debuts: debuts)
}
RarestSongsCard(songs: stats.rarestSongs)
```

## Files Summary

| Layer | File | Action |
|-------|------|--------|
| Server | `Server/Services/StatisticsCalculators/DebutsCalculator.js` | CREATE |
| Server | `Server/Services/StatisticsRegistry.js` | MODIFY - add import + registration |
| Server | `Server/Services/TourStatisticsService.js` | MODIFY - add debuts to results |
| Server | `Server/Models/TourStatistics.js` | MODIFY - add DebutsStats handling |
| iOS | `Models/TourStatisticsModels.swift` | MODIFY - add DebutInfo, DebutsStats |
| iOS | `Features/Dashboard/DebutsCard.swift` | CREATE |
| iOS | `Features/Dashboard/TourStatisticsCards.swift` | MODIFY - add card to layout |

## Expected JSON Output

```json
{
  "debuts": {
    "songs": [
      {
        "songId": 123,
        "songName": "New Song",
        "footnote": "Phish debut.",
        "showDate": "2025-07-15",
        "venue": "Madison Square Garden",
        "venueRun": { "nightNumber": 1, "totalNights": 4 },
        "city": "New York",
        "state": "NY"
      }
    ],
    "latestShowDate": "2025-07-20"
  }
}
```

## Testing Checklist

- [ ] `npm run generate-stats` completes without errors
- [ ] `tour-stats.json` contains `debuts` object
- [ ] iOS build succeeds
- [ ] Card displays debuts (or empty state with date)
- [ ] Expand/collapse works smoothly
- [ ] `npm run deploy` succeeds
