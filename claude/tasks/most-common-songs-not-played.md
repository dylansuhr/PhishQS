# Most Common Songs Not Played Implementation Task

## Overview
Implement a new tour statistics card showing the top 20 most commonly played Phish songs (originals + covers) that have NOT been played during the current tour.

## Key Discovery: Correct Phish Song Filtering
Based on API exploration, the proper way to filter for **all songs performed by Phish**:

**Correct Approach**: Exclude side project artists rather than include only `artist: "Phish"`
- ✅ **Includes**: Phish originals + covers performed by Phish
- ✅ **Excludes**: Side project songs (Trey Anastasio, Mike Gordon, etc.)
- ✅ **Result**: 902 songs performed by Phish vs 333 with old filter

## Data Source Strategy
- **Single API Call**: `/songs.json` endpoint (970 total songs)
- **Filtering**: Exclude 68 side project songs → 902 Phish-performed songs
- **Threshold**: 100+ plays (108 candidates) for "common" determination
- **Integration**: Follows existing single source architecture

## Infrastructure Compliance
**✅ Zero Infrastructure Changes Required**:
- Uses existing GitHub Actions workflow (`npm run generate-stats`)
- Stores data in existing `Server/Data/tour-stats.json`
- Serves via existing `/api/tour-statistics` endpoint
- Deploys via existing Vercel configuration

## Implementation Steps

### Phase 1: Data Collection Enhancement
- **File**: `Server/Scripts/generate-stats.js`
- **Enhancement**: Add comprehensive song database collection
- **Integration**: Fetch `/songs.json` during existing generation process
- **Storage**: Pass song database to calculator via generation context

### Phase 2: Calculator Implementation
- **File**: `Server/Services/StatisticsCalculators/MostCommonSongsNotPlayedCalculator.js`
- **Pattern**: Extends `BaseStatisticsCalculator`
- **Algorithm**:
  1. Extract current tour songs from `show.setlistItems`
  2. Filter comprehensive songs to commonly played (100+ times)
  3. Remove current tour songs from common songs
  4. Sort by historical play count, return top 20

### Phase 3: Data Model Updates
- **Server**: Add `MostCommonSongNotPlayed` to `TourStatistics.js`
- **iOS**: Add corresponding model to `SharedModels.swift`
- **Registry**: Register calculator in `StatisticsRegistry.js`

### Phase 4: iOS UI Implementation
- **Card**: `MostCommonSongsNotPlayedCard` with state-driven accordion
- **Row Component**: `MostCommonSongNotPlayedRow` for individual display
- **Integration**: Add to `TourStatisticsCards` and dashboard animation sequence

### Phase 5: Configuration
- **Config**: Add result limit to `StatisticsConfig.js`
- **Testing**: Verify with `npm run generate-stats`

## Expected Results
**Data**: 108 common Phish songs (100+ plays) → filter current tour → top 20
**Performance**: Maintained ~140ms server response time
**Display**: "Song Name • 272 times played" with accordion expansion (3 → 20)
**Integration**: Automatic deployment via existing 3x daily GitHub Actions

## Technical Specifications

### Phish Song Filtering Logic
```javascript
const sideProjectArtists = [
    'Trey Anastasio', 'Mike Gordon', 'Page Mcconnell', 'Page McConnell',
    'Leo Kotke/Mike Gordon', 'Mike Gordon and Leo Kottke',
    'Trey, Mike, and The Benevento/Russo Duo', 'Trey Anastasio & Don Hart'
];

const phishPerformedSongs = allSongs.filter(song =>
    song.times_played > 0 &&
    !sideProjectArtists.includes(song.artist)
);
```

### Data Flow
1. **Generation**: `generate-stats.js` fetches comprehensive song data
2. **Calculation**: Calculator processes tour shows + song database
3. **Storage**: Results stored in `tour-stats.json`
4. **Deployment**: Automatic via GitHub Actions + Vercel
5. **Consumption**: iOS app fetches enhanced data

## Success Criteria
1. ✅ New card displays top 20 most common songs not played
2. ✅ State-driven accordion expansion (3 → 20 items)
3. ✅ Proper integration with existing dashboard animations
4. ✅ Automated deployment via existing infrastructure
5. ✅ Performance maintained (~140ms API response)

## Notes
- Follows established single source architecture patterns
- Zero infrastructure changes required
- Automatic updates via existing 3x daily GitHub Actions
- Compatible with existing Vercel deployment configuration