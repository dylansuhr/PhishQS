# Vercel Server Implementation Plan

## Overview
Implement a Vercel-based server solution to replace iOS tour statistics calculations with instant server-side responses. This will eliminate the 60+ second load times and provide immediate tour statistics to users.

## Reasoning Behind Approach

### Why Vercel + Static JSON
1. **Simplicity**: Pre-computed JSON served by CDN is the simplest possible architecture
2. **Performance**: Instant responses from edge network vs lengthy calculations
3. **Scalability**: Vercel handles global distribution automatically
4. **Cost-Effective**: Minimal server resources, pay-per-request model
5. **Future-Ready**: Foundation for automated updates when new shows are played

### Why Organized Architecture
1. **iOS Consistency**: Matches existing iOS project structure (Services, Models, etc.)
2. **Maintainability**: Clear separation of concerns, easy to understand and extend
3. **Developer Experience**: Familiar patterns for iOS developers working on server code

## Implementation Steps

### Phase 1: Server Infrastructure ✅ COMPLETED
- [x] Create organized server directory structure (Server/API, Server/Services, etc.)
- [x] Set up Vercel configuration with proper routing and CORS headers
- [x] Create Node.js package.json with ES modules and required dependencies
- [x] Add .gitignore entries for node_modules and Vercel files

### Phase 2: Data Models & Services ✅ COMPLETED  
- [x] Port Swift data models to JavaScript (TourStatistics.js)
- [x] Port TourStatisticsService calculation logic from Swift to JavaScript
- [x] Create generation script to produce tour statistics JSON
- [x] Generate initial sample data matching iOS structure

### Phase 3: API Endpoint ✅ COMPLETED
- [x] Create serverless function to serve pre-computed statistics
- [x] Implement proper error handling and cache headers
- [x] Configure Vercel routing for `/api/tour-statistics` endpoint

### Phase 4: iOS App Integration [IN PROGRESS]
- [ ] Create new TourStatisticsAPIClient for server communication
- [ ] Update LatestSetlistViewModel to fetch from server instead of calculating locally
- [ ] Remove heavy calculation methods from TourStatisticsService
- [ ] Update error handling for network requests
- [ ] Test integration and ensure data structure compatibility

### Phase 5: Vercel Deployment & Testing
- [ ] Walk through Vercel account setup and CLI installation
- [ ] Deploy to Vercel and test API endpoint
- [ ] Update iOS app to point to production Vercel URL
- [ ] Verify end-to-end functionality with real server responses

## Specific Tasks

### Task 4.1: Create Server Communication Layer
**File**: `Services/Core/TourStatisticsAPIClient.swift`
- Create new API client specifically for server communication
- Implement async/await network requests using URLSession
- Add proper error handling for network failures
- Include caching mechanism for offline support
- Follow existing API client patterns (PhishNetAPIClient, PhishInAPIClient)

### Task 4.2: Update LatestSetlistViewModel
**File**: `Features/LatestSetlist/LatestSetlistViewModel.swift`
- Replace `calculateAllTourStatistics` call with server fetch
- Remove commented-out calculation logic (longest/rarest songs)
- Update error handling for network vs calculation errors
- Maintain same data flow and published properties
- Add loading states for network requests

### Task 4.3: Clean Up TourStatisticsService  
**File**: `Services/Core/TourStatisticsService.swift`
- Remove or deprecate heavy calculation methods
- Keep lightweight helper methods if needed by other parts of app
- Update documentation to reflect server-first approach
- Consider keeping fallback methods for offline scenarios (if required)

### Task 4.4: Update API Configuration
**File**: `Services/APIManager.swift` 
- Add server endpoint configuration
- Update to include server API client in coordination
- Ensure consistent error handling across all API clients

## Success Criteria
1. **Performance**: Tour statistics load instantly (< 2 seconds) vs current 60+ seconds
2. **Data Consistency**: Server returns exact same data structure as iOS calculations
3. **Error Handling**: Graceful failure states for network issues
4. **Architecture**: Clean separation between server and iOS concerns
5. **Deployment**: Simple manual deployment process via Vercel CLI

## Risk Mitigation
1. **Network Failures**: Implement proper retry logic and error states
2. **Data Structure Changes**: Use TypeScript-style interfaces for consistency
3. **Deployment Issues**: Test thoroughly in Vercel dev environment first
4. **iOS Integration**: Incremental testing with existing preview data

## Future Expansion Path
1. **Automated Updates**: Add webhook/cron job to detect new shows
2. **Real-time Updates**: WebSocket or polling for live statistics updates  
3. **Multiple Tours**: Support for historical tour statistics
4. **Advanced Metrics**: Additional statistics beyond current three types

## Current Status
- **Completed**: Server infrastructure, data models, API endpoint, sample data generation
- **In Progress**: iOS app integration to fetch from server
- **Next**: Vercel deployment and end-to-end testing

---

*This plan follows the MVP approach focusing on core functionality first, with clear expansion paths for future enhancements.*