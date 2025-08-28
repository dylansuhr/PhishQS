//
//  ServerSideTourStatsService.swift
//  PhishQS
//
//  Created by Claude on 8/28/25.
//

import Foundation

/// Service for fetching pre-computed tour statistics from server-side API
/// Provides instant loading of tour statistics without client-side calculation
class ServerSideTourStatsService {
    static let shared = ServerSideTourStatsService()
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Base URL for tour statistics API - configurable for different environments
    private var baseURL: String {
        // TODO: Add to Secrets.plist or configuration
        return "https://api.phishqs.com"
    }
    
    /// Current tour statistics endpoint
    private var currentTourStatsURL: String {
        return "\(baseURL)/current-tour-stats.json"
    }
    
    // MARK: - Public API
    
    /// Fetch current tour statistics from server
    /// Returns nil if server unavailable - caller should fallback to local calculation
    func fetchCurrentTourStatistics() async -> TourSongStatistics? {
        print("🌐 Attempting to fetch tour statistics from server...")
        
        do {
            let statistics = try await performServerRequest()
            print("✅ Successfully loaded tour statistics from server")
            return statistics
        } catch {
            print("⚠️ Server unavailable for tour statistics: \(error.localizedDescription)")
            print("🔄 Caller should fallback to local calculation")
            return nil
        }
    }
    
    // MARK: - Private Implementation
    
    /// Perform the actual server request and parsing
    private func performServerRequest() async throws -> TourSongStatistics {
        guard let url = URL(string: currentTourStatsURL) else {
            throw ServerSideTourStatsError.invalidURL
        }
        
        // Create request with appropriate timeout for fast user experience
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0 // 10 second timeout for server requests
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Perform network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerSideTourStatsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ServerSideTourStatsError.serverError(httpResponse.statusCode)
        }
        
        // Parse JSON response
        let decoder = JSONDecoder()
        let serverResponse = try decoder.decode(ServerTourStatsResponse.self, from: data)
        
        // Convert server format to app format
        return convertToTourSongStatistics(from: serverResponse)
    }
    
    /// Convert server response format to app's TourSongStatistics format
    private func convertToTourSongStatistics(from serverResponse: ServerTourStatsResponse) -> TourSongStatistics {
        return TourSongStatistics(
            longestSongs: serverResponse.longestSongs,
            rarestSongs: serverResponse.rarestSongs,
            tourName: serverResponse.tourName
        )
    }
}

// MARK: - Server Response Models

/// Server response structure for current tour statistics
struct ServerTourStatsResponse: Codable {
    let tourName: String
    let lastUpdated: String
    let latestShow: String
    let longestSongs: [TrackDuration]
    let rarestSongs: [SongGapInfo]
}

// MARK: - Error Types

enum ServerSideTourStatsError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL configuration"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .parsingError:
            return "Failed to parse server response"
        }
    }
}

// MARK: - Configuration Extension

extension ServerSideTourStatsService {
    
    /// Check if server-side tour statistics are enabled
    /// Can be used to completely disable feature if needed
    var isServerSideEnabled: Bool {
        // TODO: Add configuration flag if needed
        return true
    }
    
    /// Get server status for debugging/monitoring
    func checkServerStatus() async -> ServerStatus {
        do {
            guard let url = URL(string: baseURL) else {
                return .unavailable(reason: "Invalid URL")
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 5.0
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200 ? .available : .unavailable(reason: "HTTP \(httpResponse.statusCode)")
            }
            
            return .unavailable(reason: "Invalid response")
        } catch {
            return .unavailable(reason: error.localizedDescription)
        }
    }
}

/// Server status for monitoring and debugging
enum ServerStatus {
    case available
    case unavailable(reason: String)
    
    var isAvailable: Bool {
        switch self {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
}