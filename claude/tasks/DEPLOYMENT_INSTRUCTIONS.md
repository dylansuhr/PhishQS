# Deployment Instructions

## Enhanced Tour Statistics Deployment

The server code has been updated with enhanced tour statistics functionality that includes city/state and tour position information for all three card types:

### Changes Made

1. **Server Models Updated** (`Server/Models/TourStatistics.js`):
   - `TrackDuration`: Added `city`, `state`, `tourPosition` fields
   - `SongGapInfo`: Added `tourCity`, `tourState`, `tourPosition` fields  
   - `MostPlayedSong`: Added complete tour context including most recent performance details

2. **Statistics Generation Enhanced** (`Server/Services/TourStatisticsService.js`):
   - Added helper methods to enrich data with tour context during generation
   - Enhanced all three statistic types with city/state and tour position information
   - Maintains backward compatibility with existing data structure

3. **Expected New API Response Structure**:
   ```json
   {
     "longestSongs": [{
       "id": "38368",
       "songName": "What's Going Through Your Mind",
       "durationSeconds": 2560224,
       "showDate": "2025-06-24", 
       "venue": "Petersen Events Center",
       "city": "Pittsburgh",
       "state": "PA",
       "tourPosition": {
         "showNumber": 4,
         "totalShows": 23,
         "tourName": "Summer Tour 2025"
       }
     }],
     "rarestSongs": [/* with tourCity, tourState, tourPosition */],
     "mostPlayedSongs": [/* with mostRecentVenue, city, state, tourPosition */]
   }
   ```

### Deployment Steps

1. **Authenticate with Vercel**:
   ```bash
   npx vercel login
   ```

2. **Deploy Updated Code**:
   ```bash
   npm run deploy
   ```
   
   This runs: `npx vercel --prod --yes`

3. **Verify Deployment**:
   - Check API endpoint: https://phish-qs.vercel.app/api/tour-statistics
   - Confirm new tour context fields are present in the response

### iOS App Compatibility

The iOS app has been updated to handle the new data structure:

- **Data Models**: Extended with `TourContextProvider` protocol
- **UI Components**: Enhanced to display city/state and tour position badges
- **Backward Compatibility**: New fields are optional, so existing API data will still work

### Expected UI Result

After deployment and app update, the longest songs cards will display:

```
1. What's Going Through Your Mind          42:40
   June 24, 2025  4/23
   Petersen Events Center
   Pittsburgh, PA
```

Similar enhancements will apply to rarest songs and most played songs cards.

### Testing

After deployment, test the iOS app to verify:
1. ✅ All three card types display city/state information
2. ✅ Tour position badges show in blue (e.g., "4/23")
3. ✅ Layout is consistent across all card types
4. ✅ No crashes or missing data scenarios

### Rollback Plan

If issues occur, the previous deployment can be restored via Vercel dashboard or by reverting the changes and redeploying.