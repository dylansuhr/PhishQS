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
        
        // Get venue information from the show
        let venueName = show.venue?.name
        
        // Fetch venue run information for this show
        var venueRun: VenueRun? = nil
        do {
            venueRun = try await fetchVenueRuns(for: showDate)
        } catch {
            // Continue without venue run info if fetch fails
        }
        
        return tracks.compactMap { track in
            track.toTrackDuration(
                showDate: showDate,
                venue: venueName,
                venueRun: venueRun
            )
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
        
        // Try exact match first
        let exactShows = try await fetchShowsForTourName(tourName)
        if !exactShows.isEmpty {
            // Cache and return exact matches
            await withCheckedContinuation { continuation in
                cacheQueue.async(flags: .barrier) {
                    self.tourShowsCache[tourName] = exactShows
                    continuation.resume()
                }
            }
            return exactShows
        }
        
        // If no exact matches, try fuzzy matching
        let fuzzyMatches = try await tryFuzzyTourMatching(originalTourName: tourName)
        
        // Cache the result (even if empty)
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                self.tourShowsCache[tourName] = fuzzyMatches
                continuation.resume()
            }
        }
        
        return fuzzyMatches
    }
    
    /// Try to fetch shows for a specific tour name
    private func fetchShowsForTourName(_ tourName: String) async throws -> [PhishInShow] {
        let tourShowsResponse: PhishInShowsResponse = try await makeRequest(
            endpoint: "shows",
            responseType: PhishInShowsResponse.self,
            queryParameters: [
                "tour_name": tourName,
                "per_page": "500"
            ]
        )
        
        return tourShowsResponse.shows
            .filter { $0.tour_name == tourName }
            .sorted(by: { $0.date < $1.date })
    }
    
    /// Try different tour name variations if exact match fails
    private func tryFuzzyTourMatching(originalTourName: String) async throws -> [PhishInShow] {
        let variations = generateTourNameVariations(originalTourName)
        
        for variation in variations {
            let shows = try await fetchShowsForTourName(variation)
            if !shows.isEmpty {
                return shows
            }
        }
        
        return []
    }
    
    /// Generate different variations of tour names to try
    private func generateTourNameVariations(_ originalTourName: String) -> [String] {
        var variations: [String] = []
        
        // Common patterns for tour names
        if originalTourName.contains("Summer Tour") {
            let year = originalTourName.replacingOccurrences(of: "Summer Tour ", with: "")
            variations.append("Summer \(year)")
            variations.append("\(year) Summer Tour")
            variations.append("Summer '\(year.suffix(2))")
        } else if originalTourName.contains("Winter Tour") {
            let year = originalTourName.replacingOccurrences(of: "Winter Tour ", with: "")
            variations.append("Winter \(year)")
            variations.append("\(year) Winter Tour")
            variations.append("Winter '\(year.suffix(2))")
        } else if originalTourName.contains("Fall Tour") {
            let year = originalTourName.replacingOccurrences(of: "Fall Tour ", with: "")
            variations.append("Fall \(year)")
            variations.append("\(year) Fall Tour")
            variations.append("Fall '\(year.suffix(2))")
        }
        
        return variations.filter { !$0.isEmpty }
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
    
    /// Fetch all track durations for an entire tour
    func fetchTourTrackDurations(tourName: String) async throws -> [TrackDuration] {
        // Check cache first
        let cacheKey = CacheManager.CacheKeys.tourTrackDurations(tourName)
        if let cachedTracks = CacheManager.shared.get([TrackDuration].self, forKey: cacheKey) {
            return cachedTracks
        }
        
        // Get basic show list for the tour (dates only)
        let tourShowList = try await getCachedTourShows(tourName: tourName)
        
        var allTourTracks: [TrackDuration] = []
        
        // Use TaskGroup for parallel processing instead of sequential
        allTourTracks = await withTaskGroup(of: [TrackDuration].self, returning: [TrackDuration].self) { group in
            // Add tasks for each show
            for showBasic in tourShowList {
                group.addTask {
                    do {
                        // Fetch complete show data including tracks
                        let detailedShow = try await self.fetchShowByDate(showBasic.date)
                        
                        guard let tracks = detailedShow.tracks else { 
                            return []
                        }
                        
                        // Get venue information from the show
                        let venueName = detailedShow.venue?.name
                        
                        // Fetch venue run information for this show (if needed)
                        var venueRun: VenueRun? = nil
                        do {
                            venueRun = try await self.fetchVenueRuns(for: showBasic.date)
                        } catch {
                            // Continue without venue run info if fetch fails
                        }
                        
                        return tracks.compactMap { track in
                            track.toTrackDuration(
                                showDate: showBasic.date,
                                venue: venueName,
                                venueRun: venueRun
                            )
                        }
                        
                    } catch {
                        return []
                    }
                }
            }
            
            // Collect all results
            var results: [TrackDuration] = []
            for await showTracks in group {
                results.append(contentsOf: showTracks)
            }
            return results
        }
        
        // Cache the result for 2 hours
        CacheManager.shared.set(allTourTracks, forKey: cacheKey, ttl: CacheManager.TTL.tourTrackDurations)
        
        return allTourTracks
    }
}