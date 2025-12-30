//
//  TourStatisticsModels.swift
//  PhishQS
//
//  Split from SharedModels.swift for better organization
//  Contains tour statistics-related data models
//

import Foundation

// MARK: - Tour Context Protocol

/// Protocol for models that can provide tour context information
protocol TourContextProvider {
    var city: String? { get }
    var state: String? { get }
    var tourPosition: TourShowPosition? { get }
    var showDate: String { get }
    var venue: String? { get }

    /// Formatted city and state display text
    var cityStateDisplayText: String? { get }
    /// Formatted tour position badge text (e.g., "4/23")
    var tourPositionBadgeText: String? { get }
}

/// Default implementation of TourContextProvider methods
extension TourContextProvider {
    var cityStateDisplayText: String? {
        guard let city = city else { return nil }

        if let state = state {
            return "\(city), \(state)"
        } else {
            return city
        }
    }

    var tourPositionBadgeText: String? {
        guard let tourPosition = tourPosition else { return nil }
        return "\(tourPosition.showNumber)/\(tourPosition.totalShows)"
    }
}

// MARK: - Song Statistics Models

/// Song gap information from Phish.net API
struct SongGapInfo: Codable, Identifiable {
    let id: Int               // Use songId as unique identifier
    let songId: Int           // Phish.net songid
    let songName: String      // Song name
    let gap: Int             // Shows since last performance (0 = most recent)
    let lastPlayed: String?  // Date last performed BEFORE current tour ("2024-07-12")
    let timesPlayed: Int?    // Total times performed
    let tourVenue: String?   // Venue where played in current tour (if applicable)
    let tourVenueRun: VenueRun? // Venue run info for current tour performance (if applicable)
    let tourDate: String?    // Date when played in current tour (if applicable)

    // Tour context fields
    let tourCity: String?    // City where song was played in current tour
    let tourState: String?   // State where song was played in current tour
    let tourPosition: TourShowPosition? // Position within tour (e.g., show 4 of 23)

    // Historical information (last played before current tour)
    let historicalVenue: String?     // Venue where song was actually last played before current tour
    let historicalCity: String?      // City where song was last played before current tour
    let historicalState: String?     // State where song was last played before current tour
    let historicalLastPlayed: String? // Actual date when song was last played before current tour

    /// Formatted gap display text
    var gapDisplayText: String {
        if gap == 0 {
            return "Most recent"
        } else if gap == 1 {
            return "1 show ago"
        } else {
            return "\(gap) shows ago"
        }
    }

    /// Formatted last played date
    var lastPlayedFormatted: String? {
        guard let lastPlayed = lastPlayed else { return nil }
        return DateUtilities.formatDateForDisplay(lastPlayed)
    }

    /// Tour venue display text (venue and night info if multi-night run)
    var tourVenueDisplayText: String? {
        guard let venue = tourVenue else { return nil }

        // If multi-night run, include night indicator
        if let venueRun = tourVenueRun, venueRun.totalNights > 1 {
            return "\(venue), N\(venueRun.nightNumber)"
        }

        // Single night, just venue name
        return venue
    }

    /// Formatted tour date for display (when song was played in current tour)
    var tourDateFormatted: String? {
        guard let tourDate = tourDate else { return nil }
        return DateUtilities.formatDateForDisplay(tourDate)
    }

    /// Formatted historical last played date (actual last played before current tour)
    var historicalLastPlayedFormatted: String? {
        guard let historicalLastPlayed = historicalLastPlayed else {
            // Fallback to original lastPlayed if historical data not available
            guard let lastPlayed = lastPlayed else { return nil }
            return DateUtilities.formatDateForDisplay(lastPlayed)
        }
        return DateUtilities.formatDateForDisplay(historicalLastPlayed)
    }

    /// Historical venue display text with city/state
    var historicalVenueDisplayText: String? {
        guard let venue = historicalVenue else { return nil }

        var displayText = venue
        if let city = historicalCity {
            displayText += ", \(city)"
            if let state = historicalState {
                displayText += ", \(state)"
            }
        }
        return displayText
    }

    /// Initialize with songId as id
    init(songId: Int, songName: String, gap: Int, lastPlayed: String?, timesPlayed: Int?, tourVenue: String? = nil, tourVenueRun: VenueRun? = nil, tourDate: String? = nil, tourCity: String? = nil, tourState: String? = nil, tourPosition: TourShowPosition? = nil, historicalVenue: String? = nil, historicalCity: String? = nil, historicalState: String? = nil, historicalLastPlayed: String? = nil) {
        self.id = songId
        self.songId = songId
        self.songName = songName
        self.gap = gap
        self.lastPlayed = lastPlayed
        self.timesPlayed = timesPlayed
        self.tourVenue = tourVenue
        self.tourVenueRun = tourVenueRun
        self.tourDate = tourDate
        self.tourCity = tourCity
        self.tourState = tourState
        self.tourPosition = tourPosition
        self.historicalVenue = historicalVenue
        self.historicalCity = historicalCity
        self.historicalState = historicalState
        self.historicalLastPlayed = historicalLastPlayed
    }
}

// MARK: - SongGapInfo TourContextProvider Conformance

extension SongGapInfo: TourContextProvider {
    var city: String? { tourCity }
    var state: String? { tourState }
    var showDate: String { tourDate ?? lastPlayed ?? "" }
    var venue: String? { tourVenue }
}

/// Most played song information for tour statistics
struct MostPlayedSong: Codable, Identifiable {
    let id: Int               // Use songId as unique identifier
    let songId: Int           // Phish.net songid
    let songName: String      // Song name
    let playCount: Int        // Number of times played in tour

    /// Initialize with songId as id
    init(songId: Int, songName: String, playCount: Int) {
        self.id = songId
        self.songId = songId
        self.songName = songName
        self.playCount = playCount
    }
}

/// Most common song not played information for tour statistics
/// Represents popular songs from Phish history that haven't been played on current tour
struct MostCommonSongNotPlayed: Codable, Identifiable {
    let id: Int                    // Use songId as unique identifier
    let songId: Int                // Phish.net songid
    let songName: String           // Song name
    let historicalPlayCount: Int   // Total times played in Phish history
    let originalArtist: String?    // Original artist (for covers)

    /// Get display text showing if this is a cover song
    var songTypeDisplay: String {
        if let artist = originalArtist, artist != "Phish" {
            return "Cover (\(artist))"
        }
        return "Original"
    }

    /// Initialize with songId as id
    init(songId: Int, songName: String, historicalPlayCount: Int, originalArtist: String? = nil) {
        self.id = songId
        self.songId = songId
        self.songName = songName
        self.historicalPlayCount = historicalPlayCount
        self.originalArtist = originalArtist
    }
}

/// Per-show duration availability info (single source of truth from tour-statistics API)
struct ShowDurationAvailability: Codable, Identifiable {
    let date: String
    let venue: String
    let city: String
    let state: String
    let durationsAvailable: Bool

    var id: String { date }

    /// Formatted date for display
    var formattedDate: String {
        DateUtilities.formatDateForDisplay(date) ?? date
    }

    /// Full venue display text
    var venueDisplayText: String {
        "\(venue), \(city), \(state)"
    }
}

/// Combined tour statistics for display
struct TourSongStatistics: Codable {
    let longestSongs: [TrackDuration]        // Top 3 longest songs by duration
    let rarestSongs: [SongGapInfo]           // Top 3 rarest songs by gap
    let mostPlayedSongs: [MostPlayedSong]    // Top 3 most played songs by frequency
    let mostCommonSongsNotPlayed: [MostCommonSongNotPlayed]? // Top 20 common songs not played
    let tourName: String?                    // Current tour name for context
    let showDurationAvailability: [ShowDurationAvailability]? // Per-show duration data availability

    /// Check if statistics data is available
    var hasData: Bool {
        return !longestSongs.isEmpty || !rarestSongs.isEmpty || !mostPlayedSongs.isEmpty || !(mostCommonSongsNotPlayed?.isEmpty ?? true)
    }

    /// Number of shows with duration data
    var showsWithDurations: Int {
        showDurationAvailability?.filter { $0.durationsAvailable }.count ?? 0
    }

    /// Total number of played shows
    var totalPlayedShows: Int {
        showDurationAvailability?.count ?? 0
    }
}

// MARK: - Song Performance Models

/// Song performance from Phish.net setlists API
struct SongPerformance: Codable {
    let showid: Int
    let showdate: String
    let showyear: String
    let venue: String
    let city: String
    let state: String?
    let country: String
    let permalink: String

    // Gap information
    let gap: Int                        // Number of shows since last performance
    let songid: Int                     // Song ID for reliable matching
    let song: String                    // Song name
    let slug: String                    // URL-friendly song name

    // Additional performance details
    let set: String?                    // Set number where song was played
    let position: Int?                  // Position within the set
    let trans_mark: String?            // Transition mark (>, ->, etc.)
    let footnote: String?              // Any special notes about this performance
}