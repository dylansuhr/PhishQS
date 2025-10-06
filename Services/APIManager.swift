//
//  APIManager.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//

import Foundation

// MARK: - Central API Coordinator

/// Central API coordinator implementing hybrid multi-API architecture
/// 
/// **Architecture Strategy:**
/// - **Phish.net**: Primary source for setlists, tour organization, show counts, venue runs, song gaps
/// - **Phish.in**: Specialized audio provider for song durations and recordings only
/// - **Vercel Server**: Pre-computed tour statistics for optimal performance
/// 
/// This hybrid approach leverages each API's strengths while maintaining data consistency
class APIManager: ObservableObject {
    
    // MARK: - API Clients
    
    /// Primary setlist and tour data provider (Phish.net API)
    /// Handles: setlists, shows, tour positions, venue runs, song gap calculations
    private let phishNetClient: PhishAPIService
    
    /// Specialized audio enhancement provider (Phish.in API) - song durations only
    /// Handles: track durations, audio recordings
    /// **Usage Restriction**: Only used for audio timing data
    private let phishInClient: AudioProviderProtocol?
    
    /// Tour structure and organization provider (Phish.net API)
    /// Handles: tour show lists, tour positions, show counts
    private let phishNetTourService: PhishNetTourService
    
    /// Pre-computed tour statistics provider (Vercel server)
    /// Handles: tour statistics with ~140ms response times vs 60+ second local calculations
    private let tourStatsClient: TourStatisticsProviderProtocol
    
    // MARK: - Initialization
    
    init(
        phishNetClient: PhishAPIService = PhishAPIClient.shared,
        phishInClient: AudioProviderProtocol? = PhishInAPIClient.shared,
        phishNetTourService: PhishNetTourService = PhishNetTourService(),
        tourStatsClient: TourStatisticsProviderProtocol = TourStatisticsAPIClient.shared
    ) {
        self.phishNetClient = phishNetClient
        self.phishInClient = phishInClient
        self.phishNetTourService = phishNetTourService
        self.tourStatsClient = tourStatsClient
    }
    
    // MARK: - Setlist Operations (Primary Source: Phish.net)
    
    /// Fetch shows for a given year
    func fetchShows(forYear year: String) async throws -> [Show] {
        return try await phishNetClient.fetchShows(forYear: year)
    }

    /// Fetch shows for a given year with caching (30-min TTL)
    /// Used by date search flow to avoid duplicate API calls
    func fetchShowsWithCache(forYear year: String) async throws -> [Show] {
        let cacheKey = CacheManager.CacheKeys.yearShows(year)

        // Check cache first
        if let cachedShows = CacheManager.shared.get([Show].self, forKey: cacheKey) {
            return cachedShows
        }

        // Fetch from API
        let shows = try await phishNetClient.fetchShows(forYear: year)

        // Cache for 30 minutes
        CacheManager.shared.set(shows, forKey: cacheKey, ttl: CacheManager.TTL.yearShows)

        return shows
    }
    
    /// Fetch the latest show
    func fetchLatestShow() async throws -> Show? {
        return try await phishNetClient.fetchLatestShow()
    }
    
    /// Fetch setlist for a specific date
    func fetchSetlist(for date: String) async throws -> [SetlistItem] {
        return try await phishNetClient.fetchSetlist(for: date)
    }

    /// Fetch basic setlist with only essential data (setlist + durations)
    /// Optimized for SetlistView - skips gap data, tour context, and recordings
    func fetchBasicSetlist(for date: String) async throws -> EnhancedSetlist {
        // Check cache first
        let cacheKey = CacheManager.CacheKeys.enhancedSetlist(date)
        if let cachedSetlist = CacheManager.shared.get(EnhancedSetlist.self, forKey: cacheKey) {
            return cachedSetlist
        }

        // Get base setlist from Phish.net
        let setlistItems = try await phishNetClient.fetchSetlist(for: date)

        // Get track durations from Phish.in (only if available)
        var trackDurations: [TrackDuration] = []
        if let phishInClient = phishInClient, phishInClient.isAvailable {
            do {
                trackDurations = try await phishInClient.fetchTrackDurations(for: date)
            } catch {
                SwiftLogger.warn("Could not fetch track durations from Phish.in for \(date): \(error)", category: .api)
            }
        }

        let enhancedSetlist = EnhancedSetlist(
            showDate: date,
            setlistItems: setlistItems,
            trackDurations: trackDurations,
            venueRun: nil,       // Not displayed in SetlistView
            tourPosition: nil,   // Not displayed in SetlistView
            recordings: [],      // Not displayed in SetlistView
            songGaps: []         // Not displayed in SetlistView
        )

        // Cache for 2 hours
        CacheManager.shared.set(enhancedSetlist, forKey: cacheKey, ttl: CacheManager.TTL.enhancedSetlist)

        return enhancedSetlist
    }
    
    /// Search shows by query
    func searchShows(query: String) async throws -> [Show] {
        return try await phishNetClient.searchShows(query: query)
    }
    
    
    // MARK: - Enhanced Data Operations (Multi-API Coordination)
    
    /// Fetch setlist with enhanced data (song durations, venue runs, tour position, etc.)
    func fetchEnhancedSetlist(for date: String) async throws -> EnhancedSetlist {
        // Check cache first for recent shows
        let cacheKey = CacheManager.CacheKeys.enhancedSetlist(date)
        if let cachedSetlist = CacheManager.shared.get(EnhancedSetlist.self, forKey: cacheKey) {
            return cachedSetlist
        }
        
        // Get base setlist from Phish.net
        let setlistItems = try await phishNetClient.fetchSetlist(for: date)
        
        // Hybrid data collection: durations from Phish.in (audio only), tour/venue data from Phish.net (authoritative)
        var trackDurations: [TrackDuration] = []
        var venueRun: VenueRun? = nil
        var tourPosition: TourShowPosition? = nil
        var recordings: [Recording] = []
        var songGaps: [SongGapInfo] = []
        
        // Execute all API calls in parallel for better performance
        async let gapDataTask: [SongGapInfo] = {
            // Get unique song names from the setlist
            let songNames = Array(Set(setlistItems.map { $0.song }))
            
            // Cast phishNetClient to GapDataProviderProtocol if it supports gap data
            if let gapProvider = phishNetClient as? GapDataProviderProtocol {
                do {
                    return try await gapProvider.fetchSongGaps(songNames: songNames, showDate: date)
                } catch {
                    SwiftLogger.warn("Could not fetch gap data from Phish.net for \(date): \(error)", category: .api)
                    return []
                }
            }
            return []
        }()
        
        // Parallel API execution: Phish.in (durations only), Phish.net (tour context), with individual error handling
        async let tourContextTask = phishNetTourService.getTourContext(for: date)
        
        if let phishInClient = phishInClient, phishInClient.isAvailable {
            async let trackDurationsTask = phishInClient.fetchTrackDurations(for: date)
            async let recordingsTask = phishInClient.fetchRecordings(for: date)
            
            // Await results with individual error handling
            do {
                trackDurations = try await trackDurationsTask
            } catch {
                SwiftLogger.warn("Could not fetch track durations from Phish.in for \(date): \(error)", category: .api)
            }
            
            do {
                recordings = try await recordingsTask
            } catch {
                SwiftLogger.warn("Could not fetch recording info from Phish.in: \(error)", category: .api)
            }
        }
        
        // Get tour context from Phish.net
        do {
            let tourContext = try await tourContextTask
            tourPosition = tourContext.tourPosition
            venueRun = tourContext.venueRun
        } catch {
            SwiftLogger.warn("Could not fetch tour context from Phish.net: \(error)", category: .api)
        }
        
        // Await gap data task
        songGaps = await gapDataTask
        
        let enhancedSetlist = EnhancedSetlist(
            showDate: date,
            setlistItems: setlistItems,
            trackDurations: trackDurations,
            venueRun: venueRun,
            tourPosition: tourPosition,
            recordings: recordings,
            songGaps: songGaps
        )
        
        // Cache the enhanced setlist for 30 minutes
        CacheManager.shared.set(enhancedSetlist, forKey: cacheKey, ttl: CacheManager.TTL.enhancedSetlist)
        
        return enhancedSetlist
    }
    
    /// Fetch tours for a specific year from Phish.net
    /// Note: This method may need to be implemented differently as Phish.net doesn't have a direct tours endpoint
    func fetchTours(forYear year: String) async throws -> [Tour] {
        // For now, we can extract tour information from shows
        let shows = try await phishNetClient.fetchShows(forYear: year)
        let tourNames = Set(shows.compactMap { $0.tour_name })
        
        return tourNames.map { tourName in
            Tour(id: tourName, name: tourName, year: year, startDate: "", endDate: "", showCount: 0)
        }
    }
    
    /// Fetch track durations for a specific show
    func fetchTrackDurations(for showDate: String) async throws -> [TrackDuration] {
        guard let phishInClient = phishInClient else {
            return []
        }
        return try await phishInClient.fetchTrackDurations(for: showDate)
    }
    
    /// Fetch venue run information for a specific show from Phish.net
    func fetchVenueRuns(for showDate: String) async throws -> VenueRun? {
        let tourContext = try await phishNetTourService.getTourContext(for: showDate)
        return tourContext.venueRun
    }
    
    /// Fetch recording information for a specific show
    func fetchRecordings(for showDate: String) async throws -> [Recording] {
        guard let phishInClient = phishInClient else {
            return []
        }
        return try await phishInClient.fetchRecordings(for: showDate)
    }
    
    /// Fetch tour position information for a specific show from Phish.net
    func fetchTourPosition(for showDate: String) async throws -> TourShowPosition? {
        guard let tourName = try await phishNetTourService.getTourNameForShow(date: showDate) else {
            return nil
        }
        return try await phishNetTourService.calculateTourPosition(for: showDate, tourName: tourName)
    }
    
    /// Fetch all track durations for an entire tour using hybrid approach
    /// **Data Sources**: Phish.net (tour show list), Phish.in (duration data only)
    func fetchTourTrackDurations(tourName: String, year: String) async throws -> [TrackDuration] {
        guard let phishInClient = phishInClient else {
            return []
        }
        
        // Step 1: Get complete tour show list from Phish.net (authoritative source)
        let tourShows = try await phishNetTourService.fetchTourShows(year: year, tourName: tourName)
        var allTourTracks: [TrackDuration] = []
        
        // Step 2: Enhance with duration data from Phish.in (audio timing only)
        for show in tourShows {
            do {
                let trackDurations = try await phishInClient.fetchTrackDurations(for: show.showdate)
                allTourTracks.append(contentsOf: trackDurations)
            } catch {
                SwiftLogger.warn("Could not fetch durations for \(show.showdate): \(error)", category: .api)
            }
        }
        
        return allTourTracks
    }
    
    /// Fetch all shows for a specific tour using Phish.net
    func fetchTourShows(tourName: String, year: String) async throws -> [Show] {
        return try await phishNetTourService.fetchTourShows(year: year, tourName: tourName)
    }
    
    /// Get the tour name from Phish.net for a specific show date
    func getNativeTourName(for showDate: String) async throws -> String? {
        do {
            return try await phishNetTourService.getTourNameForShow(date: showDate)
        } catch {
            SwiftLogger.warn("Could not fetch tour name for \(showDate): \(error)", category: .api)
            return nil
        }
    }
}

// MARK: - Convenience Extensions

extension APIManager {
    
    /// Shared instance for app-wide use
    static let shared = APIManager()
    
    /// Check if primary setlist service is available
    var isSetlistServiceAvailable: Bool {
        return true // Phish.net is our primary source
    }
    
    /// Check if audio enhancement services (Phish.in) are available
    /// **Note**: Only used for song timing data, not tour structure
    var isEnhancedDataAvailable: Bool {
        return phishInClient?.isAvailable ?? false
    }
    
    /// Get list of available data sources
    var availableDataSources: [String] {
        var sources = ["Phish.net (Setlists)"]
        if isEnhancedDataAvailable {
            sources.append("Phish.in (Song Durations Only)")
        }
        sources.append("Phish.net (Tours & Venues)")
        if tourStatsClient.isAvailable {
            sources.append("Vercel Server (Statistics)")
        }
        return sources
    }
    
    // MARK: - Tour Statistics Operations (Primary Source: Vercel Server)
    
    /// Fetch pre-computed tour statistics from Vercel server
    /// 
    /// **Performance**: ~140ms server response vs 60+ second local calculations
    /// **Data Sources**: Uses Phish.net for tour structure, Phish.in for durations
    /// - Returns: Complete tour statistics with longest, rarest, and most played songs
    /// - Throws: APIError for network or parsing failures
    func fetchTourStatistics() async throws -> TourSongStatistics {
        return try await tourStatsClient.fetchTourStatistics()
    }
}