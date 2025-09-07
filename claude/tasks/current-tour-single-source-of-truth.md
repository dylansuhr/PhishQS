# Current Tour Single Source of Truth

## Project Overview

### Feature Name
**Current Tour Single Source of Truth**

### Summary
Create a single JSON file that serves as the dynamic reference point for both Component A (Tour Setlist Browser) and Component B (Tour Statistics Display). This file will be automatically updated via GitHub Actions and will eliminate redundant API calls while ensuring data consistency across components.

### Goals
1. **Maintain Component Separation**: Keep Component A and Component B as independent components
2. **Reduce API Calls**: Have both components pull data from a single source for efficiency
3. **Single State Reference**: The tour dashboard state should be read from a single file
4. **Automated Updates**: GitHub Actions will keep the data current based on latest tour results

### Current Problems
- Component A makes real-time iOS API calls to phish.net and phish.in
- Component B pulls pre-computed data from the server
- Multiple API calls for the same information
- Potential data inconsistency between components
- Inefficient use of network resources

### Proposed Solution Benefits
- Single source of truth for tour information
- Dramatic reduction in API calls (90%+ reduction)
- Consistent data across all components
- Faster app loading and better performance
- Simplified debugging and maintenance

## Single Source File Structure

### File: `api/Data/tour-dashboard-data.json`

```json
{
  "currentTour": {
    "name": "2025 Summer Tour",
    "year": "2025", 
    "totalShows": 31,
    "playedShows": 20,
    "startDate": "2025-06-20",
    "endDate": "2025-08-11",
    "tourDates": [
      {
        "date": "2025-06-20",
        "venue": "Deer Creek",
        "city": "Noblesville", 
        "state": "IN",
        "played": true,
        "setlistAvailable": true
      },
      {
        "date": "2025-06-21",
        "venue": "Deer Creek",
        "city": "Noblesville",
        "state": "IN", 
        "played": true,
        "setlistAvailable": true
      },
      // ... all tour dates with played/future status ...
      {
        "date": "2025-08-11",
        "venue": "Dick's Sporting Goods Park",
        "city": "Commerce City",
        "state": "CO",
        "played": false,
        "setlistAvailable": false
      }
    ]
  },
  "latestShow": {
    "date": "2025-07-20",
    "venue": "Xfinity Center",
    "city": "Mansfield",
    "state": "MA",
    "tourPosition": {
      "showNumber": 20,
      "totalShows": 31,
      "tourName": "2025 Summer Tour"
    },
    "venueRun": {
      "nightNumber": 2,
      "totalNights": 2,
      "dates": ["2025-07-19", "2025-07-20"]
    }
  },
  "futureTours": [
    {
      "name": "2025 NYE Run",
      "year": "2025",
      "startDate": "2025-12-28",
      "endDate": "2025-12-31",
      "totalShows": 4,
      "tourDates": [
        {
          "date": "2025-12-28",
          "venue": "Madison Square Garden",
          "city": "New York",
          "state": "NY",
          "played": false
        }
        // ... other NYE dates
      ]
    }
  ],
  "metadata": {
    "lastUpdated": "2025-01-15T10:30:00Z",
    "dataVersion": "1.0",
    "updateReason": "new_show", // "new_show", "tour_change", "manual_update", "scheduled_update"
    "nextShow": {
      "date": "2025-07-22",
      "venue": "Saratoga Performing Arts Center",
      "city": "Saratoga Springs",
      "state": "NY"
    }
  }
}
```

### Field Descriptions

- **currentTour**: Active tour information
  - `name`: Official tour name from phish.net
  - `totalShows`: Total scheduled shows in tour
  - `playedShows`: Number of shows already performed
  - `tourDates`: Complete list of all tour dates with status

- **latestShow**: Most recent performed show
  - Contains venue, location, and tour context
  - Includes venue run information for multi-night stands

- **futureTours**: Upcoming announced tours
  - Same structure as currentTour but all shows marked as not played

- **metadata**: File management information
  - `lastUpdated`: ISO timestamp of last update
  - `updateReason`: Why the file was updated
  - `nextShow`: Quick reference to next scheduled show

## Implementation Phases

### ✅ PHASE 1: Create Update Script [COMPLETED]
**Status: Completed**

Create the Node.js script that generates and updates the tour dashboard JSON file.

**Completed Tasks:**
1. ✅ Create `Server/Scripts/update-tour-dashboard.js`
2. ✅ Implement API data fetching logic
3. ✅ Build JSON structure generation
4. ✅ Add update detection logic
5. ✅ Test locally with real API data

---

### ✅ PHASE 2: Hybrid Architecture with Individual Show Files [COMPLETED]
**Status: Completed**

✅ **Successfully implemented hybrid system with lightweight control file plus individual show files.**

**Architecture Overview:**
- **Control File**: `api/Data/tour-dashboard-data.json` - Lightweight orchestration file with tour metadata and show references
- **Individual Show Files**: `api/Data/tours/2025-early-summer-tour/show-YYYY-MM-DD.json` - Complete setlist and duration data for each show (23 files)
- **Organized Structure**: Tour-specific directory structure for scalability

**Completed Tasks:**
1. ✅ Create control file generation script (`update-tour-dashboard.js`)
2. ✅ Update generate-stats.js to use control file instead of making API calls (zero API calls achieved)
3. ✅ Create initialization script for all 23 show files (`quick-initialize-remaining-shows.js`)
4. ✅ Generate all 23 individual show files with complete data
5. ✅ Remove fallback mechanisms for explicit error handling
6. ✅ Validate identical statistical results (Component B 100% functional)

**Component B Achievement:**
- **Zero API calls** for tour statistics generation
- **Identical results** to previous API-based approach
- **97% performance improvement** (140ms vs 60+ second execution)
- **All 23 shows processed** successfully with complete data

**Smart Flag System:**
The control file includes metadata flags for intelligent updates:
- **High-level tracking**: `lastAPICheck`, `latestShowFromAPI`, `pendingDurationChecks`
- **Individual show flags**: `exists`, `lastUpdated`, `durationsAvailable`, `dataComplete`, `needsUpdate`
- **Update lifecycle**: Handles scenario where setlist data arrives immediately but Phish.in duration data comes days later

---

### 📋 PHASE 3: GitHub Actions Automation [FUTURE]
**Status: Not Started**

Automate the update process using GitHub Actions with smart update detection.

**Planned Implementation:**
- Create `.github/workflows/update-tour-dashboard.yml`
- Schedule runs every 2 hours during tour season
- Quick update checks using metadata flags (5-10 seconds vs full processing)
- Auto-commit changes when new data detected
- Add manual trigger option

---

### 📋 PHASE 4: Create API Endpoint [FUTURE]
**Status: Not Started**

Create server endpoint to serve the tour dashboard data.

**Planned Implementation:**
- Create `Server/API/tour-dashboard.js`
- Serve JSON files with appropriate caching headers
- Add to Vercel deployment configuration
- Handle both control file and individual show file requests

---

### 📋 PHASE 5: iOS Client Updates [FUTURE]
**Status: Not Started**

Update iOS components to consume the single source of truth.

**Planned Implementation:**
- Create `TourDashboardDataClient.swift`
- Update Component A to use tour dashboard for latest show
- Update Component B to reference tour dashboard for context
- Add fallback mechanisms

## Phase 2 Implementation Details [CURRENT WORK]

### Hybrid Architecture Overview

The hybrid system separates orchestration data from detailed show data:

#### Control File: `api/Data/tour-dashboard-data.json`
**Purpose**: Lightweight orchestration and smart update detection
**Size**: ~10-15KB (manageable for frequent updates)

```json
{
  "currentTour": {
    "name": "2025 Early Summer Tour",
    "year": "2025",
    "totalShows": 23,
    "playedShows": 23,
    "startDate": "2025-06-20", 
    "endDate": "2025-07-27",
    "tourDates": [
      {
        "date": "2025-06-20",
        "venue": "SNHU Arena",
        "city": "Manchester",
        "state": "NH", 
        "played": true,
        "showNumber": 1,
        "showFile": "shows/show-2025-06-20.json"
      }
      // ... other dates
    ]
  },
  "latestShow": {
    "date": "2025-07-27",
    "venue": "Broadview Stage at SPAC",
    "city": "Saratoga Springs",
    "state": "NY",
    "tourPosition": {
      "showNumber": 23,
      "totalShows": 23,
      "tourName": "2025 Early Summer Tour"
    }
  },
  "updateTracking": {
    "lastAPICheck": "2025-09-07T16:37:46.927Z",
    "latestShowFromAPI": "2025-07-27",
    "pendingDurationChecks": ["2025-07-25", "2025-07-26"],
    "individualShows": {
      "2025-06-20": {
        "exists": true,
        "lastUpdated": "2025-06-21T08:00:00Z",
        "durationsAvailable": true,
        "dataComplete": true,
        "needsUpdate": false
      },
      "2025-07-27": {
        "exists": true,
        "lastUpdated": "2025-07-27T23:30:00Z", 
        "durationsAvailable": false,
        "dataComplete": false,
        "needsUpdate": true
      }
    }
  }
}
```

#### Individual Show Files: `api/Data/shows/show-YYYY-MM-DD.json`
**Purpose**: Complete setlist and duration data for each show
**Size**: ~5-15KB per show (depending on setlist length)
**Total**: ~115-345KB for 23-show tour

```json
{
  "showDate": "2025-06-20",
  "venue": "SNHU Arena",
  "city": "Manchester", 
  "state": "NH",
  "tourPosition": {
    "showNumber": 1,
    "totalShows": 23,
    "tourName": "2025 Early Summer Tour"
  },
  "venueRun": {
    "nightNumber": 1,
    "totalNights": 3,
    "dates": ["2025-06-20", "2025-06-21", "2025-06-22"]
  },
  "setlistItems": [
    {
      "songName": "Wilson",
      "transition": ">", 
      "set": "1",
      "position": 1
    }
    // ... complete setlist
  ],
  "trackDurations": [
    {
      "id": "wilson_2025-06-20_1_1",
      "songName": "Wilson",
      "songId": 123,
      "durationSeconds": 245,
      "showDate": "2025-06-20",
      "setNumber": "1",
      "venue": "SNHU Arena",
      "city": "Manchester",
      "state": "NH",
      "tourPosition": { /* tour context */ }
    }
    // ... all track durations with color gradients pre-calculated
  ],
  "songGaps": [
    {
      "songId": 123,
      "songName": "Wilson", 
      "gap": 15,
      "lastPlayed": "2024-12-31",
      "timesPlayed": 1432,
      "tourVenue": "SNHU Arena"
      // ... gap information
    }
    // ... all song gaps
  ],
  "metadata": {
    "setlistSource": "phishnet",
    "durationsSource": "phishin", 
    "lastUpdated": "2025-06-21T08:00:00Z",
    "dataComplete": true
  }
}
```

### Smart Update Detection Logic

#### Flag Lifecycle Example:
**Scenario**: New show 2025-07-27 gets played

1. **Immediate after show**: 
   - Setlist data available on Phish.net within hours
   - Duration data not yet available on Phish.in (typically 2-3 days delay)
   
2. **Control file flags after initial update**:
   ```json
   "2025-07-27": {
     "exists": true,
     "lastUpdated": "2025-07-27T23:30:00Z",
     "durationsAvailable": false, 
     "dataComplete": false,
     "needsUpdate": true
   }
   ```

3. **GitHub Actions runs every 2 hours**:
   - Checks `needsUpdate: true` shows
   - Quick API check for duration data availability
   - If still unavailable, skips full processing (saves 55+ seconds)
   - Updates `lastUpdated` timestamp

4. **Duration data becomes available** (2-3 days later):
   - GitHub Actions detects Phish.in has duration data
   - Updates individual show file with complete data
   - Flags updated:
   ```json
   "2025-07-27": {
     "exists": true,
     "lastUpdated": "2025-07-30T14:22:00Z",
     "durationsAvailable": true,
     "dataComplete": true, 
     "needsUpdate": false
   }
   ```

### Key Implementation Files

#### 1. Update generate-stats.js to use control file
**File**: `Server/Scripts/generate-stats.js`
**Changes needed**:
- Replace API calls with control file reading
- Read individual show files for statistical calculations
- Maintain exact same output format
- Add error handling for missing show files

#### 2. Create show files initialization script
**File**: `Server/Scripts/initialize-tour-shows.js` 
**Purpose**: Generate all 23 individual show files for current tour
**Features**:
- Create complete show files with current API data
- Set appropriate flags in control file
- Handle partial data scenarios (setlist available, durations pending)

#### 3. Smart update detection script
**File**: `Server/Scripts/smart-update-check.js`
**Purpose**: Quick update detection for GitHub Actions
**Features**:
- 5-10 second execution time (vs 60+ seconds full processing)
- Check only shows marked with `needsUpdate: true`
- Update flags based on API availability
- Trigger full processing only when necessary

### Component B Integration

#### Current generate-stats.js behavior:
```javascript
// BEFORE: Makes own API calls
const year2025Shows = await enhancedService.phishNetClient.fetchShows('2025');
const tourName = '2025 Summer Tour';
const allTourShows = await enhancedService.collectTourData(tourName, latestShow.showdate);
```

#### Updated generate-stats.js behavior:
```javascript
// AFTER: Reads from control file + individual show files
const controlFile = JSON.parse(readFileSync('api/Data/tour-dashboard-data.json'));
const tourName = controlFile.currentTour.name;
const allTourShows = [];

for (const tourDate of controlFile.currentTour.tourDates) {
  if (tourDate.played && tourDate.showFile) {
    const showData = JSON.parse(readFileSync(`api/Data/${tourDate.showFile}`));
    allTourShows.push(showData);
  }
}
```

**Benefits**:
- Zero API calls from Component B (100% reduction)
- Consistent data with Component A
- Faster execution (no network latency)
- Reliable data availability

## Phase 1 Implementation Details [COMPLETED]

### File: `Server/Scripts/update-tour-dashboard.js`

#### 1. Setup and Dependencies
```javascript
import { PhishNetAPIClient } from '../Services/PhishNetAPIClient.js';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync, writeFileSync, existsSync } from 'fs';
```

#### 2. Main Update Logic

**Step 1: Fetch Current Year Shows**
- Get all shows for current year from Phish.net API
- Filter to official Phish shows only
- Sort by date

**Step 2: Identify Current Tour**
- Find the most recent played show
- Determine which tour it belongs to
- Get all shows for that tour

**Step 3: Build Tour Dates Array**
- Mark each show as played/not played
- Include venue and location information
- Calculate show numbers within tour

**Step 4: Identify Latest Show**
- Find most recent show with setlist data
- Calculate tour position
- Determine venue run information

**Step 5: Find Future Tours**
- Identify tours that haven't started yet
- Include all scheduled dates

**Step 6: Update Detection**
```javascript
function shouldUpdate(existingData, newData) {
  // Update if:
  // 1. File doesn't exist
  // 2. Latest show date changed
  // 3. Tour changed
  // 4. Number of played shows changed
  // 5. Future tours added/modified
}
```

**Step 7: Write JSON File**
- Only write if update is needed
- Include metadata with reason
- Pretty-print for readability

#### 3. Error Handling
- Graceful API failure handling
- Validation of data completeness
- Logging for debugging

#### 4. Testing Approach
```bash
# Run locally
node Server/Scripts/update-tour-dashboard.js

# Check output
cat api/Data/tour-dashboard-data.json
```

### Acceptance Criteria for Phase 1

1. ✅ Script successfully fetches data from Phish.net API
2. ✅ Generates correctly structured JSON file
3. ✅ Accurately identifies current tour and latest show
4. ✅ Properly marks shows as played/not played
5. ✅ Includes venue run information when applicable
6. ✅ Only updates file when changes detected
7. ✅ Handles API errors gracefully
8. ✅ Produces valid JSON that can be parsed

## Data Flow After Full Implementation

```
Phish.net API
     ↓
GitHub Actions (every 2 hours)
     ↓
update-tour-dashboard.js
     ↓
tour-dashboard-data.json (committed to repo)
     ↓
Served via API endpoint
     ↓
┌──────────────┬──────────────┐
│ Component A  │ Component B  │
│ (Latest Show)│ (Statistics) │
└──────────────┴──────────────┘
```

## Success Metrics

### Phase 1 Metrics
- Script execution time < 5 seconds
- Accurate tour identification 100% of the time
- Correct show played/not played status

### Overall Project Metrics
- 90%+ reduction in API calls from iOS app
- App startup time improvement of 50%+
- Zero data inconsistencies between components
- 99.9% uptime for automated updates

## Risk Mitigation

### Phase 1 Risks
- **Risk**: API rate limiting
  - **Mitigation**: Implement request throttling and caching
  
- **Risk**: Incomplete tour data
  - **Mitigation**: Validation checks and fallback to previous data

### Overall Project Risks
- **Risk**: GitHub Actions failures
  - **Mitigation**: Manual trigger option, monitoring alerts
  
- **Risk**: Breaking changes in APIs
  - **Mitigation**: Version checking, graceful degradation

## Progress Tracking

### Current Sprint (Phase 1)
- [x] Create task documentation
- [ ] Implement update-tour-dashboard.js script
- [ ] Test with real API data
- [ ] Validate JSON structure
- [ ] Document script usage

### Future Sprints
- [ ] Phase 2: GitHub Actions setup
- [ ] Phase 3: API endpoint creation
- [ ] Phase 4: iOS client updates

## Notes

- This approach maintains the independence of Component A and Component B while providing a shared data foundation
- The simple JSON structure is intentionally minimal to reduce complexity
- Future enhancements can add more data fields without breaking existing functionality
- The update script is designed to be run both manually and automatically

## References

- Original feature request: `/Users/dylansuhr/Downloads/claude_code_feature_change_working_doc.md`
- Current Component A: `Features/LatestSetlist/LatestSetlistViewModel.swift`
- Current Component B: `Services/Core/TourStatisticsAPIClient.swift`
- Existing stats generation: `Server/Scripts/generate-stats.js`