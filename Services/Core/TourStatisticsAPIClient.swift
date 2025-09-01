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
        // Use local development server when running in debug mode
        return "http://localhost:3000"
        #else
        // Production Vercel deployment URL
        return "https://phish-qs.vercel.app"
        #endif
    }()
    
    /// API client is always available (no API key required for our server)
    var isAvailable: Bool {
        return true
    }
    
    // MARK: - Private Properties
    
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    
    // MARK: - Public Methods
    
    /// Fetch pre-computed tour statistics from server
    /// - Returns: Complete tour statistics with longest, rarest, and most played songs
    /// - Throws: APIError for network or parsing failures
    func fetchTourStatistics() async throws -> TourSongStatistics {
        guard let url = URL(string: "\(baseURL)/api/tour-statistics") else {
            throw APIError.invalidURL
        }
        
        print("🌐 Fetching tour statistics from: \(url)")
        
        // Create request with cache headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0 // 10 second timeout for server requests
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("📡 Server response status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                // Log error details for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Server error response: \(responseString)")
                }
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            // Parse the JSON response
            let tourStatistics = try decoder.decode(TourSongStatistics.self, from: data)
            
            print("✅ Successfully fetched tour statistics:")
            print("   📊 Longest songs: \(tourStatistics.longestSongs.count)")
            print("   📊 Rarest songs: \(tourStatistics.rarestSongs.count)")  
            print("   📊 Most played songs: \(tourStatistics.mostPlayedSongs.count)")
            print("   📊 Tour: \(tourStatistics.tourName ?? "Unknown")")
            
            return tourStatistics
            
        } catch let decodingError as DecodingError {
            print("❌ Failed to decode tour statistics: \(decodingError)")
            throw APIError.decodingError(decodingError)
            
        } catch let urlError as URLError {
            print("❌ Network error fetching tour statistics: \(urlError)")
            throw APIError.networkError(urlError)
            
        } catch {
            print("❌ Unexpected error fetching tour statistics: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private init() {
        // Singleton pattern
    }
}

