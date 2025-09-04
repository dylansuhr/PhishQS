//
//  APIManager.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//

import Foundation

// MARK: - Central API Coordinator

/// Central manager that coordinates between different API services
/// Uses Phish.net for tour organization, show counts, venue runs
/// Uses Phish.in for song durations only
class APIManager: ObservableObject {
    
    // MARK: - API Clients
    
    /// Primary setlist data provider (Phish.net)
    private let phishNetClient: PhishAPIService
    
    /// Audio data provider (Phish.in) - durations only
    private let phishInClient: AudioProviderProtocol?
    
    /// Tour data provider (Phish.net)
    private let phishNetTourService: PhishNetTourService
    
    /// Tour statistics provider (Vercel server)
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
    
    /// Fetch the latest show
    func fetchLatestShow() async throws -> Show? {
        return try await phishNetClient.fetchLatestShow()
    }
    
    /// Fetch setlist for a specific date
    func fetchSetlist(for date: String) async throws -> [SetlistItem] {
        return try await phishNetClient.fetchSetlist(for: date)
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
        
        // Get enhanced data: durations from Phish.in, tour/venue data from Phish.net
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
                    print("Warning: Could not fetch gap data from Phish.net for \(date): \(error)")
                    return []
                }
            }
            return []
        }()
        
        // Execute API calls in parallel: Phish.in for durations, Phish.net for tour/venue data
        async let tourContextTask = phishNetTourService.getTourContext(for: date)
        
        if let phishInClient = phishInClient, phishInClient.isAvailable {
            async let trackDurationsTask = phishInClient.fetchTrackDurations(for: date)
            async let recordingsTask = phishInClient.fetchRecordings(for: date)
            
            // Await results with individual error handling
            do {
                trackDurations = try await trackDurationsTask
            } catch {
                print("Warning: Could not fetch track durations from Phish.in for \(date): \(error)")
            }
            
            do {
                recordings = try await recordingsTask
            } catch {
                print("Warning: Could not fetch recording info from Phish.in: \(error)")
            }
        }
        
        // Get tour context from Phish.net
        do {
            let tourContext = try await tourContextTask
            tourPosition = tourContext.tourPosition
            venueRun = tourContext.venueRun
        } catch {
            print("Warning: Could not fetch tour context from Phish.net: \(error)")
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
    
    /// Fetch all track durations for an entire tour
    /// Uses Phish.net for tour show list, Phish.in for durations
    func fetchTourTrackDurations(tourName: String, year: String) async throws -> [TrackDuration] {
        guard let phishInClient = phishInClient else {
            return []
        }
        
        // Get tour shows from Phish.net
        let tourShows = try await phishNetTourService.fetchTourShows(year: year, tourName: tourName)
        var allTourTracks: [TrackDuration] = []
        
        // Fetch durations from Phish.in for each show
        for show in tourShows {
            do {
                let trackDurations = try await phishInClient.fetchTrackDurations(for: show.showdate)
                allTourTracks.append(contentsOf: trackDurations)
            } catch {
                print("Warning: Could not fetch durations for \(show.showdate): \(error)")
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
            print("Could not fetch tour name for \(showDate): \(error)")
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
    
    /// Check if enhanced data services (Phish.in) are available
    var isEnhancedDataAvailable: Bool {
        return phishInClient?.isAvailable ?? false
    }
    
    /// Get list of available data sources
    var availableDataSources: [String] {
        var sources = ["Phish.net (Setlists)"]
        if isEnhancedDataAvailable {
            sources.append("Phish.in (Audio Only)")
        }
        sources.append("Phish.net (Tours & Venues)")
        if tourStatsClient.isAvailable {
            sources.append("Vercel Server (Statistics)")
        }
        return sources
    }
    
    // MARK: - Tour Statistics Operations (Primary Source: Vercel Server)
    
    /// Fetch pre-computed tour statistics from server
    /// - Returns: Complete tour statistics with longest, rarest, and most played songs
    /// - Throws: APIError for network or parsing failures
    func fetchTourStatistics() async throws -> TourSongStatistics {
        return try await tourStatsClient.fetchTourStatistics()
    }
}