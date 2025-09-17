# API Exploration Tools

Generic utilities for exploring and testing Phish.net API endpoints.

## Phish.net Explorer

**File**: `phish-net-explorer.js`

### Usage Examples

```bash
# Explore songs database (default)
node tools/phish-net-explorer.js

# Explore songs database explicitly
node tools/phish-net-explorer.js --endpoint songs

# Explore shows for specific year
node tools/phish-net-explorer.js --endpoint shows --year 2025

# Test endpoint discovery
node tools/phish-net-explorer.js --endpoint discover

# Custom exploration
node tools/phish-net-explorer.js --endpoint custom
```

### Features

**Song Analysis**:
- Phish song filtering (excludes side projects)
- Play count distribution analysis
- Top songs by frequency
- Cover song identification

**Show Analysis**:
- Year-based show exploration
- Tour identification
- Phish show filtering
- Recent show listing

**Endpoint Discovery**:
- Test multiple API endpoints
- Response structure analysis
- Data type identification

**Custom Exploration**:
- Editable custom function
- Reusable analysis utilities
- Flexible search criteria

### Available Functions

```javascript
// Import for use in other scripts
import {
    fetchPhishNetData,         // Generic API fetch
    filterPhishPerformedSongs, // Phish song filtering
    analysisUtils,             // Data analysis utilities
    exploreFunctions           // Exploration functions
} from './phish-net-explorer.js';
```

### Analysis Utilities

```javascript
// Song distribution analysis
analysisUtils.analyzeSongDistribution(songs);

// Find songs by criteria
analysisUtils.findSongs(songs, {
    minPlays: 100,
    nameContains: 'tweezer',
    artist: 'Phish'
});

// Show top N songs
analysisUtils.showTopSongs(songs, 20, 'Most Played');
```

## Development Usage

Use these tools when:
- Exploring new API endpoints
- Understanding data structures
- Testing filtering logic
- Debugging API responses
- Prototyping new features

## Important Notes

- Uses production API key for real data
- Includes Phish song filtering logic from CLAUDE.md
- Outputs are formatted for readability
- Functions are reusable across projects
- No file modifications - read-only exploration