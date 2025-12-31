# Add Setlistnotes to Historical API Calls

## Status: Pending

## Overview
Currently, setlistnotes only display for current tour shows (loaded from pre-computed JSON files). Historical shows fetched via direct API calls have `setlistnotes: nil`.

## Current Behavior

| Date Type | Data Source | setlistnotes |
|-----------|-------------|--------------|
| Current Tour | Local JSON (`Server/Data/tours/*/show-*.json`) | ✓ Available |
| Historical | API calls (Phish.net + Phish.in) | ✗ nil |
| Future Tour | Local JSON (metadata only) | N/A |

## Problem
The Phish.net API response includes `setlistnotes` in each setlist item, but `APIManager.fetchBasicSetlist()` doesn't extract it. The field is available - we just don't capture it.

## Solution

### 1. Update SetlistItem Model
**File**: `Models/SetlistItem.swift`

Add `setlistnotes` property to decode from Phish.net API response.

### 2. Update APIManager
**File**: `Services/APIManager.swift`

In `fetchBasicSetlist()` and `fetchEnhancedSetlist()`:
- Extract `setlistnotes` from the first setlist item (it's the same for all items in a show)
- Pass to EnhancedSetlist constructor instead of `nil`

### 3. Verify PhishNetClient Response
**File**: `Services/PhishNet/PhishNetClient.swift`

Ensure the setlist response includes `setlistnotes` field and it's being decoded.

## Files to Modify
- `Models/SetlistItem.swift`
- `Services/APIManager.swift`
- Possibly `Services/PhishNet/PhishNetClient.swift`

## Testing
1. Open SetlistView for a historical show (e.g., 1999-12-31)
2. Verify notes section appears if show has notes
3. Verify current tour shows still work correctly
