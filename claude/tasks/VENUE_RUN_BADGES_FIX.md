# Venue Run Badges and Tour Position Indicators Fix

## Problem Statement
Component A (Tour Setlist Browser) is not displaying:
- **Venue run badges** (N1/N2/N3 for multi-night runs)
- **Tour position indicators** (Show X/23 format)

These features historically worked but are currently broken despite documentation claiming they function correctly.

## Critical Discovery from Debug Logs
```
🎪 PhishNetTourService.getTourContext for 2025-07-27
   ⚠️  No tour name found for 2025-07-27
```

**ROOT CAUSE**: The `getTourNameForShow()` method is returning `nil`, which causes the entire tour context flow to fail. Without a tour name, the system cannot:
1. Fetch tour shows
2. Calculate venue runs
3. Determine tour positions

## Investigation Timeline

### 1. Initial Discovery
- User reported venue run badges and tour position indicators not displaying
- Found hardcoded "2025 Summer Tour" throughout codebase (should be "2025 Early Summer Tour")
- Tour had 31 shows hardcoded, actual tour has 23 shows

### 2. Server-Side Fixes (COMPLETED)
- Fixed tour name in multiple server files
- Added missing `tourYear` field to `TourShowPosition` objects
- Regenerated and deployed corrected tour statistics
- Server now correctly returns tour data with proper tour name

### 3. iOS Model Updates (COMPLETED)
- Updated `Show` model to include venue fields:
  ```swift
  struct Show: Codable {
      let showyear: String
      let showdate: String  
      let artist_name: String
      let tour_name: String?    // Optional tour name
      let venue: String?        // Added (optional)
      let city: String?         // Added (optional)
      let state: String?        // Added (optional)
  }
  ```

### 4. Venue Run Calculation (COMPLETED)
- Implemented `calculateVenueRuns()` in `PhishNetTourService.swift`
- Logic groups consecutive shows by venue
- Creates `VenueRun` objects for multi-night runs
- Added comprehensive debug logging

## Current Status

### What Works ✅
- Server API returns correct tour statistics
- Tour statistics dashboard displays correct tour name
- iOS app compiles without errors
- Debug logging is in place

### What's Still Broken ❌
- `getTourNameForShow()` returns `nil` for show date "2025-07-27"
- No venue runs or tour positions display in UI
- Tour context chain fails at the first step

## Root Cause Analysis

The issue appears to be in how the iOS app fetches and decodes Show data from Phish.net API:

1. **API Response Issue**: The Phish.net API response may not include the `tour_name` field for individual shows
2. **Field Name Mismatch**: The API might use a different field name (e.g., `tourname` vs `tour_name`)
3. **Endpoint Difference**: iOS might be using a different API endpoint than the server

### Evidence from Debug Logs
```
🎪 PhishNetTourService.getTourContext for 2025-07-27
   ⚠️  No tour name found for 2025-07-27
```

This indicates `getTourNameForShow()` → `fetchAllShowsForYear()` → `extractTourFromShow()` chain is failing.

## Code Flow Analysis

```swift
// PhishNetTourService.swift
func getTourContext(for showDate: String) {
    // FAILS HERE - returns nil
    guard let tourName = try await getTourNameForShow(date: showDate) else {
        return (nil, nil)
    }
    // Never reaches here...
    let tourShows = try await fetchTourShows(year: year, tourName: tourName)
    let venueRun = getVenueRun(for: showDate, in: tourShows)
}

func getTourNameForShow(date: String) {
    let allYearShows = try await fetchAllShowsForYear(year)
    guard let show = allYearShows.first(where: { $0.showdate == date }) else {
        return nil  // Show found but...
    }
    return extractTourFromShow(show)  // Returns show.tour_name which is nil
}
```

## Solution Approach

### Immediate Fix Needed
1. **Verify API Response Format**
   - Check actual Phish.net API response for field names
   - Confirm if `tour_name` field exists in response
   - May need to map `tourname` → `tour_name`

2. **Update Show Model Decoding**
   ```swift
   struct Show: Codable {
       // ... existing fields ...
       
       // Custom decoding to handle field name variations
       enum CodingKeys: String, CodingKey {
           case showyear
           case showdate
           case artist_name
           case tour_name = "tourname"  // Map API field name
           case venue
           case city  
           case state
       }
   }
   ```

3. **Fallback Strategy**
   - If tour name is missing from Show data, fetch from setlist API
   - Use tour statistics API as fallback source
   - Cache tour name once discovered

### Testing Strategy
1. Add logging to see raw API response
2. Verify field names in actual JSON
3. Test with known multi-night runs (e.g., Madison Square Garden)
4. Confirm venue run badges appear when tour context succeeds

## Files Modified

### Server-Side
- `Server/Services/DataCollectionService.js` - Added tourYear field
- `Server/Services/PhishNetTourService.js` - Fixed tour name references
- `Server/Data/tour-schedules.json` - Split tours correctly
- `Server/Scripts/generate-stats.js` - Fixed tour detection

### iOS-Side  
- `Services/PhishNet/PhishNetTourService.swift` - Added venue run calculation & debug logging
- `Models/Show.swift` - Added optional venue fields
- `Services/Core/TourConfig.swift` - Fixed hardcoded tour values
- `Services/PhishIn/PhishInModels.swift` - Updated toShow() method
- `Tests/PhishQSTests/Mocks/MockPhishAPIClient.swift` - Updated mock data

## Next Steps

### Priority 1: Fix Tour Name Issue
1. **Investigate API Response**
   ```swift
   // Add to PhishNetAPIClient.fetchShows()
   print("RAW API RESPONSE: \(String(data: data, encoding: .utf8) ?? "")")
   ```

2. **Check Field Mapping**
   - Verify if API uses `tourname` vs `tour_name`
   - Add CodingKeys enum if needed

3. **Test with Hardcoded Tour Name**
   ```swift
   // Temporary test in getTourNameForShow
   return "2025 Early Summer Tour"  // Hardcode to verify downstream works
   ```

### Priority 2: Implement Fallback
If Phish.net shows API doesn't include tour names:
1. Use setlist API which includes tour info
2. Cache tour names after first discovery
3. Use tour statistics API as backup source

### Priority 3: Verify UI Updates
Once tour context works:
1. Confirm venue run badges display (N1/N2/N3)
2. Confirm tour position shows (Show X/23)
3. Remove debug logging in production build

## Success Criteria
- [ ] `getTourNameForShow()` returns valid tour name
- [ ] Venue run badges display for multi-night runs
- [ ] Tour position indicators show correct X/Y format
- [ ] No hardcoded tour names remain
- [ ] Feature works for future tours without code changes

## Related Issues
- Component B (Tour Statistics) works correctly
- Server API returns correct data
- Issue is isolated to iOS tour context discovery

## Historical Context
This feature previously worked, suggesting:
1. API response format may have changed
2. Field names may have been updated
3. Original implementation may have used different data source

## Branch
`tour-setlist-browser-feature`

## Commit History
- Fixed tour name from "2025 Summer Tour" to "2025 Early Summer Tour"
- Added missing tourYear field to server models
- Implemented venue run calculation in iOS
- Added debug logging to track data flow