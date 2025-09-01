# Real Data Integration Plan

## Objective
Move the exact same working API calls and calculations from iOS to server-side generation script to replace sample data with real current tour statistics.

## Current State
- iOS app was successfully calculating real tour statistics using Phish.net and Phish.in APIs
- Server generation script (`generate-stats.js`) only generates sample/mock data
- All calculation logic exists and works - just need to connect real API data

## Approach
Take the exact working iOS API integration and port it to JavaScript for server-side pre-computation.

## Implementation Steps

### Step 1: Port Real API Calls
- Copy the working API logic from iOS `APIManager.swift` and `PhishNetAPIClient.swift`
- Create JavaScript versions that make the same exact API calls
- Use the existing Phish.net API key from `Secrets.plist`: `4771B8589CD3E53848E7`
- Focus on the specific APIs that were working:
  - Latest show fetch
  - Tour identification 
  - Show data for current tour
  - Gap calculations

### Step 2: Update Data Collection
- Replace sample data generation in `generate-stats.js` 
- Connect real API responses to existing `TourStatisticsService.js` calculation logic
- Maintain the exact same data structure and processing that was working in iOS

### Step 3: Deploy Real Data
- Generate statistics with real API data: `npm run generate-stats`
- Deploy to Vercel: `vercel --prod` 
- Verify iOS app receives real current tour data instead of sample data

## Success Criteria
- ✅ Server generation script fetches real tour data from APIs
- ✅ Generated JSON contains current actual Phish tour statistics  
- ✅ iOS app displays real data (longest songs, rarest songs, most played from current tour)
- ✅ Same calculation accuracy as original iOS implementation
- ✅ API response time remains fast (~140ms)

## Implementation Notes
- Keep it simple - just move working logic, don't redesign
- Avoid code reuse complexity - focus on making it work first
- Use the exact same API calls and processing logic that was proven to work
- No automation features - just get real data working first

## Completed: Code Cleanup
✅ **Cleanup Tasks Completed**:
- Removed duplicate API files (kept only `/api/tour-statistics.js`)
- Cleaned up sample data generation code in `generate-stats.js`
- Fixed API key configuration (using real key: `4771B8589CD3E53848E7`)
- Removed .DS_Store and unnecessary files
- Reduced excessive logging in TourStatisticsService
- Fixed broken syntax issues (incorrect constructor call)
- Removed obsolete TODOs

✅ **Current State**: Clean, organized codebase ready for real API integration
- Generation script structure ready for real API calls
- All models and services properly structured
- API endpoint tested and working
- No dead code or file duplication