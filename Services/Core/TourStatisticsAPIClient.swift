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
            print("❌ TourStatisticsAPIClient: Invalid health check URL")
            return false
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 5.0 // Short timeout for health check
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let isHealthy = httpResponse.statusCode == 200
                print("🌐 TourStatisticsAPIClient: Server health check - \(isHealthy ? "✅ Healthy" : "❌ Unhealthy")")
                return isHealthy
            }
            
            return false
            
        } catch {
            print("❌ TourStatisticsAPIClient: Health check failed - \(error.localizedDescription)")
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
            print("❌ TourStatisticsAPIClient: \(errorMessage)")
            throw APIError.invalidURL
        }
        
        print("🌐 TourStatisticsAPIClient: Fetching tour statistics from: \(url)")
        print("🔍 TourStatisticsAPIClient: Environment - \(baseURL.contains("localhost") ? "Development" : "Production")")
        
        // Create request with cache headers and user agent
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("PhishQS-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.timeoutInterval = 15.0 // Increased timeout for server requests
        
        do {
            // Clear URL cache to ensure fresh response (temporary for debugging)
            URLCache.shared.removeAllCachedResponses()

            // Add request timing for performance monitoring
            let startTime = CFAbsoluteTimeGetCurrent()
            let (data, response) = try await session.data(for: request)
            let requestDuration = CFAbsoluteTimeGetCurrent() - startTime
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ TourStatisticsAPIClient: Invalid response type - expected HTTPURLResponse")
                throw APIError.invalidResponse
            }
            
            print("📡 TourStatisticsAPIClient: Server response status: \(httpResponse.statusCode) (\(String(format: "%.2f", requestDuration * 1000))ms)")
            
            // Enhanced status code handling with specific error guidance
            switch httpResponse.statusCode {
            case 200:
                // Success - continue to parse response
                break
                
            case 404:
                print("❌ TourStatisticsAPIClient: Statistics endpoint not found (404)")
                print("💡 TourStatisticsAPIClient: Possible causes:")
                print("   • Server not deployed or endpoint missing")
                print("   • Incorrect baseURL configuration")
                print("   • API route not properly configured in Vercel")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📜 TourStatisticsAPIClient: Server response: \(responseString)")
                }
                throw APIError.httpError(404)
                
            case 500:
                print("❌ TourStatisticsAPIClient: Server internal error (500)")
                print("💡 TourStatisticsAPIClient: Server-side processing failed:")
                print("   • Check server logs for statistics generation errors")
                print("   • Verify tour statistics data exists and is valid")
                print("   • May need to regenerate statistics data")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📜 TourStatisticsAPIClient: Server error details: \(responseString)")
                }
                throw APIError.httpError(500)
                
            case 502, 503, 504:
                print("❌ TourStatisticsAPIClient: Server unavailable (\(httpResponse.statusCode))")
                print("💡 TourStatisticsAPIClient: Server deployment or infrastructure issue:")
                print("   • Vercel deployment may be down or restarting")
                print("   • Cold start timeout (serverless functions)")
                print("   • Try again in a few moments")
                throw APIError.httpError(httpResponse.statusCode)
                
            default:
                print("❌ TourStatisticsAPIClient: Unexpected HTTP status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📜 TourStatisticsAPIClient: Response body: \(responseString)")
                }
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            // Validate response has data
            guard !data.isEmpty else {
                print("❌ TourStatisticsAPIClient: Server returned empty response")
                print("💡 TourStatisticsAPIClient: This suggests statistics data is missing or corrupt")
                throw APIError.invalidResponse
            }
            
            // Log response size for monitoring
            print("📊 TourStatisticsAPIClient: Response size: \(data.count) bytes")
            
            // Parse the JSON response with detailed error handling
            do {
                let tourStatistics = try decoder.decode(TourSongStatistics.self, from: data)
                
                // Validate the decoded data quality
                let validationResult = validateTourStatistics(tourStatistics)
                if !validationResult.isValid {
                    print("⚠️ TourStatisticsAPIClient: Data validation warnings:")
                    for warning in validationResult.warnings {
                        print("   • \(warning)")
                    }
                }
                
                print("✅ TourStatisticsAPIClient: Successfully fetched and parsed tour statistics:")
                print("   📊 Longest songs: \(tourStatistics.longestSongs.count)")
                print("   📊 Rarest songs: \(tourStatistics.rarestSongs.count)")
                print("   📊 Most played songs: \(tourStatistics.mostPlayedSongs.count)")
                print("   📊 Tour: \(tourStatistics.tourName ?? "Unknown")")
                
                return tourStatistics
                
            } catch let decodingError as DecodingError {
                print("❌ TourStatisticsAPIClient: Failed to decode tour statistics")
                print("💡 TourStatisticsAPIClient: JSON parsing failed - data format issues:")
                
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("   • Type mismatch: expected \(type) at \(context.codingPath)")
                    print("   • Description: \(context.debugDescription)")
                    
                case .valueNotFound(let type, let context):
                    print("   • Missing value: \(type) at \(context.codingPath)")
                    print("   • Description: \(context.debugDescription)")
                    
                case .keyNotFound(let key, let context):
                    print("   • Missing key: \(key) at \(context.codingPath)")
                    print("   • Description: \(context.debugDescription)")
                    
                case .dataCorrupted(let context):
                    print("   • Data corrupted at \(context.codingPath)")
                    print("   • Description: \(context.debugDescription)")
                    
                @unknown default:
                    print("   • Unknown decoding error: \(decodingError)")
                }
                
                // Log sample of response data for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    let preview = String(responseString.prefix(500))
                    print("📜 TourStatisticsAPIClient: Response preview: \(preview)...")
                }
                
                throw APIError.decodingError(decodingError)
            }
            
        } catch let urlError as URLError {
            print("❌ TourStatisticsAPIClient: Network error fetching tour statistics")
            print("💡 TourStatisticsAPIClient: Network issue details:")
            
            switch urlError.code {
            case .notConnectedToInternet:
                print("   • No internet connection - check device connectivity")
                
            case .timedOut:
                print("   • Request timed out - server may be slow or unresponsive")
                print("   • Consider checking server status or trying again")
                
            case .cannotFindHost:
                print("   • Cannot find host: \(baseURL)")
                print("   • Check if server domain is correct and accessible")
                
            case .cannotConnectToHost:
                print("   • Cannot connect to host - server may be down")
                print("   • Verify server deployment and accessibility")
                
            case .networkConnectionLost:
                print("   • Network connection lost during request")
                print("   • Check network stability and retry")
                
            case .dnsLookupFailed:
                print("   • DNS lookup failed for \(baseURL)")
                print("   • Domain may not exist or DNS issues")
                
            default:
                print("   • Network error: \(urlError.localizedDescription)")
                print("   • Code: \(urlError.code.rawValue)")
            }
            
            throw APIError.networkError(urlError)
            
        } catch let apiError as APIError {
            // Re-throw API errors without additional logging (already logged above)
            throw apiError
            
        } catch {
            print("❌ TourStatisticsAPIClient: Unexpected error fetching tour statistics")
            print("💡 TourStatisticsAPIClient: Unhandled error type: \(type(of: error))")
            print("   • Error: \(error.localizedDescription)")
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

