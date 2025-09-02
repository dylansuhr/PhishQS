# Archived iOS Tour Statistics Calculations

This directory contains deprecated iOS calculation methods that have been replaced by server-side pre-computed statistics for performance and architectural reasons.

## Background

Originally, PhishQS calculated tour statistics locally on the iOS device, which resulted in:
- **60+ second calculation times** for complex tour statistics
- **High memory usage** when processing large tour datasets  
- **Poor user experience** with long loading times and potential timeouts
- **Battery drain** from intensive local processing

## Server-Side Architecture Migration

As of **September 2025**, PhishQS moved to a **server-side pre-computed statistics architecture**:

| Metric | iOS Local Calculation | Server Pre-computed |
|--------|----------------------|---------------------|
| **Performance** | 60+ seconds | ~140ms |
| **Memory Usage** | High (processes all tour shows) | Low (fetches JSON) |
| **User Experience** | Loading spinners, timeouts | Instant display |
| **Maintainability** | Complex iOS code | Centralized server logic |
| **Scalability** | Limited by device resources | Unlimited server processing |

## Current Architecture

### Server Components
- **`/Server/Services/TourStatisticsService.js`** - Core statistics calculation logic
- **`/Server/API/tour-statistics.js`** - Vercel serverless endpoint  
- **`/Server/Data/tour-stats.json`** - Pre-computed statistics data
- **`/Server/Scripts/generate-stats.js`** - Statistics generation script

### iOS Components  
- **`TourStatisticsAPIClient.swift`** - Server API client with comprehensive error handling
- **`TourStatisticsService.swift`** - Coordination service (server-only, no local calculations)
- **`LegacyTourStatisticsCalculator.swift`** - Archived calculation methods (this directory)

## Archived File Contents

### `LegacyTourStatisticsCalculator.swift`

Contains all deprecated iOS calculation methods:

#### Core Algorithm Methods
- `calculateAllTourStatistics()` - Single-pass algorithm for complete tour statistics
- `calculateTourProgressiveRarestSongs()` - Progressive gap tracking across tour shows
- `calculateHistoricalRarestSongs()` - Historical gap calculation with API integration

#### Utility Methods
- `calculateLongestSongs()` - Duration-based song ranking
- `calculateRarestSongs()` - Gap-based rarity calculation with historical data enhancement
- `calculateMostPlayedSongs()` - Play count frequency analysis
- `calculateComprehensiveTourStatistics()` - Multi-show tour analysis

#### API Integration Methods
- `getLastPlayedBeforeCurrentTour()` - Historical performance lookup
- Integration with `HistoricalGapCalculator` for accurate gap data

## Key Algorithms Preserved

### Progressive Gap Tracking Algorithm
The archived code preserves the **progressive gap tracking algorithm** which was critical for accurate rarest song identification:

```swift
// For each song, keep the occurrence with the HIGHEST gap
if let existingGap = tourSongGaps[songKey] {
    if gapInfo.gap > existingGap.gap {
        tourSongGaps[songKey] = enhancedGapInfo
    }
} else {
    tourSongGaps[songKey] = enhancedGapInfo
}
```

This algorithm ensures that when a song appears multiple times in a tour, only the performance with the highest gap (most rare occurrence) is counted.

### Single-Pass Calculation Optimization
The archived code includes an optimized **single-pass algorithm** that processes all tour shows once to calculate all three statistics types simultaneously, minimizing data processing overhead.

## When to Use Archived Code

### ✅ Use Archived Code For:
- **Research and reference** - Understanding calculation logic
- **Algorithm validation** - Comparing server results against iOS calculations
- **Offline scenarios** - If server-side statistics become unavailable (future implementation)
- **Historical analysis** - Studying tour statistics calculation evolution
- **Code archaeology** - Understanding pre-server architecture decisions

### ❌ Do NOT Use Archived Code For:
- **Production features** - All statistics should use server API
- **Performance-critical paths** - iOS calculations are 400x slower than server
- **New development** - Extend server-side calculators instead
- **User-facing features** - Poor UX compared to instant server responses

## Migration Notes

### Data Format Compatibility
The archived iOS methods produce `TourSongStatistics` objects that are **100% compatible** with server-generated statistics, ensuring seamless UI rendering regardless of data source.

### Algorithm Accuracy
Server-side calculations use **identical algorithms** to the archived iOS code but with additional optimizations:
- **Enhanced gap data** from multiple API sources
- **Better venue information** with proper venue-date consistency  
- **Optimized data structures** for faster processing
- **Comprehensive error handling** for data quality issues

### API Consistency
Both iOS and server calculations integrate with the same external APIs:
- **Phish.net API** for setlist data and gap calculations
- **Phish.in API** for song durations and tour structure
- **Multi-API strategy** for comprehensive tour statistics

## Future Considerations

### Potential Use Cases for Restoration
1. **Offline Support** - If network connectivity becomes unreliable
2. **Development/Debug Mode** - For algorithm validation and testing
3. **Fallback Mechanism** - As backup if server infrastructure fails
4. **Historical Analysis** - For studying past tour statistics calculation approaches

### Implementation Considerations
If archived code needs to be restored:
1. **Update dependencies** - Verify compatibility with current iOS/Swift versions
2. **Performance testing** - Measure impact on modern devices
3. **Memory optimization** - Consider streaming/chunked processing for large datasets
4. **Error handling** - Enhance robustness for production use
5. **API updates** - Verify external API compatibility

## Documentation Standards

All archived methods include:
- **`@available(*, deprecated)`** warnings directing to server alternatives
- **Comprehensive comments** explaining algorithm logic and performance characteristics  
- **Historical context** about why methods were deprecated
- **Usage examples** for future reference
- **Performance notes** documenting calculation times and memory usage

---

**Last Updated:** September 2025  
**Deprecated:** September 2025  
**Replacement:** Server-side pre-computed statistics via `TourStatisticsAPIClient`