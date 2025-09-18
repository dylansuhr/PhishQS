//
//  HistoricalGapCalculator.swift
//  PhishQS
//
//  Created by Claude on 8/27/25.
//

import Foundation
import SwiftLogger

/// Service for calculating historical gaps between song performances
/// Used to determine what the gap was when a song was played during a specific tour
class HistoricalGapCalculator {
    
    private let apiClient: PhishAPIService
    
    init(apiClient: PhishAPIService) {
        self.apiClient = apiClient
    }
    
    /// Calculate the historical gap for a song when it was played on a specific date
    /// This determines how many shows it had been since the song was last played
    /// - Parameters:
    ///   - songName: Name of the song
    ///   - playedOnDate: Date when the song was played (e.g., "2025-07-18")
    /// - Returns: HistoricalGapInfo with the calculated gap and performance details
    func calculateHistoricalGap(for songName: String, playedOnDate: String) async throws -> HistoricalGapInfo {
        
        // Step 1: Get complete performance history for the song
        let performances = try await apiClient.fetchSongPerformances(songName: songName)
        
        guard !performances.isEmpty else {
            throw APIError.noData
        }
        
        // Step 2: Find the performance on the specified date
        guard let targetPerformance = performances.first(where: { $0.showdate == playedOnDate }) else {
            throw APIError.invalidResponse
        }
        
        // Step 3: Find the most recent performance BEFORE the target date
        let performancesBeforeTarget = performances.filter { $0.showdate < playedOnDate }
        guard let lastPerformanceBeforeTarget = performancesBeforeTarget.last else {
            // This was the first performance ever, gap is infinite or "debut"
            return HistoricalGapInfo(
                songName: songName,
                targetDate: playedOnDate,
                targetVenue: targetPerformance.venue,
                targetCity: targetPerformance.city,
                targetState: targetPerformance.state,
                lastPlayedDate: nil,
                lastPlayedVenue: nil,
                lastPlayedCity: nil,
                lastPlayedState: nil,
                calculatedGap: 0,  // Use 0 to indicate debut
                isDebut: true
            )
        }
        
        // Step 4: Calculate the number of shows between the two performances
        let showCount = try await apiClient.fetchShowCountBetween(
            startDate: lastPerformanceBeforeTarget.showdate,
            endDate: targetPerformance.showdate
        )
        
        // Subtract 1 because we don't want to count the performance dates themselves
        let gap = max(0, showCount - 2)
        
        return HistoricalGapInfo(
            songName: songName,
            targetDate: playedOnDate,
            targetVenue: targetPerformance.venue,
            targetCity: targetPerformance.city,
            targetState: targetPerformance.state,
            lastPlayedDate: lastPerformanceBeforeTarget.showdate,
            lastPlayedVenue: lastPerformanceBeforeTarget.venue,
            lastPlayedCity: lastPerformanceBeforeTarget.city,
            lastPlayedState: lastPerformanceBeforeTarget.state,
            calculatedGap: gap,
            isDebut: false
        )
    }
    
    /// Calculate historical gaps for multiple songs efficiently
    /// Uses caching to avoid redundant API calls
    func calculateHistoricalGaps(for songs: [(songName: String, playedOnDate: String)]) async throws -> [HistoricalGapInfo] {
        var results: [HistoricalGapInfo] = []
        
        for (songName, playedOnDate) in songs {
            do {
                let gapInfo = try await calculateHistoricalGap(for: songName, playedOnDate: playedOnDate)
                results.append(gapInfo)
                
                // Add small delay to avoid overwhelming the API
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
            } catch {
                SwiftLogger.warn("Failed to calculate gap for \(songName): \(error)", category: .api)
                continue
            }
        }
        
        return results
    }
}

/// Information about a song's historical gap
struct HistoricalGapInfo {
    let songName: String
    let targetDate: String        // Date when song was played (e.g., "2025-07-18")
    let targetVenue: String       // Venue where it was played in target performance
    let targetCity: String        // City of target performance
    let targetState: String?      // State of target performance
    
    let lastPlayedDate: String?   // Date when it was last played before target
    let lastPlayedVenue: String?  // Venue where it was last played before
    let lastPlayedCity: String?   // City where it was last played before  
    let lastPlayedState: String?  // State where it was last played before
    
    let calculatedGap: Int        // Number of shows between performances
    let isDebut: Bool            // True if this was the song's debut
    
    /// Convert to SongGapInfo for display purposes
    func toSongGapInfo(songId: Int, timesPlayed: Int) -> SongGapInfo {
        return SongGapInfo(
            songId: songId,
            songName: songName,
            gap: calculatedGap,
            lastPlayed: lastPlayedDate ?? targetDate,
            timesPlayed: timesPlayed,
            tourVenue: targetVenue,
            tourVenueRun: nil,  // Could be enhanced later
            tourDate: targetDate,
            historicalVenue: lastPlayedVenue,
            historicalCity: lastPlayedCity,
            historicalState: lastPlayedState,
            historicalLastPlayed: lastPlayedDate
        )
    }
}