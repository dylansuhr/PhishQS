import Foundation
import SwiftLogger

// MARK: - Venue Model

struct Venue: Codable, Identifiable {
    let id: String
    let name: String
    let city: String
    let state: String?
    let country: String
    let latitude: Double?
    let longitude: Double?
}

// MARK: - Enhanced API Client

/// Modern async/await API client for Phish.net API
class PhishAPIClient: PhishAPIService {
    static let shared = PhishAPIClient()  // singleton instance

    internal let baseURL = "https://api.phish.net/v5"
    private let apiKey = Secrets.value(for: "PhishNetAPIKey")
    
    var isAvailable: Bool {
        return !apiKey.isEmpty
    }
    
    // MARK: - Show Methods
    
    /// Fetch all shows for a given year
    func fetchShows(forYear year: String) async throws -> [Show] {
        // Remove cache-busting for better performance - year data doesn't change frequently
        guard let url = URL(string: "\(baseURL)/setlists/showyear/\(year).json?apikey=\(apiKey)&artist=phish") else {
            throw APIError.invalidURL
        }

        let request = URLRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            let showResponse = try JSONDecoder().decode(ShowResponse.self, from: data)
            return showResponse.data
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// Fetch the latest show (most recent chronologically)
    func fetchLatestShow() async throws -> Show? {
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Try current year first
        do {
            let shows = try await fetchShows(forYear: String(currentYear))
            let phishShows = APIUtilities.filterPhishShows(shows)
            let sortedShows = phishShows.sorted { $0.showdate > $1.showdate }
            if let latestShow = sortedShows.first {
                return latestShow
            }
        } catch {
            // Continue to try previous year
        }
        
        // Try previous year if no Phish shows this year
        let previousYear = currentYear - 1
        let previousShows = try await fetchShows(forYear: String(previousYear))
        let phishShows = APIUtilities.filterPhishShows(previousShows)
        let sortedShows = phishShows.sorted { $0.showdate > $1.showdate }
        return sortedShows.first
    }
    
    /// Search shows by query (venue, city, etc.)
    func searchShows(query: String) async throws -> [Show] {
        guard let url = URL(string: "\(baseURL)/setlists/search.json?apikey=\(apiKey)&artist=phish&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            let showResponse = try JSONDecoder().decode(ShowResponse.self, from: data)
            return showResponse.data
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Setlist Methods
    
    /// Fetch setlist for a specific show date
    func fetchSetlist(for date: String) async throws -> [SetlistItem] {
        // Remove cache-busting for better performance - historical setlists don't change
        guard let url = URL(string: "\(baseURL)/setlists/showdate/\(date).json?apikey=\(apiKey)&artist=phish") else {
            throw APIError.invalidURL
        }

        let request = URLRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            let setlistResponse = try JSONDecoder().decode(SetlistResponse.self, from: data)
            return setlistResponse.data
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Song Gap Methods
    
    /// Fetch all songs with gap information for tour statistics
    func fetchAllSongsWithGaps() async throws -> [SongGapInfo] {
        // Check cache first - song gaps change rarely
        if let cachedGaps = CacheManager.shared.get([SongGapInfo].self, forKey: CacheManager.CacheKeys.songGaps) {
            return cachedGaps
        }
        
        // Fetch from API if not cached
        guard let url = URL(string: "\(baseURL)/songs.json?apikey=\(apiKey)") else {
            throw APIError.invalidURL
        }

        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            let songsResponse = try JSONDecoder().decode(SongsResponse.self, from: data)
            
            // Convert API response to SongGapInfo objects
            let gapInfo = songsResponse.data.map { songData in
                SongGapInfo(
                    songId: songData.songid,
                    songName: songData.song,
                    gap: songData.gap,
                    lastPlayed: songData.last_played,
                    timesPlayed: songData.times_played
                )
            }
            
            // Cache the result for 6 hours
            CacheManager.shared.set(gapInfo, forKey: CacheManager.CacheKeys.songGaps, ttl: CacheManager.TTL.songGaps)
            
            return gapInfo
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Venue Methods
    
    /// Fetch all performances of a specific song with chronological ordering
    func fetchSongPerformances(songName: String) async throws -> [SongPerformance] {
        // Use song slug endpoint for better performance with chronological ordering
        let encodedSongName = songName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? songName
        guard let url = URL(string: "\(baseURL)/setlists/song/\(encodedSongName).json?apikey=\(apiKey)&order_by=showdate&direction=asc") else {
            throw APIError.invalidURL
        }

        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            let performanceResponse = try JSONDecoder().decode(SongPerformanceResponse.self, from: data)
            return performanceResponse.data
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// Fetch total number of Phish shows between two dates (inclusive)
    /// Used for calculating historical gaps
    func fetchShowCountBetween(startDate: String, endDate: String) async throws -> Int {
        // Use a more efficient approach by fetching years and counting
        // Parse start and end years
        let startYear = String(startDate.prefix(4))
        let endYear = String(endDate.prefix(4))
        
        var totalShows = 0
        
        // Convert years to integers for range
        guard let startYearInt = Int(startYear), let endYearInt = Int(endYear) else {
            throw APIError.invalidURL
        }
        
        // Fetch shows for each year in the range
        for year in startYearInt...endYearInt {
            let yearShows = try await fetchShows(forYear: String(year))
            
            // Filter shows to date range
            let filteredShows = yearShows.filter { show in
                show.showdate >= startDate && show.showdate <= endDate
            }
            
            totalShows += filteredShows.count
        }
        
        return totalShows
    }
    
    /// Fetch venue information by venue ID
    func fetchVenueInfo(for venueId: String) async throws -> Venue {
        guard let url = URL(string: "\(baseURL)/venues/\(venueId).json?apikey=\(apiKey)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            let venueResponse = try JSONDecoder().decode(VenueResponse.self, from: data)
            return venueResponse.data
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Response Models

struct VenueResponse: Codable {
    let data: Venue
}

struct SongPerformanceResponse: Codable {
    let data: [SongPerformance]
}

// MARK: - Song Gap Response Models

struct SongData: Codable {
    let songid: Int
    let song: String
    let slug: String
    let artist: String
    let debut: String
    let last_played: String
    let times_played: Int
    let gap: Int
}

struct SongsResponse: Codable {
    let data: [SongData]
}

// MARK: - Gap Data Provider Extension

extension PhishAPIClient: GapDataProviderProtocol {
    
    /// Fetch gap information for a specific song on a specific show date
    func fetchSongGap(songName: String, showDate: String) async throws -> SongGapInfo? {
        let performances = try await fetchSongPerformanceHistory(songName: songName)
        
        // Find the performance matching the show date
        guard let currentPerformanceIndex = performances.firstIndex(where: { $0.showdate == showDate }),
              let currentPerformance = performances.first(where: { $0.showdate == showDate }) else {
            return nil
        }
        
        // Find the previous performance (the one that created the gap)
        var historicalLastPlayed: String?
        var historicalVenue: String?
        var historicalCity: String?
        var historicalState: String?
        
        if currentPerformanceIndex > 0 {
            let previousPerformance = performances[currentPerformanceIndex - 1]
            historicalLastPlayed = previousPerformance.showdate
            historicalVenue = previousPerformance.venue
            historicalCity = previousPerformance.city
            historicalState = previousPerformance.state
        }
        
        // Convert to SongGapInfo with proper historical data
        return SongGapInfo(
            songId: currentPerformance.songid,
            songName: currentPerformance.song,
            gap: currentPerformance.gap,
            lastPlayed: historicalLastPlayed ?? showDate, // Use historical date if available
            timesPlayed: performances.count,
            tourVenue: currentPerformance.venue,
            tourVenueRun: nil,  // Can be enhanced later with venue run data
            tourDate: showDate,
            historicalVenue: historicalVenue,
            historicalCity: historicalCity,
            historicalState: historicalState,
            historicalLastPlayed: historicalLastPlayed
        )
    }
    
    /// Fetch gap information for multiple songs on a specific show date
    func fetchSongGaps(songNames: [String], showDate: String) async throws -> [SongGapInfo] {
        var gapInfos: [SongGapInfo] = []
        
        for songName in songNames {
            do {
                if let gapInfo = try await fetchSongGap(songName: songName, showDate: showDate) {
                    gapInfos.append(gapInfo)
                }
                
                // Small delay to avoid overwhelming the API
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
            } catch {
                SwiftLogger.warn("Failed to fetch gap for \(songName): \(error)", category: .api)
                continue
            }
        }
        
        return gapInfos.sorted { $0.gap > $1.gap } // Sort by highest gap first
    }
    
    /// Fetch complete performance history for a song (includes gap data for each performance)
    func fetchSongPerformanceHistory(songName: String) async throws -> [SongPerformance] {
        // Use the slug endpoint for better URL handling
        let slugName = songName.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
        
        guard let url = URL(string: "\(baseURL)/setlists/slug/\(slugName).json?apikey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let request = URLRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        do {
            let performanceResponse = try JSONDecoder().decode(SongPerformanceResponse.self, from: data)
            return performanceResponse.data
        } catch {
            throw APIError.decodingError(error)
        }
    }
}