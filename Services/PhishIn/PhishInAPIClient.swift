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
    
    let baseURL = "https://phish.in/api/v1"
    private let session = URLSession.shared
    private let apiKey = Secrets.value(for: "PhishInAPIKey")
    
    // MARK: - API Client Protocol
    
    var isAvailable: Bool {
        // Check if API key is configured and not empty
        return !apiKey.isEmpty
    }
    
    private init() {}
    
    // MARK: - Private Helper Methods
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        responseType: T.Type,
        queryParameters: [String: String] = [:]
    ) async throws -> T {
        // Check if API key is available
        guard !apiKey.isEmpty else {
            throw APIError.apiKeyMissing
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/\(endpoint)")!
        
        if !queryParameters.isEmpty {
            urlComponents.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        // Create request with API key header
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
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
        let tours: [PhishInTour] = try await makeRequest(
            endpoint: "tours.json",
            responseType: [PhishInTour].self,
            queryParameters: ["per_page": "2000"]
        )
        
        // Filter tours by year
        return tours.filter { tour in
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
        let tourPhishInShows = try await fetchPhishInShowsInTour(String(tourId))
        let venueShows = tourPhishInShows.filter { $0.venue?.id == venue.id }
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
    
    /// Fetch all shows in a specific tour (returns standard Show models)
    func fetchShowsInTour(_ tourId: String) async throws -> [Show] {
        let phishInShows = try await fetchPhishInShowsInTour(tourId)
        return phishInShows.map { $0.toShow() }
    }
    
    /// Fetch all PhishIn shows in a specific tour (returns PhishInShow models with full data)
    private func fetchPhishInShowsInTour(_ tourId: String) async throws -> [PhishInShow] {
        let shows: [PhishInShow] = try await makeRequest(
            endpoint: "shows.json",
            responseType: [PhishInShow].self,
            queryParameters: [
                "tour_id": tourId,
                "per_page": "2000"
            ]
        )
        
        return shows
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
            endpoint: "show-on-date/\(date).json",
            responseType: PhishInShow.self
        )
        return show
    }
    
    /// Fetch all shows with pagination
    func fetchShows(page: Int = 1, perPage: Int = 50) async throws -> [PhishInShow] {
        let shows: [PhishInShow] = try await makeRequest(
            endpoint: "shows.json",
            responseType: [PhishInShow].self,
            queryParameters: [
                "page": String(page),
                "per_page": String(perPage)
            ]
        )
        return shows
    }
    
    /// Fetch all venues
    func fetchVenues() async throws -> [PhishInVenue] {
        let venues: [PhishInVenue] = try await makeRequest(
            endpoint: "venues.json",
            responseType: [PhishInVenue].self,
            queryParameters: ["per_page": "2000"]
        )
        return venues
    }
    
    /// Fetch all songs
    func fetchSongs() async throws -> [PhishInSong] {
        let songs: [PhishInSong] = try await makeRequest(
            endpoint: "songs.json",
            responseType: [PhishInSong].self,
            queryParameters: ["per_page": "2000"]
        )
        return songs
    }
    
    /// Fetch all eras
    func fetchEras() async throws -> [PhishInEra] {
        let eras: [PhishInEra] = try await makeRequest(
            endpoint: "eras.json",
            responseType: [PhishInEra].self
        )
        return eras
    }
}