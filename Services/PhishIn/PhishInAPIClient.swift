//
//  PhishInAPIClient.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/25/25.
//

import Foundation

// MARK: - PhishIn API Client

/// API client for Phish.in - provides song durations, tour metadata, and audio recordings
class PhishInAPIClient: AudioProviderProtocol, TourProviderProtocol, UserDataProviderProtocol {
    
    // MARK: - Properties
    
    static let shared = PhishInAPIClient()
    
    let baseURL = "https://phish.in/api/v2"
    private let session = URLSession.shared
    // No API key required for v2 API
    
    // MARK: - API Client Protocol
    
    var isAvailable: Bool {
        // v2 API doesn't require authentication
        return true
    }
    
    private init() {}
    
    // MARK: - Private Helper Methods
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        responseType: T.Type,
        queryParameters: [String: String] = [:]
    ) async throws -> T {
        // v2 API doesn't require authentication
        
        var urlComponents = URLComponents(string: "\(baseURL)/\(endpoint)")!
        
        if !queryParameters.isEmpty {
            urlComponents.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        // Create request (no authentication required for v2)
        let request = URLRequest(url: url)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Audio Provider Protocol Implementation
    
    /// Fetch track durations for a specific show date
    func fetchTrackDurations(for showDate: String) async throws -> [TrackDuration] {
        // First get the show data for the date
        let show = try await fetchShowByDate(showDate)
        
        guard let tracks = show.tracks else {
            return []
        }
        
        return tracks.compactMap { track in
            track.toTrackDuration(showDate: showDate)
        }
    }
    
    /// Fetch recording information for a specific show date
    func fetchRecordings(for showDate: String) async throws -> [Recording] {
        let show = try await fetchShowByDate(showDate)
        
        // Convert PhishIn show to Recording model
        let recording = Recording(
            id: String(show.id),
            showDate: showDate,
            venue: show.venue?.name ?? "Unknown Venue",
            recordingType: show.sbd == true ? .soundboard : .audience,
            url: show.tracks?.first?.mp3,
            isAvailable: !(show.missing ?? false)
        )
        
        return [recording]
    }
    
    // MARK: - Tour Provider Protocol Implementation
    
    /// Fetch tours for a specific year
    func fetchTours(forYear year: String) async throws -> [Tour] {
        let response: PhishInToursResponse = try await makeRequest(
            endpoint: "tours",
            responseType: PhishInToursResponse.self,
            queryParameters: ["per_page": "2000"]
        )
        
        // Filter tours by year
        return response.tours.filter { tour in
            tour.starts_on?.hasPrefix(year) == true
        }.map { $0.toTour() }
    }
    
    /// Fetch venue run information for a specific show date
    func fetchVenueRuns(for showDate: String) async throws -> VenueRun? {
        let phishInShow = try await fetchShowByDate(showDate)
        
        guard let venue = phishInShow.venue,
              let tourId = phishInShow.tour_id else {
            return nil
        }
        
        // Get all shows in the same tour at the same venue
        let tourResponse = try await fetchPhishInShowsInTour(String(tourId))
        let venueShows = tourResponse.shows.filter { $0.venue?.slug == venue.slug }
            .sorted(by: { $0.date < $1.date })
        
        guard let currentShowIndex = venueShows.firstIndex(where: { $0.date == showDate }) else {
            return nil
        }
        
        return VenueRun(
            venue: venue.name,
            city: venue.location?.components(separatedBy: ", ").first ?? "",
            state: venue.location?.components(separatedBy: ", ").dropFirst().first,
            nightNumber: currentShowIndex + 1,
            totalNights: venueShows.count,
            showDates: venueShows.map { $0.date }
        )
    }
    
    /// Fetch tour position information for a specific show date
    func fetchTourPosition(for showDate: String) async throws -> TourShowPosition? {
        let phishInShow = try await fetchShowByDate(showDate)
        
        guard let tour = phishInShow.tour,
              let tourId = phishInShow.tour_id else {
            return nil
        }
        
        // Get all shows in the same tour
        let tourResponse = try await fetchPhishInShowsInTour(String(tourId))
        let tourShows = tourResponse.shows.sorted(by: { $0.date < $1.date })
        
        guard let currentShowIndex = tourShows.firstIndex(where: { $0.date == showDate }) else {
            return nil
        }
        
        return TourShowPosition(
            tourName: tour.name,
            showNumber: currentShowIndex + 1,
            totalShows: tourShows.count,
            tourYear: String(tour.starts_on?.prefix(4) ?? "")
        )
    }
    
    /// Fetch all shows in a specific tour (returns standard Show models)
    func fetchShowsInTour(_ tourId: String) async throws -> [Show] {
        let response = try await fetchPhishInShowsInTour(tourId)
        return response.shows.map { $0.toShow() }
    }
    
    /// Fetch all PhishIn shows in a specific tour (returns PhishInShow models with full data)
    private func fetchPhishInShowsInTour(_ tourId: String) async throws -> PhishInShowsResponse {
        let response: PhishInShowsResponse = try await makeRequest(
            endpoint: "shows",
            responseType: PhishInShowsResponse.self,
            queryParameters: [
                "tour_id": tourId,
                "per_page": "2000"
            ]
        )
        
        return response
    }
    
    // MARK: - User Data Provider Protocol Implementation
    
    /// Authenticate user with Phish.in
    func authenticateUser(username: String, password: String) async throws -> UserSession {
        // Note: This would require POST request implementation
        // For now, return a placeholder implementation
        throw APIError.notImplemented
    }
    
    /// Fetch user's liked shows
    func fetchUserLikes() async throws -> [String] {
        // Requires authentication - placeholder implementation
        throw APIError.notImplemented
    }
    
    /// Fetch user's playlists
    func fetchUserPlaylists() async throws -> [Playlist] {
        // Requires authentication - placeholder implementation
        throw APIError.notImplemented
    }
    
    // MARK: - Additional Public Methods
    
    /// Fetch show data by date
    func fetchShowByDate(_ date: String) async throws -> PhishInShow {
        let show: PhishInShow = try await makeRequest(
            endpoint: "shows/\(date)",
            responseType: PhishInShow.self
        )
        return show
    }
    
    /// Fetch all shows with pagination
    func fetchShows(page: Int = 1, perPage: Int = 50) async throws -> PhishInShowsResponse {
        let response: PhishInShowsResponse = try await makeRequest(
            endpoint: "shows",
            responseType: PhishInShowsResponse.self,
            queryParameters: [
                "page": String(page),
                "per_page": String(perPage)
            ]
        )
        return response
    }
    
    /// Fetch all venues
    func fetchVenues() async throws -> [PhishInVenue] {
        let response: PhishInVenuesResponse = try await makeRequest(
            endpoint: "venues",
            responseType: PhishInVenuesResponse.self,
            queryParameters: ["per_page": "2000"]
        )
        return response.venues
    }
    
    /// Fetch all songs
    func fetchSongs() async throws -> [PhishInSong] {
        let response: PhishInSongsResponse = try await makeRequest(
            endpoint: "songs",
            responseType: PhishInSongsResponse.self,
            queryParameters: ["per_page": "2000"]
        )
        return response.songs
    }
    
    /// Fetch all eras
    func fetchEras() async throws -> [PhishInEra] {
        let response: PhishInErasResponse = try await makeRequest(
            endpoint: "eras",
            responseType: PhishInErasResponse.self
        )
        return response.eras
    }
}