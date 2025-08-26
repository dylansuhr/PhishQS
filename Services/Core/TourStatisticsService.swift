//
//  TourStatisticsService.swift
//  PhishQS
//
//  Created by Claude on 8/26/25.
//

import Foundation

/// Service for calculating tour-specific song statistics
class TourStatisticsService {
    
    /// Calculate tour statistics by combining setlist data with song gap information
    /// - Parameters:
    ///   - enhancedSetlist: Current setlist with duration data
    ///   - tourTrackDurations: Track durations from entire tour (if available)
    ///   - allSongGaps: Complete gap information for all songs
    ///   - tourName: Optional tour name for context
    /// - Returns: TourSongStatistics with top 3 lists
    static func calculateTourStatistics(
        enhancedSetlist: EnhancedSetlist?,
        tourTrackDurations: [TrackDuration]?,
        allSongGaps: [SongGapInfo],
        tourName: String?
    ) -> TourSongStatistics {
        
        guard let setlist = enhancedSetlist else {
            return TourSongStatistics(
                longestSongs: [],
                rarestSongs: [],
                tourName: tourName
            )
        }
        
        // Get tour context from setlist items
        let tourSongIds = extractTourSongIds(from: setlist.setlistItems)
        let tourSongNames = Set(setlist.setlistItems.map { $0.song.lowercased() })
        
        // Calculate longest songs - use tour-wide data if available, otherwise fall back to single show
        let longestSongs: [TrackDuration]
        if let tourDurations = tourTrackDurations, !tourDurations.isEmpty {
            longestSongs = calculateLongestSongs(from: tourDurations)
        } else {
            longestSongs = calculateLongestSongs(from: setlist.trackDurations)
        }
        
        // Calculate rarest songs (filtered to tour context)
        let rarestSongs = calculateRarestSongs(
            from: allSongGaps,
            tourSongIds: tourSongIds,
            tourSongNames: tourSongNames
        )
        
        return TourSongStatistics(
            longestSongs: longestSongs,
            rarestSongs: rarestSongs,
            tourName: tourName
        )
    }
    
    /// Extract song IDs from setlist items (when available)
    private static func extractTourSongIds(from setlistItems: [SetlistItem]) -> Set<Int> {
        let songIds = setlistItems.compactMap { $0.songId }
        return Set(songIds)
    }
    
    /// Calculate top 3 longest songs from track durations
    private static func calculateLongestSongs(from trackDurations: [TrackDuration]) -> [TrackDuration] {
        return trackDurations
            .sorted { $0.durationSeconds > $1.durationSeconds }
            .prefix(3)
            .map { $0 }
    }
    
    /// Calculate top 3 rarest songs (highest gap) filtered to current tour
    private static func calculateRarestSongs(
        from allGaps: [SongGapInfo],
        tourSongIds: Set<Int>,
        tourSongNames: Set<String>
    ) -> [SongGapInfo] {
        
        // Filter to songs that appear in the current tour
        let tourSongs = allGaps.filter { gapInfo in
            // First try songId matching (most reliable)
            if !tourSongIds.isEmpty && tourSongIds.contains(gapInfo.songId) {
                return true
            }
            
            // Fallback to name matching (case insensitive)
            return tourSongNames.contains(gapInfo.songName.lowercased())
        }
        
        // Return top 3 rarest (highest gap) songs
        // If no songs have gap > 0, show the ones with highest gap (including 0)
        let filteredSongs = tourSongs.filter { $0.gap > 0 }
        
        if filteredSongs.isEmpty {
            // Fallback: if all songs are recent (gap=0), show the tour songs sorted by other criteria
            return tourSongs
                .sorted { $0.gap > $1.gap }  // This will still sort by gap, even if all are 0
                .prefix(3)
                .map { $0 }
        } else {
            return filteredSongs
                .sorted { $0.gap > $1.gap }
                .prefix(3)
                .map { $0 }
        }
    }
    
    /// Calculate tour statistics for a specific tour by analyzing multiple shows
    /// This is a more comprehensive method for future use when we have full tour data
    /// - Parameters:
    ///   - tourShows: All enhanced setlists for a tour
    ///   - allSongGaps: Complete gap information
    ///   - tourName: Tour name
    /// - Returns: Comprehensive tour statistics
    static func calculateComprehensiveTourStatistics(
        tourShows: [EnhancedSetlist],
        allSongGaps: [SongGapInfo],
        tourName: String
    ) -> TourSongStatistics {
        
        guard !tourShows.isEmpty else {
            return TourSongStatistics(longestSongs: [], rarestSongs: [], tourName: tourName)
        }
        
        // Collect all songs and durations from entire tour
        let allTourDurations = tourShows.flatMap { $0.trackDurations }
        let allTourSongIds = Set(tourShows.flatMap { show in
            show.setlistItems.compactMap { $0.songId }
        })
        let allTourSongNames = Set(tourShows.flatMap { show in
            show.setlistItems.map { $0.song.lowercased() }
        })
        
        // Calculate statistics across entire tour
        let longestSongs = calculateLongestSongs(from: allTourDurations)
        let rarestSongs = calculateRarestSongs(
            from: allSongGaps,
            tourSongIds: allTourSongIds,
            tourSongNames: allTourSongNames
        )
        
        return TourSongStatistics(
            longestSongs: longestSongs,
            rarestSongs: rarestSongs,
            tourName: tourName
        )
    }
}