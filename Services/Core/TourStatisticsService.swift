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
/// - Legacy: iOS calculation methods archived in git history (September 2025)
///
class TourStatisticsService {
    
    /// Fetch tour statistics from server with comprehensive error handling
    /// - Returns: Complete tour statistics from server API
    /// - Throws: APIError with detailed logging for debugging server issues
    static func fetchTourStatistics() async throws -> TourSongStatistics {
        do {
            SwiftLogger.info("Fetching tour statistics from server", category: .statistics)
            let statistics = try await TourStatisticsAPIClient.shared.fetchTourStatistics()
            SwiftLogger.info("Successfully received server statistics", category: .statistics)
            return statistics
            
        } catch let apiError as APIError {
            SwiftLogger.error("Server API error - \(apiError). Check: 1) Network connection 2) Server accessibility 3) Server logs 4) Data regeneration", category: .statistics)
            throw apiError
            
        } catch {
            SwiftLogger.error("Unexpected error - \(error). This may indicate a network or system issue", category: .statistics)
            throw APIError.networkError(error)
        }
    }
}