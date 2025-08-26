//
//  SharedModels.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//

import Foundation

// MARK: - Audio/Recording Models

struct TrackDuration: Codable, Identifiable {
    let id: String
    let songName: String
    let durationSeconds: Int
    let showDate: String
    let setNumber: String
    
    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct Recording: Codable, Identifiable {
    let id: String
    let showDate: String
    let venue: String
    let recordingType: RecordingType
    let url: String?
    let isAvailable: Bool
}

enum RecordingType: String, Codable {
    case audience = "aud"
    case soundboard = "sbd"
    case matrix = "matrix"
}

// MARK: - Tour Models

struct Tour: Codable, Identifiable {
    let id: String
    let name: String
    let year: String
    let startDate: String
    let endDate: String
    let showCount: Int
}

struct TourShowPosition: Codable {
    let tourName: String
    let showNumber: Int
    let totalShows: Int
    let tourYear: String
    
    var displayText: String {
        if totalShows > 1 {
            return "\(tourName) (\(showNumber)/\(totalShows))"
        }
        return tourName
    }
    
    var shortDisplayText: String {
        if totalShows > 1 {
            return "\(tourName) \(showNumber)/\(totalShows)"
        }
        return ""
    }
}

struct VenueRun: Codable {
    let venue: String
    let city: String
    let state: String?
    let nightNumber: Int
    let totalNights: Int
    let showDates: [String]
    
    var runDisplayText: String {
        if totalNights > 1 {
            return "N\(nightNumber)/\(totalNights)"
        }
        return ""
    }
}

// MARK: - User Models

struct UserSession: Codable {
    let userId: String
    let username: String
    let token: String
    let expiresAt: Date
}

struct Playlist: Codable, Identifiable {
    let id: String
    let name: String
    let showIds: [String]
    let createdAt: Date
    let updatedAt: Date
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