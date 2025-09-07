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

### ✅ PHASE 1: Create Update Script [CURRENT FOCUS]
**Status: In Progress**

Create the Node.js script that generates and updates the tour dashboard JSON file.

**Key Tasks:**
1. Create `Server/Scripts/update-tour-dashboard.js`
2. Implement API data fetching logic
3. Build JSON structure generation
4. Add update detection logic
5. Test locally with real API data

---

### 📋 PHASE 2: GitHub Actions Automation [FUTURE]
**Status: Not Started**

Automate the update process using GitHub Actions.

**Planned Implementation:**
- Create `.github/workflows/update-tour-dashboard.yml`
- Schedule runs every 2 hours during tour season
- Auto-commit changes when new show detected
- Add manual trigger option

---

### 📋 PHASE 3: Create API Endpoint [FUTURE]
**Status: Not Started**

Create server endpoint to serve the tour dashboard data.

**Planned Implementation:**
- Create `Server/API/tour-dashboard.js`
- Serve JSON file with appropriate caching headers
- Add to Vercel deployment configuration

---

### 📋 PHASE 4: iOS Client Updates [FUTURE]
**Status: Not Started**

Update iOS components to consume the single source of truth.

**Planned Implementation:**
- Create `TourDashboardDataClient.swift`
- Update Component A to use tour dashboard for latest show
- Update Component B to reference tour dashboard for context
- Add fallback mechanisms

## Phase 1 Implementation Details [CURRENT WORK]

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