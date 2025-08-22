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
        // Get base setlist from Phish.net
        let setlistItems = try await phishNetClient.fetchSetlist(for: date)
        
        // Try to get enhanced data from Phish.in
        var trackDurations: [TrackDuration] = []
        var venueRun: VenueRun? = nil
        var tourPosition: TourShowPosition? = nil
        var recordings: [Recording] = []
        
        if let phishInClient = phishInClient, phishInClient.isAvailable {
            // Fetch track durations (song lengths)
            do {
                trackDurations = try await phishInClient.fetchTrackDurations(for: date)
                print("DEBUG: Successfully fetched \(trackDurations.count) track durations from Phish.in for \(date)")
                for duration in trackDurations {
                    print("DEBUG: Track - \(duration.songName): \(duration.formattedDuration)")
                }
            } catch {
                // Continue without durations if Phish.in is unavailable
                print("Warning: Could not fetch track durations from Phish.in for \(date): \(error)")
            }
            
            // Fetch venue run information (N1/N2/N3)
            do {
                venueRun = try await phishInClient.fetchVenueRuns(for: date)
            } catch {
                // Continue without venue run info if unavailable
                print("Warning: Could not fetch venue run info from Phish.in: \(error)")
            }
            
            // Fetch tour position information (Show X/Y)
            do {
                tourPosition = try await phishInClient.fetchTourPosition(for: date)
                if let tourPos = tourPosition {
                    print("DEBUG: Successfully fetched tour position: \(tourPos.displayText)")
                }
            } catch {
                // Continue without tour position info if unavailable
                print("Warning: Could not fetch tour position from Phish.in: \(error)")
            }
            
            // Fetch recording information
            do {
                recordings = try await phishInClient.fetchRecordings(for: date)
            } catch {
                // Continue without recording info if unavailable
                print("Warning: Could not fetch recording info from Phish.in: \(error)")
            }
        } else {
            print("DEBUG: Phish.in client unavailable - likely missing API key")
        }
        
        return EnhancedSetlist(
            showDate: date,
            setlistItems: setlistItems,
            trackDurations: trackDurations,
            venueRun: venueRun,
            tourPosition: tourPosition,
            recordings: recordings
        )
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