//
//  PhishInAPIClient.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/25/25.
//

import Foundation

// MARK: - PhishIn API Client

/// API client for Phish.in - provides song durations, tour metadata, and audio recordings
class PhishInAPIClient: AudioProviderProtocol, TourProviderProtocol {
    
    // MARK: - Properties
    
    static let shared = PhishInAPIClient()
    
    let baseURL = "https://phish.in/api/v2"
    private let session = URLSession.shared
    // No API key required for v2 API
    
    // Simple cache to avoid duplicate API calls for same tour
    private var tourShowsCache: [String: [PhishInShow]] = [:]
    private let cacheQueue = DispatchQueue(label: "phishin.cache", attributes: .concurrent)
    
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
            let result = try JSONDecoder().decode(T.self, from: data)
            
            
            return result
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
              let tourName = phishInShow.tour_name else {
            return nil
        }
        
        let venueSlug = venue.slug ?? venue.name.lowercased().replacingOccurrences(of: " ", with: "-")
        
        // Get tour shows with caching to avoid duplicate API calls
        let allTourShows = try await getCachedTourShows(tourName: tourName)
        
        // Filter tour shows to this venue only (already filtered by exact tour name)
        let venueShows = allTourShows
            .filter { $0.venue?.slug == venue.slug || $0.venue?.name == venue.name }
            .sorted(by: { $0.date < $1.date })
        
        // Only create venue run if there are multiple nights
        guard venueShows.count > 1,
              let currentShowIndex = venueShows.firstIndex(where: { $0.date == showDate }) else {
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
        
        guard let tourName = phishInShow.tour_name else {
            return nil
        }
        
        // Get tour shows with caching to avoid duplicate API calls
        let tourShows = try await getCachedTourShows(tourName: tourName)
        
        guard let currentShowIndex = tourShows.firstIndex(where: { $0.date == showDate }) else {
            return nil
        }
        
        // Extract year from date or tour name
        let tourYear = String(showDate.prefix(4))
        
        return TourShowPosition(
            tourName: tourName,
            showNumber: currentShowIndex + 1,
            totalShows: tourShows.count,
            tourYear: tourYear
        )
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
    
    // MARK: - Caching Methods
    
    /// Get tour shows with caching to avoid duplicate API calls
    private func getCachedTourShows(tourName: String) async throws -> [PhishInShow] {
        // Check cache first (thread-safe)
        if let cached = await withCheckedContinuation({ continuation in
            cacheQueue.async {
                continuation.resume(returning: self.tourShowsCache[tourName])
            }
        }) {
            return cached
        }
        
        let tourShowsResponse: PhishInShowsResponse = try await makeRequest(
            endpoint: "shows",
            responseType: PhishInShowsResponse.self,
            queryParameters: [
                "tour_name": tourName,
                "per_page": "500"
            ]
        )
        
        // Filter to EXACT tour name match only and cache the result
        let exactTourShows = tourShowsResponse.shows
            .filter { $0.tour_name == tourName }
            .sorted(by: { $0.date < $1.date })
        
        // Cache the result (thread-safe)
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                self.tourShowsCache[tourName] = exactTourShows
                continuation.resume()
            }
        }
        
        return exactTourShows
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