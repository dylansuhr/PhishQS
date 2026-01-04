//
//  SharedModels.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//  NOTE: This file is being gradually split into focused model files for better organization
//

import Foundation

// Import focused model files for better organization
// These files contain extracted models from this file for maintainability
// TODO: Remove models from this file once all imports are updated across the codebase

// MARK: - Audio/Recording Models (moved to Models/AudioModels.swift)

// TrackDuration, Recording, RecordingType, and Tour models moved to focused model files



// MARK: - User Models (definitions moved to Models/UserModels.swift)

// UserSession and Playlist models moved to focused model files

// MARK: - Tour Statistics Models

// TourContextProvider protocol moved to Models/TourStatisticsModels.swift

// SongGapInfo model moved to Models/TourStatisticsModels.swift

// SongGapInfo TourContextProvider conformance moved to Models/TourStatisticsModels.swift

// SongPerformance, MostPlayedSong, and MostCommonSongNotPlayed models moved to Models/TourStatisticsModels.swift

// All tour statistics models moved to Models/TourStatisticsModels.swift

// TourSongStatistics model moved to Models/TourStatisticsModels.swift

// MARK: - Footnote Models

/// A single footnote legend item for setlist display
struct FootnoteLegendItem: Codable, Equatable {
    let index: Int
    let text: String
}

/// Utility for normalizing footnotes from raw setlist data
enum FootnoteNormalizer {
    /// Normalize footnotes for a setlist, deduplicating identical footnotes
    /// - Parameter setlistItems: Array of SetlistItem with raw footnote strings
    /// - Returns: Tuple of (updated items with footnoteIndices, legend array)
    static func normalize(_ setlistItems: [SetlistItem]) -> (items: [SetlistItem], legend: [FootnoteLegendItem]) {
        var footnoteMap: [String: Int] = [:]
        var nextIndex = 1

        let normalizedItems = setlistItems.map { item -> SetlistItem in
            let footnote = (item.footnote ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            guard !footnote.isEmpty else {
                return SetlistItem(
                    set: item.set,
                    song: item.song,
                    songId: item.songId,
                    transMark: item.transMark,
                    venue: item.venue,
                    city: item.city,
                    state: item.state,
                    showdate: item.showdate,
                    permalink: item.permalink,
                    setlistnotes: item.setlistnotes,
                    footnote: item.footnote,
                    footnoteIndices: []
                )
            }

            let index: Int
            if let existingIndex = footnoteMap[footnote] {
                index = existingIndex
            } else {
                index = nextIndex
                footnoteMap[footnote] = index
                nextIndex += 1
            }

            return SetlistItem(
                set: item.set,
                song: item.song,
                songId: item.songId,
                transMark: item.transMark,
                venue: item.venue,
                city: item.city,
                state: item.state,
                showdate: item.showdate,
                permalink: item.permalink,
                setlistnotes: item.setlistnotes,
                footnote: item.footnote,
                footnoteIndices: [index]
            )
        }

        let legend = footnoteMap
            .sorted { $0.value < $1.value }
            .map { FootnoteLegendItem(index: $0.value, text: $0.key) }

        return (normalizedItems, legend)
    }
}

// MARK: - Enhanced Data Models

/// Enhanced setlist combining data from multiple APIs
struct EnhancedSetlist: Codable {
    let showDate: String
    let setlistItems: [SetlistItem]
    let trackDurations: [TrackDuration]
    let venueRun: VenueRun?
    let tourPosition: TourShowPosition?
    let recordings: [Recording]
    let songGaps: [SongGapInfo]          // Gap information for each song in setlist
    let setlistnotes: String?            // HTML show notes from Phish.net
    let footnoteLegend: [FootnoteLegendItem]? // Normalized footnotes for this show

    /// Get duration for a specific song by position in setlist (preferred method)
    /// Uses position-based matching with name validation for accuracy with duplicate song names
    func getDuration(at position: Int) -> TrackDuration? {
        guard position >= 0 && position < trackDurations.count else { return nil }
        return trackDurations[position]
    }
    
    /// Get duration for a specific song by name (fallback method)
    /// Note: This may return incorrect results for duplicate song names
    func getDuration(for songName: String) -> TrackDuration? {
        return trackDurations.first { duration in
            duration.songName.lowercased() == songName.lowercased()
        }
    }
    
    /// Get duration for a song with position validation (hybrid approach)
    /// Matches by position first, then validates song name similarity
    func getDuration(at position: Int, expectedName: String) -> TrackDuration? {
        guard position >= 0 && position < trackDurations.count else { 
            // Fallback to name-only matching if position is invalid
            return getDuration(for: expectedName)
        }
        
        let track = trackDurations[position]
        
        // Validate names are similar (handles minor differences)
        if isNameMatch(track.songName, expectedName) {
            return track
        }
        
        // Position mismatch - fall back to name-only search
        return getDuration(for: expectedName)
    }
    
    /// Check if two song names match (exact or fuzzy match)
    private func isNameMatch(_ name1: String, _ name2: String) -> Bool {
        let clean1 = name1.lowercased().trimmingCharacters(in: .whitespaces)
        let clean2 = name2.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Exact match
        if clean1 == clean2 { return true }
        
        // Fuzzy match (one contains the other, or >80% similarity)
        if clean1.contains(clean2) || clean2.contains(clean1) { return true }
        
        // Calculate simple similarity ratio
        let similarity = calculateSimilarity(clean1, clean2)
        return similarity > 0.8
    }
    
    /// Calculate similarity ratio between two strings (0.0 to 1.0)
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let longer = str1.count > str2.count ? str1 : str2
        
        if longer.isEmpty { return 1.0 }
        
        let editDistance = levenshteinDistance(str1, str2)
        return (Double(longer.count) - Double(editDistance)) / Double(longer.count)
    }
    
    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let a = Array(str1)
        let b = Array(str2)
        let m = a.count
        let n = b.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                if a[i-1] == b[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]) + 1
                }
            }
        }
        
        return dp[m][n]
    }
    
    /// Get gap information for a specific song by name
    func getGap(for songName: String) -> SongGapInfo? {
        return songGaps.first { gap in
            gap.songName.lowercased() == songName.lowercased()
        }
    }
    
    /// Get the top N rarest songs (highest gaps) from this setlist
    func getRarestSongs(limit: Int = 3) -> [SongGapInfo] {
        let sortedByGap = songGaps.sorted { $0.gap > $1.gap }
        return Array(sortedByGap.prefix(limit))
    }
    
    /// Get formatted venue run display text
    var venueRunDisplayText: String {
        return venueRun?.runDisplayText ?? ""
    }
    
    /// Get formatted tour position display text
    var tourPositionDisplayText: String {
        return tourPosition?.displayText ?? ""
    }
    
    /// Get short tour position display text (Show X/Y)
    var tourPositionShortText: String {
        return tourPosition?.shortDisplayText ?? ""
    }
    
    /// Check if recordings are available for this show
    var hasRecordings: Bool {
        return !recordings.isEmpty && recordings.contains { $0.isAvailable }
    }
    
    /// Get primary recording URL if available
    var primaryRecordingURL: String? {
        return recordings.first { $0.isAvailable }?.url
    }
}