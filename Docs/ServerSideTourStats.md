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

## Implementation Notes

**This document will be updated continuously as implementation progresses. All decisions, code changes, and lessons learned will be documented here for future reference.**
