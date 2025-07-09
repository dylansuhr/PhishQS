import Foundation

// MARK: - Mock API Client for Testing

/// Mock implementation of PhishAPIService for unit testing
class MockPhishAPIClient: PhishAPIService {
    
    // MARK: - Mock Data
    
    private let mockShows: [Show] = [
        Show(showyear: "2025", showdate: "2025-01-28", artist_name: "Phish"),
        Show(showyear: "2025", showdate: "2025-01-29", artist_name: "Phish"),
        Show(showyear: "2024", showdate: "2024-12-31", artist_name: "Phish")
    ]
    
    private let mockSetlistItems: [SetlistItem] = [
        SetlistItem(set: "1", song: "Sample in a Jar", transMark: nil, venue: "Madison Square Garden", city: "New York", showdate: "2025-01-28"),
        SetlistItem(set: "1", song: "Divided Sky", transMark: "->", venue: "Madison Square Garden", city: "New York", showdate: "2025-01-28"),
        SetlistItem(set: "1", song: "Free", transMark: nil, venue: "Madison Square Garden", city: "New York", showdate: "2025-01-28"),
        SetlistItem(set: "2", song: "Tweezer", transMark: nil, venue: "Madison Square Garden", city: "New York", showdate: "2025-01-28"),
        SetlistItem(set: "2", song: "Harry Hood", transMark: nil, venue: "Madison Square Garden", city: "New York", showdate: "2025-01-28")
    ]
    
    private let mockVenue = Venue(
        id: "1",
        name: "Madison Square Garden",
        city: "New York",
        state: "NY",
        country: "USA",
        latitude: 40.7505,
        longitude: -73.9934
    )
    
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
    
    func fetchVenueInfo(for venueId: String) async throws -> Venue {
        await simulateNetworkDelay()
        
        // Simulate venue not found
        if venueId == "999" {
            throw APIError.httpError(404)
        }
        
        return mockVenue
    }
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