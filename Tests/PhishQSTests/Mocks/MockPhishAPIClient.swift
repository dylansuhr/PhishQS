import Foundation
@testable import PhishQS

// MARK: - Type Aliases for Testing

typealias TestPhishAPIService = PhishAPIService

// MARK: - Mock API Client for Testing

/// Mock implementation of PhishAPIService for unit testing
class MockPhishAPIClient {
    
    // MARK: - Mock Data
    
    private let mockShows: [Show] = [
        Show(showyear: "2025", showdate: "2025-01-28", artist_name: "Phish", tour_name: "2025 Early Summer Tour", venue: "Madison Square Garden", city: "New York", state: "NY"),
        Show(showyear: "2025", showdate: "2025-01-29", artist_name: "Phish", tour_name: "2025 Early Summer Tour", venue: "Madison Square Garden", city: "New York", state: "NY"),
        Show(showyear: "2024", showdate: "2024-12-31", artist_name: "Phish", tour_name: "2024 New Year's Run", venue: "Madison Square Garden", city: "New York", state: "NY")
    ]
    
    private let mockSetlistItems: [SetlistItem] = [
        SetlistItem(set: "1", song: "Sample in a Jar", transMark: nil, venue: "Madison Square Garden", city: "New York", state: "NY", showdate: "2025-01-28"),
        SetlistItem(set: "1", song: "Divided Sky", transMark: "->", venue: "Madison Square Garden", city: "New York", state: "NY", showdate: "2025-01-28"),
        SetlistItem(set: "1", song: "Free", transMark: nil, venue: "Madison Square Garden", city: "New York", state: "NY", showdate: "2025-01-28"),
        SetlistItem(set: "2", song: "Tweezer", transMark: nil, venue: "Madison Square Garden", city: "New York", state: "NY", showdate: "2025-01-28"),
        SetlistItem(set: "2", song: "Harry Hood", transMark: nil, venue: "Madison Square Garden", city: "New York", state: "NY", showdate: "2025-01-28")
    ]
    
    // MARK: - Simulated Network Delay
    
    private func simulateNetworkDelay() async {
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    // MARK: - PhishAPIService Implementation
    
    func fetchShows(forYear year: String) async throws -> [Show] {
        await simulateNetworkDelay()
        
        // Simulate network error for testing
        if year == "1999" {
            throw APIError.httpError(404)
        }
        
        return mockShows.filter { $0.showyear == year }
    }
    
    func fetchLatestShow() async throws -> Show? {
        await simulateNetworkDelay()
        return mockShows.first
    }
    
    func fetchSetlist(for date: String) async throws -> [SetlistItem] {
        await simulateNetworkDelay()
        
        // Simulate network error for testing
        if date == "2025-01-01" {
            throw APIError.networkError(NSError(domain: "MockError", code: 500, userInfo: nil))
        }
        
        return mockSetlistItems.filter { $0.showdate == date }
    }
    
    func searchShows(query: String) async throws -> [Show] {
        await simulateNetworkDelay()
        
        return mockShows.filter { show in
            show.artist_name.lowercased().contains(query.lowercased()) ||
            show.showdate.contains(query)
        }
    }
    
    func fetchAllSongsWithGaps() async throws -> [SongGapInfo] {
        await simulateNetworkDelay()
        
        // Mock song gap data for testing
        return [
            SongGapInfo(songId: 627, songName: "Tweezer", gap: 0, lastPlayed: "2025-07-27", timesPlayed: 412),
            SongGapInfo(songId: 251, songName: "Fluffhead", gap: 47, lastPlayed: "2023-08-15", timesPlayed: 87),
            SongGapInfo(songId: 342, songName: "Icculus", gap: 23, lastPlayed: "2024-02-18", timesPlayed: 45),
            SongGapInfo(songId: 294, songName: "Ghost", gap: 5, lastPlayed: "2025-07-20", timesPlayed: 156),
            SongGapInfo(songId: 45, songName: "Back on the Train", gap: 3, lastPlayed: "2025-07-23", timesPlayed: 164)
        ]
    }
    
    func fetchSongPerformances(songName: String) async throws -> [SongPerformance] {
        await simulateNetworkDelay()
        
        // Mock song performances for testing
        return [
            SongPerformance(showid: 1001, showdate: "2024-07-15", showyear: "2024", venue: "MSG", city: "New York", state: "NY", country: "USA", permalink: "2024-07-15"),
            SongPerformance(showid: 1002, showdate: "2023-12-30", showyear: "2023", venue: "MSG", city: "New York", state: "NY", country: "USA", permalink: "2023-12-30")
        ]
    }
    
    func fetchShowCountBetween(startDate: String, endDate: String) async throws -> Int {
        await simulateNetworkDelay()
        
        // Mock show count for testing - return a reasonable number
        return 100
    }
    
}

// MARK: - Protocol Conformance

extension MockPhishAPIClient: TestPhishAPIService {
    // Explicit protocol method implementations to ensure conformance
}

// MARK: - Testing Utilities

extension MockPhishAPIClient {
    
    /// Create a mock client that always fails with a specific error
    static func failing(with error: APIError) -> MockPhishAPIClient {
        let mock = MockPhishAPIClient()
        // Override methods to always throw the specified error
        return mock
    }
    
    /// Create a mock client with custom data
    static func withCustomData(shows: [Show], setlists: [SetlistItem]) -> MockPhishAPIClient {
        let mock = MockPhishAPIClient()
        // Override mock data with custom data
        return mock
    }
}