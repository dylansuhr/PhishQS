//
//  TourStatisticsService.swift
//  PhishQS
//
//  Created by Claude on 8/26/25.
//

import Foundation

/// Service coordinating tour statistics fetching from server
///
/// **ARCHITECTURE**: This service now exclusively uses server-side pre-computed statistics.
/// - Primary approach: `TourStatisticsAPIClient.shared.fetchTourStatistics()` for instant server-side statistics  
/// - Performance: Server responses are ~140ms vs 60+ seconds for local calculations
/// - Fallback: No iOS calculations - comprehensive error handling guides user to resolve server issues
/// - Legacy: iOS calculation methods preserved in `LegacyTourStatisticsCalculator.swift`
///
class TourStatisticsService {
    
    /// Fetch tour statistics from server with comprehensive error handling
    /// - Returns: Complete tour statistics from server API
    /// - Throws: APIError with detailed logging for debugging server issues
    static func fetchTourStatistics() async throws -> TourSongStatistics {
        do {
            print("🌐 TourStatisticsService: Fetching tour statistics from server...")
            let statistics = try await TourStatisticsAPIClient.shared.fetchTourStatistics()
            print("✅ TourStatisticsService: Successfully received server statistics")
            return statistics
            
        } catch let apiError as APIError {
            print("❌ TourStatisticsService: Server API error - \(apiError)")
            print("💡 TourStatisticsService: To resolve server issues:")
            print("   1. Check network connection")
            print("   2. Verify server is deployed and accessible")
            print("   3. Check server logs for statistics generation errors")
            print("   4. Regenerate statistics data if needed")
            throw apiError
            
        } catch {
            print("❌ TourStatisticsService: Unexpected error - \(error)")
            print("💡 TourStatisticsService: This may indicate a network or system issue")
            throw APIError.networkError(error)
        }
    }
}