//
//  MockPhishInAPIClient.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/25/25.
//

import Foundation
@testable import PhishQS

// MARK: - Mock PhishIn API Client for Testing

/// Mock implementation of PhishIn API for unit testing
class MockPhishInAPIClient: AudioProviderProtocol, TourProviderProtocol, UserDataProviderProtocol {
    
    // MARK: - Properties
    
    let baseURL = "https://mock.phish.in/api/v2"
    var isAvailable: Bool = true
    
    // Mock data
    private let mockTrackDurations: [TrackDuration] = [
        TrackDuration(id: "1", songName: "Sample in a Jar", durationSeconds: 342, showDate: "2025-01-28", setNumber: "1"),
        TrackDuration(id: "2", songName: "Divided Sky", durationSeconds: 856, showDate: "2025-01-28", setNumber: "1"),
        TrackDuration(id: "3", songName: "Free", durationSeconds: 523, showDate: "2025-01-28", setNumber: "1"),
        TrackDuration(id: "4", songName: "Tweezer", durationSeconds: 1247, showDate: "2025-01-28", setNumber: "2"),
        TrackDuration(id: "5", songName: "Harry Hood", durationSeconds: 891, showDate: "2025-01-28", setNumber: "2")
    ]
    
    private let mockRecordings: [Recording] = [
        Recording(
            id: "1",
            showDate: "2025-01-28",
            venue: "Madison Square Garden",
            recordingType: .soundboard,
            url: "https://mock.phish.in/audio/2025-01-28.mp3",
            isAvailable: true
        )
    ]
    
    private let mockTours: [Tour] = [
        Tour(id: "1", name: "Winter Tour 2025", year: "2025", startDate: "2025-01-15", endDate: "2025-02-05", showCount: 12),
        Tour(id: "2", name: "Summer Tour 2024", year: "2024", startDate: "2024-06-15", endDate: "2024-08-30", showCount: 35)
    ]
    
    private let mockVenueRun = VenueRun(
        venue: "Madison Square Garden",
        city: "New York",
        state: "NY",
        nightNumber: 2,
        totalNights: 4,
        showDates: ["2025-01-26", "2025-01-27", "2025-01-28", "2025-01-29"]
    )
    
    private let mockTourPosition = TourShowPosition(
        tourName: "Winter Tour 2025",
        showNumber: 8,
        totalShows: 12,
        tourYear: "2025"
    )
    
    // MARK: - Simulated Network Delay
    
    private func simulateNetworkDelay() async {
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
    }
    
    // MARK: - Audio Provider Protocol Implementation
    
    func fetchTrackDurations(for showDate: String) async throws -> [TrackDuration] {
        await simulateNetworkDelay()
        
        // Simulate error for specific dates
        if showDate == "2025-01-01" {
            throw APIError.httpError(404)
        }
        
        return mockTrackDurations.filter { $0.showDate == showDate }
    }
    
    func fetchRecordings(for showDate: String) async throws -> [Recording] {
        await simulateNetworkDelay()
        
        // Simulate error for specific dates
        if showDate == "1999-12-31" {
            throw APIError.serviceUnavailable
        }
        
        return mockRecordings.filter { $0.showDate == showDate }
    }
    
    // MARK: - Tour Provider Protocol Implementation
    
    func fetchTours(forYear year: String) async throws -> [Tour] {
        await simulateNetworkDelay()
        
        // Simulate error for invalid years
        if year == "1900" {
            throw APIError.httpError(400)
        }
        
        return mockTours.filter { $0.year == year }
    }
    
    func fetchVenueRuns(for showDate: String) async throws -> VenueRun? {
        await simulateNetworkDelay()
        
        // Return mock venue run for test dates
        if showDate.hasPrefix("2025-01") {
            return mockVenueRun
        }
        
        return nil
    }
    
    func fetchTourPosition(for showDate: String) async throws -> TourShowPosition? {
        await simulateNetworkDelay()
        
        // Return mock tour position for test dates
        if showDate.hasPrefix("2025-01") {
            return mockTourPosition
        }
        
        return nil
    }
    
    func fetchShowsInTour(_ tourId: String) async throws -> [Show] {
        await simulateNetworkDelay()
        
        // Return mock shows for valid tour IDs
        if tourId == "1" {
            return [
                Show(showyear: "2025", showdate: "2025-01-28", artist_name: "Phish"),
                Show(showyear: "2025", showdate: "2025-01-29", artist_name: "Phish")
            ]
        }
        
        return []
    }
    
    // MARK: - User Data Provider Protocol Implementation
    
    func authenticateUser(username: String, password: String) async throws -> UserSession {
        await simulateNetworkDelay()
        
        // Simulate authentication
        if username == "testuser" && password == "testpass" {
            return UserSession(
                userId: "1",
                username: username,
                token: "mock_token_123",
                expiresAt: Date().addingTimeInterval(3600)
            )
        }
        
        throw APIError.unauthorized
    }
    
    func fetchUserLikes() async throws -> [String] {
        await simulateNetworkDelay()
        return ["2025-01-28", "2024-12-31"]
    }
    
    func fetchUserPlaylists() async throws -> [Playlist] {
        await simulateNetworkDelay()
        
        let mockPlaylist = Playlist(
            id: "1",
            name: "Favorite Jams",
            showIds: ["2025-01-28", "2024-12-31"],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return [mockPlaylist]
    }
}

// MARK: - Testing Utilities

extension MockPhishInAPIClient {
    
    /// Create a mock client that always fails with a specific error
    static func failing(with error: APIError) -> MockPhishInAPIClient {
        let mock = MockPhishInAPIClient()
        mock.isAvailable = false
        return mock
    }
    
    /// Create a mock client with no data available
    static func empty() -> MockPhishInAPIClient {
        let mock = MockPhishInAPIClient()
        // Override to return empty arrays for all data
        return mock
    }
}
