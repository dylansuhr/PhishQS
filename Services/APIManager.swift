//
//  APIManager.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//

import Foundation

// MARK: - Central API Coordinator

/// Central manager that coordinates between different API services
class APIManager: ObservableObject {
    
    // MARK: - API Clients
    
    /// Primary setlist data provider (Phish.net)
    private let phishNetClient: PhishAPIService
    
    /// Audio and tour data provider (Phish.in)
    private let phishInClient: (AudioProviderProtocol & TourProviderProtocol)?
    
    // MARK: - Initialization
    
    init(
        phishNetClient: PhishAPIService = PhishAPIClient.shared,
        phishInClient: (AudioProviderProtocol & TourProviderProtocol)? = PhishInAPIClient.shared
    ) {
        self.phishNetClient = phishNetClient
        self.phishInClient = phishInClient
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
        
        // Try to get enhanced data from Phish.in and gap data from Phish.net
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
        
        if let phishInClient = phishInClient, phishInClient.isAvailable {
            // Execute all Phish.in API calls in parallel for better performance
            async let trackDurationsTask = phishInClient.fetchTrackDurations(for: date)
            async let venueRunTask = phishInClient.fetchVenueRuns(for: date)
            async let tourPositionTask = phishInClient.fetchTourPosition(for: date)
            async let recordingsTask = phishInClient.fetchRecordings(for: date)
            
            // Await results with individual error handling
            do {
                trackDurations = try await trackDurationsTask
            } catch {
                print("Warning: Could not fetch track durations from Phish.in for \(date): \(error)")
            }
            
            do {
                venueRun = try await venueRunTask
            } catch {
                print("Warning: Could not fetch venue run info from Phish.in: \(error)")
            }
            
            do {
                tourPosition = try await tourPositionTask
            } catch {
                print("Warning: Could not fetch tour position from Phish.in: \(error)")
            }
            
            do {
                recordings = try await recordingsTask
            } catch {
                print("Warning: Could not fetch recording info from Phish.in: \(error)")
            }
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
    
    /// Fetch tours for a specific year from Phish.in
    func fetchTours(forYear year: String) async throws -> [Tour] {
        guard let phishInClient = phishInClient else {
            throw APIError.serviceUnavailable
        }
        return try await phishInClient.fetchTours(forYear: year)
    }
    
    /// Fetch track durations for a specific show
    func fetchTrackDurations(for showDate: String) async throws -> [TrackDuration] {
        guard let phishInClient = phishInClient else {
            return []
        }
        return try await phishInClient.fetchTrackDurations(for: showDate)
    }
    
    /// Fetch venue run information for a specific show
    func fetchVenueRuns(for showDate: String) async throws -> VenueRun? {
        guard let phishInClient = phishInClient else {
            return nil
        }
        return try await phishInClient.fetchVenueRuns(for: showDate)
    }
    
    /// Fetch recording information for a specific show
    func fetchRecordings(for showDate: String) async throws -> [Recording] {
        guard let phishInClient = phishInClient else {
            return []
        }
        return try await phishInClient.fetchRecordings(for: showDate)
    }
    
    /// Fetch tour position information for a specific show
    func fetchTourPosition(for showDate: String) async throws -> TourShowPosition? {
        guard let phishInClient = phishInClient else {
            return nil
        }
        return try await phishInClient.fetchTourPosition(for: showDate)
    }
    
    /// Fetch all track durations for an entire tour
    func fetchTourTrackDurations(tourName: String) async throws -> [TrackDuration] {
        guard let phishInClient = phishInClient else {
            return []
        }
        return try await phishInClient.fetchTourTrackDurations(tourName: tourName)
    }
    
    /// Fetch all shows for a specific tour using existing Phish.in infrastructure
    func fetchTourShows(tourName: String) async throws -> [Show] {
        guard let phishInClient = phishInClient as? PhishInAPIClient else {
            throw APIError.noData
        }
        
        // Use existing getCachedTourShows from PhishIn (it's private, so we need to use the public method)
        // We can get tour shows through the existing fetchTourTrackDurations infrastructure
        let tourTracks = try await phishInClient.fetchTourTrackDurations(tourName: tourName)
        
        // Extract unique show dates from tour tracks
        let uniqueShowDates = Set(tourTracks.map { $0.showDate })
        
        // Convert to Show objects
        let shows = uniqueShowDates.map { showDate in
            Show(
                showyear: String(showDate.prefix(4)),
                showdate: showDate,
                artist_name: "Phish"
            )
        }
        
        return shows.sorted { $0.showdate < $1.showdate }
    }
    
    /// Get the native tour name from Phish.in for a specific show date
    func getNativeTourName(for showDate: String) async throws -> String? {
        guard let phishInClient = phishInClient as? PhishInAPIClient else {
            return nil
        }
        
        do {
            let phishInShow = try await phishInClient.fetchShowByDate(showDate)
            return phishInShow.tour_name
        } catch {
            print("Could not fetch native tour name for \(showDate): \(error)")
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
            sources.append("Phish.in (Audio & Tours)")
        }
        return sources
    }
}