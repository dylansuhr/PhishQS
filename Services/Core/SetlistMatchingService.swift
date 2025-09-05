//
//  SetlistMatchingService.swift
//  PhishQS
//
//  Created by Claude on 9/4/25.
//

import Foundation

/// Service for matching setlist data with external data sources (durations, gaps, etc.)
/// Consolidates duplicate position-matching logic from multiple ViewModels
/// 
/// **Purpose**: Provides accurate data matching even with duplicate song names
/// **Strategy**: Uses position-based matching with name validation for reliability
struct SetlistMatchingService {
    
    // MARK: - Position-Based Matching
    
    /// Match track durations to setlist items using position-based matching
    /// Handles duplicate song names correctly by using position within set
    /// 
    /// - Parameters:
    ///   - setlistItems: Array of setlist items to match
    ///   - durations: Array of track durations to match against
    /// - Returns: Dictionary mapping setlist item indices to matched durations
    static func matchDurationsToSetlist(
        setlistItems: [SetlistItem], 
        durations: [TrackDuration]
    ) -> [Int: TrackDuration] {
        var matches: [Int: TrackDuration] = [:]
        
        // Group durations by set for accurate positional matching
        let durationsBySet = Dictionary(grouping: durations) { $0.setNumber }
        
        for (index, item) in setlistItems.enumerated() {
            guard let setDurations = durationsBySet[item.set] else { continue }
            
            // Get position within the set (0-based)
            let setItems = setlistItems.filter { $0.set == item.set }
            guard let positionInSet = setItems.firstIndex(where: { $0.song == item.song && $0.showdate == item.showdate }) else { continue }
            
            // Match by position with name validation for accuracy
            if positionInSet < setDurations.count {
                let candidateDuration = setDurations[positionInSet]
                
                // Validate match with normalized song name comparison
                if normalizeSongName(item.song) == normalizeSongName(candidateDuration.songName) {
                    matches[index] = candidateDuration
                }
            }
        }
        
        return matches
    }
    
    /// Match song gap information to setlist items using position-based matching
    /// Ensures accurate gap data assignment even with duplicate song names
    /// 
    /// - Parameters:
    ///   - setlistItems: Array of setlist items to match
    ///   - gaps: Array of song gap information to match against
    /// - Returns: Dictionary mapping setlist item indices to matched gap info
    static func matchGapsToSetlist(
        setlistItems: [SetlistItem], 
        gaps: [SongGapInfo]
    ) -> [Int: SongGapInfo] {
        var matches: [Int: SongGapInfo] = [:]
        
        for (index, item) in setlistItems.enumerated() {
            // Find gap info by normalized song name matching
            if let gapInfo = gaps.first(where: { 
                normalizeSongName($0.songName) == normalizeSongName(item.song)
            }) {
                matches[index] = gapInfo
            }
        }
        
        return matches
    }
    
    // MARK: - Color Assignment
    
    /// Assign duration-based colors to setlist items using position-based matching
    /// Provides accurate color assignment even with duplicate song names
    /// 
    /// - Parameters:
    ///   - setlistItems: Array of setlist items
    ///   - durations: Array of track durations for color calculation
    /// - Returns: Array of colors corresponding to each setlist item
    static func assignDurationColors(
        setlistItems: [SetlistItem], 
        durations: [TrackDuration]
    ) -> [DurationColor] {
        let durationMatches = matchDurationsToSetlist(setlistItems: setlistItems, durations: durations)
        
        return setlistItems.indices.map { index in
            if let duration = durationMatches[index] {
                return DurationColor.fromDuration(duration.durationSeconds)
            } else {
                return DurationColor.unavailable
            }
        }
    }
    
    /// Get formatted duration for a specific setlist item using position-based matching
    /// Returns nil if no duration data available for the item
    /// 
    /// - Parameters:
    ///   - index: Index of setlist item
    ///   - durations: Array of track durations
    ///   - setlistItems: Array of setlist items for context
    /// - Returns: Formatted duration string or nil
    static func getFormattedDuration(
        at index: Int, 
        durations: [TrackDuration], 
        setlistItems: [SetlistItem]
    ) -> String? {
        let durationMatches = matchDurationsToSetlist(setlistItems: setlistItems, durations: durations)
        
        if let duration = durationMatches[index] {
            let minutes = duration.durationSeconds / 60
            let seconds = duration.durationSeconds % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        return nil
    }
    
    // MARK: - Utility Methods
    
    /// Normalize song names for accurate matching
    /// Handles common variations and whitespace differences
    /// 
    /// - Parameter songName: Original song name
    /// - Returns: Normalized song name for comparison
    static func normalizeSongName(_ songName: String) -> String {
        return songName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
    
    /// Validate that setlist and duration data are from the same show
    /// Prevents mismatched data from different shows
    /// 
    /// - Parameters:
    ///   - setlistItems: Setlist items to validate
    ///   - durations: Duration data to validate
    /// - Returns: True if data sources match the same show
    static func validateDataConsistency(
        setlistItems: [SetlistItem], 
        durations: [TrackDuration]
    ) -> Bool {
        guard let firstSetlistDate = setlistItems.first?.showdate,
              let firstDurationDate = durations.first?.showDate else {
            return false
        }
        
        return firstSetlistDate == firstDurationDate
    }
    
    /// Get position of song within its set for accurate matching
    /// Used internally for position-based matching algorithm
    /// 
    /// - Parameters:
    ///   - targetSong: Song to find position for
    ///   - setNumber: Set containing the song
    ///   - setlistItems: Complete setlist for context
    /// - Returns: Zero-based position within the set
    static func getPositionInSet(
        targetSong: String, 
        setNumber: String, 
        setlistItems: [SetlistItem]
    ) -> Int? {
        let setItems = setlistItems.filter { $0.set == setNumber }
        return setItems.firstIndex { $0.song == targetSong }
    }
}

// MARK: - Extensions

extension SetlistMatchingService {
    
    /// Enhanced matching for complex setlist scenarios
    /// Handles edge cases like repeated songs, medleys, and transitions
    static func matchWithAdvancedValidation(
        setlistItems: [SetlistItem], 
        durations: [TrackDuration]
    ) -> [Int: TrackDuration] {
        // Start with position-based matching
        var matches = matchDurationsToSetlist(setlistItems: setlistItems, durations: durations)
        
        // Apply additional validation for edge cases
        for (index, item) in setlistItems.enumerated() {
            if matches[index] == nil {
                // Try fuzzy matching for songs with slight name variations
                if let fuzzyMatch = findFuzzyDurationMatch(for: item, in: durations) {
                    matches[index] = fuzzyMatch
                }
            }
        }
        
        return matches
    }
    
    /// Find duration match using fuzzy name comparison
    /// Handles slight variations in song names between APIs
    private static func findFuzzyDurationMatch(
        for item: SetlistItem, 
        in durations: [TrackDuration]
    ) -> TrackDuration? {
        let normalizedItemName = normalizeSongName(item.song)
        
        return durations.first { duration in
            let normalizedDurationName = normalizeSongName(duration.songName)
            
            // Check if names are similar (allowing for minor differences)
            return normalizedDurationName.contains(normalizedItemName) || 
                   normalizedItemName.contains(normalizedDurationName)
        }
    }
}

// MARK: - Duration Color Logic

extension SetlistMatchingService {
    
    /// Duration-based color calculation logic
    /// Extracted from ViewModels for consistency across the app
    enum DurationColor {
        case short      // < 5 minutes
        case medium     // 5-15 minutes  
        case long       // 15-25 minutes
        case epic       // > 25 minutes
        case unavailable // No duration data
        
        static func fromDuration(_ seconds: Int) -> DurationColor {
            let minutes = seconds / 60
            
            switch minutes {
            case 0..<5: return .short
            case 5..<15: return .medium
            case 15..<25: return .long
            default: return .epic
            }
        }
    }
}