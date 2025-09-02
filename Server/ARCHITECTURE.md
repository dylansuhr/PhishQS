# PhishQS Server Architecture Documentation

## Modular Statistics Calculation System

### Overview

The PhishQS server uses a modular, extensible architecture for calculating tour statistics. This system was designed to replace the monolithic iOS calculations with a maintainable, configurable server-side solution.

### Architecture Principles

- **Modular**: Each statistics type has its own dedicated calculator
- **Configurable**: All settings managed through `StatisticsConfig`
- **Extensible**: New statistics types can be added without core changes
- **Maintainable**: Clear separation of concerns and responsibilities
- **Testable**: Individual calculators can be tested in isolation

### Core Components

#### 1. Configuration System (`Server/Config/`)

**StatisticsConfig.js** - Centralized configuration management
- Environment-specific settings (development, production, preview)
- Result limits and thresholds (no hardcoding)
- API endpoints and feature flags
- Debug and performance settings

```javascript
// Example: Get configuration for a calculator
const config = StatisticsConfig.getCalculatorConfig('longestSongs');
// Returns: { resultLimit: 3, debugMode: true, ... }
```

#### 2. Calculator Framework (`Server/Services/StatisticsCalculators/`)

**BaseStatisticsCalculator.js** - Abstract base class
- Template Method pattern for consistent workflow
- Input validation and error handling
- Shared utilities (capitalization, hashing)
- Debug logging infrastructure

**Concrete Calculators:**
- `LongestSongsCalculator.js` - Processes track duration data
- `RarestSongsCalculator.js` - Analyzes gap data with progressive tracking
- `MostPlayedSongsCalculator.js` - Counts song frequency across tour

#### 3. Registry System (`Server/Services/StatisticsRegistry.js`)

**StatisticsRegistry.js** - Central calculator management
- Registry pattern for calculator discovery
- Factory pattern for instance creation
- Automatic calculator execution coordination
- Performance timing and error handling

#### 4. Orchestration Layer (`Server/Services/TourStatisticsService.js`)

**TourStatisticsService.js** - Main service interface
- V2: New modular architecture (recommended)
- V1: Legacy monolithic method (preserved for compatibility)
- Maintains same API contract for seamless migration

### Data Flow

```
1. generate-stats.js
   ↓
2. TourStatisticsService.calculateTourStatistics()
   ↓
3. StatisticsRegistry.calculateAllStatistics()
   ↓
4. [LongestSongs, RarestSongs, MostPlayed] Calculators (parallel execution)
   ↓
5. Combined results → TourSongStatistics model
   ↓
6. JSON output → API endpoint
```

### Adding New Statistics Types

Adding a new statistics type requires these steps:

#### Step 1: Create Calculator Class

Create `Server/Services/StatisticsCalculators/NewStatCalculator.js`:

```javascript
import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';

export class NewStatCalculator extends BaseStatisticsCalculator {
    constructor(config = {}) {
        super(config);
        this.calculatorType = 'NewStat';
    }
    
    initializeDataContainer() {
        return {
            // Your data collection structure
        };
    }
    
    processShow(show, dataContainer) {
        // Process each show and update dataContainer
    }
    
    generateResults(dataContainer, tourName) {
        // Generate final results from collected data
        return results.slice(0, this.resultLimit);
    }
}
```

#### Step 2: Register Calculator

Add to `StatisticsRegistry.js` constructor:

```javascript
this.registerCalculator('newStat', {
    name: 'New Statistic',
    description: 'Description of what this calculates',
    dataSource: 'Data source description',
    calculatorClass: NewStatCalculator,
    resultType: 'ResultModelType',
    enabled: true,
    priority: 4 // Display order
});
```

#### Step 3: Update Configuration

Add to `StatisticsConfig.js` resultLimits:

```javascript
resultLimits: {
    longestSongs: 3,
    rarestSongs: 3,
    mostPlayedSongs: 3,
    newStat: 3  // Add your new statistic
}
```

#### Step 4: Update Data Model

Modify `TourSongStatistics.js` if needed:

```javascript
export class TourSongStatistics {
    constructor(longestSongs, rarestSongs, mostPlayedSongs, newStats, tourName) {
        this.longestSongs = longestSongs;
        this.rarestSongs = rarestSongs;
        this.mostPlayedSongs = mostPlayedSongs;
        this.newStats = newStats; // Add your new field
        this.tourName = tourName;
    }
}
```

#### Step 5: Update Service Layer

Modify `TourStatisticsService.calculateTourStatistics()`:

```javascript
const newStats = calculatorResults.newStat || [];

return new TourSongStatistics(
    longestSongs,
    rarestSongs,
    mostPlayedSongs,
    newStats, // Add your results
    tourName
);
```

That's it! The new statistic will automatically be:
- Calculated during generation
- Included in API responses
- Configurable through StatisticsConfig
- Debuggable with logging

### Performance Characteristics

- **Single-pass data collection**: Each show processed once across all calculators
- **Parallel calculator execution**: Statistics calculated simultaneously
- **Memory efficient**: Uses Maps and progressive tracking
- **Configurable limits**: Result sets limited to prevent memory issues

### Environment Configuration

**Development**:
- Debug logging enabled
- Shorter cache TTLs
- Extended logging and timing

**Production**:
- Debug logging disabled
- Optimized cache settings
- Minimal logging overhead

**Preview/Staging**:
- Balanced settings
- Some debug features enabled

### Error Handling

- **Calculator failures**: Individual calculator errors don't break the system
- **Empty results**: Graceful handling of missing data
- **Validation**: Input validation at multiple levels
- **Fallbacks**: Legacy method available as backup

### Monitoring and Debugging

**Debug Features** (development only):
- Calculator registration logging
- Performance timing per calculator
- Extended statistics logging
- Gap validation warnings

**Production Monitoring**:
- Error tracking for failed calculators
- Performance metrics collection
- Statistics generation success/failure rates

### Migration Path

1. **Current**: New modular architecture in use
2. **Legacy**: Monolithic method preserved for compatibility
3. **Future**: Legacy method can be removed after full validation

### Testing Strategy

**Unit Tests** (recommended):
```javascript
// Test individual calculators
const calculator = new LongestSongsCalculator(config);
const results = calculator.calculate(mockTourShows, 'Test Tour');
expect(results).toHaveLength(3);
```

**Integration Tests**:
```javascript
// Test full registry coordination
const registry = new StatisticsRegistry();
const allResults = registry.calculateAllStatistics(tourShows, tourName);
expect(allResults).toHaveProperty('longestSongs');
```

### Deployment

The modular architecture maintains the same API contract:
- Same endpoints (`/api/tour-statistics`)
- Same response format
- Same performance characteristics
- Same caching behavior

No client-side changes required for the migration.

---

## Benefits Summary

✅ **Extensibility**: New statistics can be added in minutes
✅ **Maintainability**: Clear separation of concerns
✅ **Configurability**: No hardcoded values anywhere
✅ **Performance**: Maintained ~140ms response times
✅ **Testability**: Individual components can be tested
✅ **Documentation**: Comprehensive inline and architectural docs
✅ **Future-proof**: Registry pattern supports unlimited statistics types

The new architecture transforms PhishQS from a monolithic calculation system into a flexible, extensible platform for tour statistics analysis.