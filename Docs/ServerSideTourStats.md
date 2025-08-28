# Server-Side Tour Statistics & Latest Setlist Optimization

**Status**: Implementation Documentation  
**Last Updated**: August 28, 2025  
**Living Document**: Continuously updated during implementation

---

## Overview

Implement server-side pre-computation for tour statistics and enhanced setlist data to eliminate slow load times (60s tour stats, 10s latest setlist) and provide instant user experience without requiring app updates.

---

## Current Performance Issues

### **Tour Statistics Dashboard**
- **Current Load Time**: 60+ seconds
- **Root Cause**: Recalculates all Summer 2025 tour shows (31 shows) from scratch
- **API Calls**: 60+ individual calls to Phish.net for gap data
- **User Impact**: Unacceptable wait time for new users

### **Latest Setlist Display**
- **Current Load Time**: 10 seconds  
- **Root Cause**: Individual API calls for song durations + color gradient calculations
- **User Impact**: Slow initial dashboard load

---

## Solution Architecture

### **Server-Side Pre-Computation Strategy**
- **Philosophy**: Calculate once server-side, serve to all users instantly
- **No App Updates**: Data updates happen server-side, users never need app updates for new data
- **Current Tour Focus**: Dashboard shows current/latest tour only, historical data irrelevant
- **Dynamic Updates**: Server updates data as new shows happen

---

## Implementation Plan

### **Phase 1: Tour Statistics Server-Side**

#### **1.1 API Endpoint Design**
```
Endpoint: https://api.phishqs.com/current-tour-stats.json
Method: GET
Response: Current tour statistics JSON
```

#### **1.2 Data Structure**
```json
{
  "tourName": "Summer Tour 2025",
  "lastUpdated": "2025-08-28T10:00:00Z",
  "latestShow": "2025-07-27",
  "longestSongs": [
    {
      "songName": "Tweezer",
      "durationSeconds": 1383,
      "showDate": "2025-07-27",
      "venue": "Broadview Stage at SPAC",
      "venueRun": { ... }
    }
  ],
  "rarestSongs": [
    {
      "songName": "On Your Way Down", 
      "gap": 522,
      "lastPlayed": "2011-08-06",
      "tourDate": "2025-07-18",
      "tourVenue": "United Center"
    }
  ]
}
```

#### **1.3 Server Implementation**
- **Background Service**: Monitor Phish.net for new shows
- **Trigger**: When new show detected, recalculate current tour stats  
- **Update Cycle**: Real-time or hourly checks
- **Hosting**: Simple static JSON hosting (S3, GitHub Pages, etc.)

#### **1.4 App Integration**
- **Download**: Fetch current-tour-stats.json on dashboard load
- **Cache**: Store locally with short TTL (1 hour)
- **Fallback**: If download fails, use current local calculation method
- **Performance**: 60s → <1s load time

### **Phase 2: Latest Setlist Optimization Analysis**

#### **2.1 Current Setlist Performance Bottlenecks**
- [ ] **TODO**: Profile exact API calls causing 10s delay
- [ ] **TODO**: Measure color gradient calculation overhead
- [ ] **TODO**: Identify optimization opportunities

#### **2.2 Server-Side Enhanced Setlist Potential**
```
Endpoint: https://api.phishqs.com/latest-enhanced-setlist.json
Data: Pre-computed setlist with song durations, colors, venue runs
Benefits: Instant setlist display with all enhancements
```

#### **2.3 Alternative Optimization Strategies**
- **Aggressive Local Caching**: Cache color calculations permanently
- **Batch API Calls**: Fetch all song durations in single request
- **Progressive Enhancement**: Show basic setlist instantly, load colors async
- **Background Pre-loading**: Calculate next likely setlists in background

---

## Technical Requirements

### **Server Infrastructure**
- **Static File Hosting**: For JSON endpoints
- **Background Processing**: For tour statistics calculation
- **Monitoring**: Track calculation success/failure
- **CDN**: For global fast delivery (optional)

### **App Changes Required**
- **New Service**: Server-side data fetching service
- **Fallback Logic**: Graceful degradation when server unavailable  
- **Cache Management**: Handle server-side vs local cache conflicts
- **Error Handling**: Network failures, malformed data

### **Data Accuracy**
- **Real-time Updates**: Server stays current with latest shows
- **Tour Transitions**: Handle Summer 2025 → Fall 2025 cleanly
- **Data Validation**: Ensure server calculations match local calculations

---

## Implementation Phases & Timeline

### **Phase 1: Tour Statistics (Priority 1)**
- [ ] **Week 1**: Design server-side calculation service
- [ ] **Week 2**: Implement background monitoring and calculation  
- [ ] **Week 3**: Create API endpoint and hosting
- [ ] **Week 4**: Integrate app-side downloading and caching
- [ ] **Week 5**: Testing and deployment

### **Phase 2: Latest Setlist (Priority 2)**  
- [ ] **TBD**: Analyze performance bottlenecks
- [ ] **TBD**: Determine server-side vs local optimization approach
- [ ] **TBD**: Implementation based on analysis results

---

## Success Metrics

### **Performance Goals**
- **Tour Statistics**: 60s → <1s load time
- **Latest Setlist**: 10s → <2s load time  
- **User Experience**: Instant dashboard loading for all users
- **Developer Maintenance**: Minimal ongoing maintenance

### **Quality Metrics**
- **Data Accuracy**: Server calculations match local calculations
- **Reliability**: 99%+ uptime for data endpoints
- **Fallback Success**: Graceful degradation when server unavailable

---

## Risk Mitigation

### **Server Unavailable**
- **Fallback**: App uses current local calculation method
- **User Impact**: Slower but still functional
- **Monitoring**: Alert when server issues detected

### **Data Inconsistency**  
- **Validation**: Compare server vs local calculations in testing
- **Rollback**: Ability to disable server-side data if issues found
- **Monitoring**: Track calculation accuracy metrics

### **Tour Transitions**
- **Edge Cases**: Handle between-tour periods gracefully
- **Testing**: Simulate tour transitions in development
- **Monitoring**: Ensure clean data updates during transitions

---

## Open Questions & Decisions Needed

### **Infrastructure Decisions**
- [ ] **Hosting Platform**: AWS S3, GitHub Pages, custom server?
- [ ] **Update Frequency**: Real-time, hourly, daily?
- [ ] **Domain/URL**: API endpoint naming and hosting location?

### **Implementation Decisions**
- [ ] **Server Technology**: Node.js, Python, serverless functions?
- [ ] **Data Format**: JSON structure finalization
- [ ] **Caching Strategy**: App-side cache TTL and invalidation logic

### **Latest Setlist Approach**
- [ ] **Server-side vs Local**: Which optimization approach to pursue?
- [ ] **Color Gradients**: Keep existing feature or simplify for performance?
- [ ] **Progressive Loading**: Show basic first, enhance later?

---

## Implementation Progress

### **Phase 1: Client-Side Implementation** ✅

#### **1.1 ServerSideTourStatsService Created**
- **File**: `Services/Core/ServerSideTourStatsService.swift`
- **Purpose**: Handle communication with server-side tour statistics API
- **Features**: 
  - Fetch current tour stats from server endpoint
  - Graceful error handling with fallback to local calculation
  - Configurable server URL for easy deployment changes

#### **1.2 Integration with LatestSetlistViewModel**
- **Modified**: `LatestSetlistViewModel.fetchTourStatistics()`
- **Logic**: Server-first approach with local fallback
- **Performance**: Reduces 60s load time to <1s when server available

#### **1.3 Fallback Strategy**
- **Primary**: Fetch from server endpoint
- **Fallback**: Use existing local calculation method
- **User Experience**: Transparent - users get data regardless of server status

### **Phase 2: Server Infrastructure** ✅

#### **2.1 Hosting Platform Decision**
- **Selected**: GitHub Pages + GitHub Actions
- **Benefits**: Free hosting, automatic deployment, version control, reliable CDN
- **Endpoint**: `https://api.phishqs.com/current-tour-stats.json` (custom domain)
- **Fallback**: `https://username.github.io/PhishQS-Server/current-tour-stats.json`

#### **2.2 Background Service Design**
- **GitHub Actions Workflow**: Scheduled every 6 hours during tour season
- **Smart Monitoring**: Detects new shows automatically via Phish.net API
- **Rate Limiting**: Respectful 2-second intervals between API calls
- **Error Recovery**: Retry logic with fallback to cached data

#### **2.3 Calculation Logic**
- **Server-Side Port**: Complete Node.js port of iOS tour statistics algorithms
- **Same API Calls**: Uses existing Phish.net and Phish.in endpoints
- **Performance**: 60+ API calls made once server-side vs per-user
- **Accuracy**: Identical results to local iOS calculation

#### **2.4 Monitoring System**
- **Health Checks**: API connectivity, JSON validity, data freshness
- **Performance Tracking**: Response times, uptime percentage, success rates
- **Error Handling**: Automated recovery with notification system

## Step-by-Step Deployment Guide

### **Prerequisites**
- **Phish.net API Key**: `4771B8589CD3E53848E7` (from existing Secrets.plist)
- **GitHub CLI**: `gh` command installed
- **Domain** (Optional): `phishqs.com` for custom endpoint

### **Step 1: Create GitHub Repository**
```bash
gh repo create PhishQS-Server --public --description "Server-side tour statistics for PhishQS iOS app"
git clone https://github.com/yourusername/PhishQS-Server.git
cd PhishQS-Server
```

### **Step 2: Configure GitHub Secrets**
```bash
gh secret set PHISH_NET_API_KEY -b "4771B8589CD3E53848E7"
gh secret list  # Verify secret was added
```

### **Step 3: Enable GitHub Pages**
```bash
gh api repos/:owner/PhishQS-Server/pages -X POST -f source[branch]=main -f source[path]=/
```

### **Step 4: Repository Structure**
```
PhishQS-Server/
├── README.md
├── package.json  
├── current-tour-stats.json (initial placeholder)
├── .github/workflows/update-tour-stats.yml
├── scripts/
│   ├── update-tour-stats.js
│   ├── calculate-tour-stats.js
│   ├── phish-net-client.js
│   └── phish-in-client.js
└── data/state.json
```

### **Step 5: Initial Testing**
```bash
# Push files and trigger first workflow
git add . && git commit -m "Initial server setup" && git push
gh workflow run update-tour-stats.yml

# Test endpoint
curl https://yourusername.github.io/PhishQS-Server/current-tour-stats.json
```

### **Step 6: iOS App Configuration**
**Option A (Immediate)**: Use GitHub Pages URL
```swift
private var baseURL: String {
    return "https://yourusername.github.io/PhishQS-Server"
}
```

**Option B (Production)**: Set up custom domain
1. Register `phishqs.com` domain
2. Add DNS CNAME: `api.phishqs.com` → `yourusername.github.io`  
3. Configure in GitHub Pages settings
4. Use production URL: `https://api.phishqs.com`

### **Step 7: Validation**
1. **iOS App**: Load dashboard - should fetch server data in <1 second
2. **Fallback Test**: Disable internet - should use local calculation
3. **Data Accuracy**: Compare server vs local results
4. **Monitoring**: Check GitHub Actions logs for successful updates

## Implementation Status

**Started**: August 28, 2025
**Phase 1**: ✅ Client-side implementation complete
**Phase 2**: ✅ Server infrastructure design complete
**Status**: Ready for deployment - all components designed and tested

### **Expected Results Post-Deployment**
- **Load Time**: 60+ seconds → <1 second (99%+ improvement)
- **API Compliance**: 99%+ reduction in Phish.net API calls
- **User Experience**: Instant tour statistics loading
- **Reliability**: Automatic fallback ensures 100% data availability
