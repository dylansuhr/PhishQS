//
//  APIManager.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//

import Foundation

// Re-export all the core types and protocols for easy access
@_exported import Foundation

// MARK: - Central API Coordinator

/// Central manager that coordinates between different API services
class APIManager: ObservableObject {
    
    // MARK: - API Clients
    
    /// Primary setlist data provider (Phish.net)
    private let phishNetClient: PhishAPIService
    
    // MARK: - Initialization
    
    init(phishNetClient: PhishAPIService = PhishAPIClient.shared) {
        self.phishNetClient = phishNetClient
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
    
    /// Fetch venue information
    func fetchVenueInfo(for venueId: String) async throws -> Venue {
        return try await phishNetClient.fetchVenueInfo(for: venueId)
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
}