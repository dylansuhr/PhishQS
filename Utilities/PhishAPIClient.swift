import Foundation

// MARK: - API Service Protocol

/// Protocol defining all Phish.net API operations
protocol PhishAPIService {
    func fetchShows(forYear year: String) async throws -> [Show]
    func fetchLatestShow() async throws -> Show?
    func fetchSetlist(for date: String) async throws -> [SetlistItem]
    func searchShows(query: String) async throws -> [Show]
    func fetchVenueInfo(for venueId: String) async throws -> Venue
}

// MARK: - API Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(Int)
    case noData
    case decodingError(Error)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

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

    private let baseURL = "https://api.phish.net/v5"
    private let apiKey = Secrets.value(for: "PhishNetAPIKey")
    
    // MARK: - Show Methods
    
    /// Fetch all shows for a given year
    func fetchShows(forYear year: String) async throws -> [Show] {
        // Add cache-busting with timestamp and random component for fresh data
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        guard let url = URL(string: "\(baseURL)/setlists/showyear/\(year).json?apikey=\(apiKey)&artist=phish&_t=\(timestamp)&_r=\(random)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
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
        // Add cache-busting with timestamp and random component for fresh data
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        guard let url = URL(string: "\(baseURL)/setlists/showdate/\(date).json?apikey=\(apiKey)&artist=phish&_t=\(timestamp)&_r=\(random)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
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
    
    // MARK: - Venue Methods
    
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