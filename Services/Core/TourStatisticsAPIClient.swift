//
//  TourStatisticsAPIClient.swift
//  PhishQS
//
//  Created by Claude on 9/1/25.
//

import Foundation

// MARK: - Tour Statistics API Protocol

/// Protocol for APIs that provide tour statistics data
protocol TourStatisticsProviderProtocol: APIClientProtocol {
    func fetchTourStatistics() async throws -> TourSongStatistics
}

// MARK: - Tour Statistics API Client

/// API client for fetching pre-computed tour statistics from Vercel server
class TourStatisticsAPIClient: TourStatisticsProviderProtocol {
    static let shared = TourStatisticsAPIClient()
    
    // MARK: - Configuration
    
    /// Base URL for the Vercel serverless functions
    internal let baseURL: String = {
        #if DEBUG
        return "http://localhost:3000"
        #else
        return "https://phish-qs.vercel.app"
        #endif
    }()
    
    /// API client availability check with server reachability
    /// - Returns: True if API client can potentially connect to server
    var isAvailable: Bool {
        // Basic validation - more sophisticated health check could be added
        return !baseURL.isEmpty
    }
    
    /// Check server health and availability
    /// - Returns: True if server is responding to health checks
    func checkServerHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/health") else {
            SwiftLogger.error("TourStatisticsAPIClient: Invalid health check URL", category: .api)
            return false
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 5.0 // Short timeout for health check
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let isHealthy = httpResponse.statusCode == 200
                SwiftLogger.info("TourStatisticsAPIClient: Server health check - \(isHealthy ? "Healthy" : "Unhealthy")", category: .api)
                return isHealthy
            }
            
            return false
            
        } catch {
            SwiftLogger.error("TourStatisticsAPIClient: Health check failed - \(error.localizedDescription)", category: .api)
            return false
        }
    }
    
    // MARK: - Private Properties
    
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    
    // MARK: - Public Methods
    
    /// Fetch pre-computed tour statistics from server with comprehensive error handling
    /// - Returns: Complete tour statistics with longest, rarest, and most played songs
    /// - Throws: APIError with detailed logging for network, server, or parsing failures
    func fetchTourStatistics() async throws -> TourSongStatistics {
        // Add cache-busting timestamp parameter
        let timestamp = Int(Date().timeIntervalSince1970)
        guard let url = URL(string: "\(baseURL)/api/tour-statistics?t=\(timestamp)") else {
            let errorMessage = "Failed to create URL from baseURL: \(baseURL)"
            SwiftLogger.error("TourStatisticsAPIClient: \(errorMessage)", category: .api)
            throw APIError.invalidURL
        }
        
        SwiftLogger.info("TourStatisticsAPIClient: Fetching tour statistics from: \(url)", category: .api)
        SwiftLogger.info("TourStatisticsAPIClient: Environment - \(baseURL.contains("localhost") ? "Development" : "Production")", category: .api)
        
        // Create request with cache headers and user agent
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("PhishQS-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.timeoutInterval = 15.0 // Increased timeout for server requests
        
        do {
            // Add request timing for performance monitoring
            let startTime = CFAbsoluteTimeGetCurrent()
            let (data, response) = try await session.data(for: request)
            let requestDuration = CFAbsoluteTimeGetCurrent() - startTime
            
            guard let httpResponse = response as? HTTPURLResponse else {
                SwiftLogger.error("TourStatisticsAPIClient: Invalid response type - expected HTTPURLResponse", category: .api)
                throw APIError.invalidResponse
            }
            
            SwiftLogger.info("TourStatisticsAPIClient: Server response status: \(httpResponse.statusCode) (\(String(format: "%.2f", requestDuration * 1000))ms)", category: .api)
            
            // Enhanced status code handling with specific error guidance
            switch httpResponse.statusCode {
            case 200:
                // Success - continue to parse response
                break
                
            case 404:
                SwiftLogger.error("TourStatisticsAPIClient: Statistics endpoint not found (404)", category: .api)
                SwiftLogger.info("TourStatisticsAPIClient: Possible causes:", category: .api)
                SwiftLogger.info("   • Server not deployed or endpoint missing", category: .api)
                SwiftLogger.info("   • Incorrect baseURL configuration", category: .api)
                SwiftLogger.info("   • API route not properly configured in Vercel", category: .api)
                if let responseString = String(data: data, encoding: .utf8) {
                    SwiftLogger.info("TourStatisticsAPIClient: Server response: \(responseString)", category: .api)
                }
                throw APIError.httpError(404)
                
            case 500:
                SwiftLogger.error("TourStatisticsAPIClient: Server internal error (500)", category: .api)
                SwiftLogger.info("TourStatisticsAPIClient: Server-side processing failed:", category: .api)
                SwiftLogger.info("   • Check server logs for statistics generation errors", category: .api)
                SwiftLogger.info("   • Verify tour statistics data exists and is valid", category: .api)
                SwiftLogger.info("   • May need to regenerate statistics data", category: .api)
                if let responseString = String(data: data, encoding: .utf8) {
                    SwiftLogger.info("TourStatisticsAPIClient: Server error details: \(responseString)", category: .api)
                }
                throw APIError.httpError(500)
                
            case 502, 503, 504:
                SwiftLogger.error("TourStatisticsAPIClient: Server unavailable (\(httpResponse.statusCode))", category: .api)
                SwiftLogger.info("TourStatisticsAPIClient: Server deployment or infrastructure issue:", category: .api)
                SwiftLogger.info("   • Vercel deployment may be down or restarting", category: .api)
                SwiftLogger.info("   • Cold start timeout (serverless functions)", category: .api)
                SwiftLogger.info("   • Try again in a few moments", category: .api)
                throw APIError.httpError(httpResponse.statusCode)
                
            default:
                SwiftLogger.error("TourStatisticsAPIClient: Unexpected HTTP status: \(httpResponse.statusCode)", category: .api)
                if let responseString = String(data: data, encoding: .utf8) {
                    SwiftLogger.info("TourStatisticsAPIClient: Response body: \(responseString)", category: .api)
                }
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            // Validate response has data
            guard !data.isEmpty else {
                SwiftLogger.error("TourStatisticsAPIClient: Server returned empty response", category: .api)
                SwiftLogger.info("TourStatisticsAPIClient: This suggests statistics data is missing or corrupt", category: .api)
                throw APIError.invalidResponse
            }
            
            // Log response size for monitoring
            SwiftLogger.info("TourStatisticsAPIClient: Response size: \(data.count) bytes", category: .api)
            
            // Parse the JSON response with detailed error handling
            do {
                let tourStatistics = try decoder.decode(TourSongStatistics.self, from: data)
                
                // Validate the decoded data quality
                let validationResult = validateTourStatistics(tourStatistics)
                if !validationResult.isValid {
                    SwiftLogger.warn("TourStatisticsAPIClient: Data validation warnings:", category: .api)
                    for warning in validationResult.warnings {
                        SwiftLogger.warn("   • \(warning)", category: .api)
                    }
                }
                
                SwiftLogger.info("TourStatisticsAPIClient: Successfully fetched and parsed tour statistics:", category: .api)
                SwiftLogger.info("   Longest songs: \(tourStatistics.longestSongs.count)", category: .api)
                SwiftLogger.info("   Rarest songs: \(tourStatistics.rarestSongs.count)", category: .api)
                SwiftLogger.info("   Most played songs: \(tourStatistics.mostPlayedSongs.count)", category: .api)
                SwiftLogger.info("   Most common not played: \(tourStatistics.mostCommonSongsNotPlayed?.count ?? 0)", category: .api)
                SwiftLogger.info("   Tour: \(tourStatistics.tourName ?? "Unknown")", category: .api)
                
                return tourStatistics
                
            } catch let decodingError as DecodingError {
                SwiftLogger.error("TourStatisticsAPIClient: Failed to decode tour statistics", category: .api)
                SwiftLogger.info("TourStatisticsAPIClient: JSON parsing failed - data format issues:", category: .api)
                
                switch decodingError {
                case .typeMismatch(let type, let context):
                    SwiftLogger.error("   • Type mismatch: expected \(type) at \(context.codingPath)", category: .api)
                    SwiftLogger.error("   • Description: \(context.debugDescription)", category: .api)
                    
                case .valueNotFound(let type, let context):
                    SwiftLogger.error("   • Missing value: \(type) at \(context.codingPath)", category: .api)
                    SwiftLogger.error("   • Description: \(context.debugDescription)", category: .api)
                    
                case .keyNotFound(let key, let context):
                    SwiftLogger.error("   • Missing key: \(key) at \(context.codingPath)", category: .api)
                    SwiftLogger.error("   • Description: \(context.debugDescription)", category: .api)
                    
                case .dataCorrupted(let context):
                    SwiftLogger.error("   • Data corrupted at \(context.codingPath)", category: .api)
                    SwiftLogger.error("   • Description: \(context.debugDescription)", category: .api)
                    
                @unknown default:
                    SwiftLogger.error("   • Unknown decoding error: \(decodingError)", category: .api)
                }
                
                // Log sample of response data for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    let preview = String(responseString.prefix(500))
                    SwiftLogger.info("TourStatisticsAPIClient: Response preview: \(preview)...", category: .api)
                }
                
                throw APIError.decodingError(decodingError)
            }
            
        } catch let urlError as URLError {
            SwiftLogger.error("TourStatisticsAPIClient: Network error fetching tour statistics", category: .api)
            SwiftLogger.info("TourStatisticsAPIClient: Network issue details:", category: .api)
            
            switch urlError.code {
            case .notConnectedToInternet:
                SwiftLogger.error("   • No internet connection - check device connectivity", category: .api)
                
            case .timedOut:
                SwiftLogger.error("   • Request timed out - server may be slow or unresponsive", category: .api)
                SwiftLogger.error("   • Consider checking server status or trying again", category: .api)
                
            case .cannotFindHost:
                SwiftLogger.error("   • Cannot find host: \(baseURL)", category: .api)
                SwiftLogger.error("   • Check if server domain is correct and accessible", category: .api)
                
            case .cannotConnectToHost:
                SwiftLogger.error("   • Cannot connect to host - server may be down", category: .api)
                SwiftLogger.error("   • Verify server deployment and accessibility", category: .api)
                
            case .networkConnectionLost:
                SwiftLogger.error("   • Network connection lost during request", category: .api)
                SwiftLogger.error("   • Check network stability and retry", category: .api)
                
            case .dnsLookupFailed:
                SwiftLogger.error("   • DNS lookup failed for \(baseURL)", category: .api)
                SwiftLogger.error("   • Domain may not exist or DNS issues", category: .api)
                
            default:
                SwiftLogger.error("   • Network error: \(urlError.localizedDescription)", category: .api)
                SwiftLogger.error("   • Code: \(urlError.code.rawValue)", category: .api)
            }
            
            throw APIError.networkError(urlError)
            
        } catch let apiError as APIError {
            // Re-throw API errors without additional logging (already logged above)
            throw apiError
            
        } catch {
            SwiftLogger.error("TourStatisticsAPIClient: Unexpected error fetching tour statistics", category: .api)
            SwiftLogger.info("TourStatisticsAPIClient: Unhandled error type: \(type(of: error))", category: .api)
            SwiftLogger.error("   • Error: \(error.localizedDescription)", category: .api)
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    // MARK: - Validation
    
    /// Validate tour statistics data quality
    /// - Parameter statistics: Tour statistics to validate
    /// - Returns: Validation result with warnings
    private func validateTourStatistics(_ statistics: TourSongStatistics) -> (isValid: Bool, warnings: [String]) {
        var warnings: [String] = []
        var isValid = true
        
        // Check for empty or missing data
        if statistics.longestSongs.isEmpty {
            warnings.append("No longest songs data available")
        }
        
        if statistics.rarestSongs.isEmpty {
            warnings.append("No rarest songs data available")
        }
        
        if statistics.mostPlayedSongs.isEmpty {
            warnings.append("No most played songs data available")
        }
        
        // Check for tour name
        if statistics.tourName?.isEmpty != false {
            warnings.append("Tour name is missing or empty")
        }
        
        // Validate longest songs have duration data
        for song in statistics.longestSongs {
            if song.durationSeconds <= 0 {
                warnings.append("Invalid duration for song: \(song.songName)")
            }
        }
        
        // Validate rarest songs have gap data
        for song in statistics.rarestSongs {
            if song.gap < 0 {
                warnings.append("Invalid gap for song: \(song.songName)")
            }
        }
        
        // Validate most played songs have play counts
        for song in statistics.mostPlayedSongs {
            if song.playCount <= 0 {
                warnings.append("Invalid play count for song: \(song.songName)")
            }
        }
        
        return (isValid: warnings.isEmpty, warnings: warnings)
    }
    
    private init() {
        // Singleton pattern
        decoder.dateDecodingStrategy = .iso8601
    }
}

