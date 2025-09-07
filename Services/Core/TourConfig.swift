//
//  TourConfig.swift
//  PhishQS
//
//  Created by Claude on 9/4/25.
//

import Foundation

/// Configuration management for current active tour
/// Eliminates hardcoded tour-specific values throughout the codebase
/// 
/// **Usage**: Replace hardcoded "Summer Tour 2025" and show counts with dynamic configuration
/// **Benefits**: 
/// - Supports future tours without code changes
/// - Single source of truth for tour information  
/// - Easy tour transitions between seasons
struct TourConfig {
    
    // MARK: - Current Tour Configuration
    
    /// Currently active tour name as used by Phish.net API
    static let currentTourName = "2025 Early Summer Tour"
    
    /// Current tour year
    static let currentTourYear = "2025"
    
    /// Total scheduled shows for current tour (from Phish.net complete schedule)
    /// This includes both played and future shows for accurate position calculations
    static let currentTourTotalShows = 23
    
    /// Start date of current tour
    static let currentTourStartDate = "2025-06-21"
    
    /// End date of current tour (scheduled)
    static let currentTourEndDate = "2025-09-04"
    
    // MARK: - Sample Data for Previews
    
    /// Sample show count for UI previews (should reflect current tour progress)
    static let samplePlayedShows = 23
    
    /// Sample tour position for previews
    static let sampleTourPosition = TourShowPosition(
        tourName: currentTourName,
        showNumber: 4,
        totalShows: currentTourTotalShows,
        tourYear: currentTourYear
    )
    
    /// Sample venue run for previews
    static let sampleVenueRun = VenueRun(
        venue: "Madison Square Garden", 
        city: "New York", 
        state: "NY", 
        nightNumber: 3, 
        totalNights: 4, 
        showDates: [
            "2025-07-25", 
            "2025-07-26", 
            "2025-07-27", 
            "2025-07-28"
        ]
    )
    
    // MARK: - Utility Methods
    
    /// Check if a given date falls within the current tour period
    /// - Parameter date: Date string in YYYY-MM-DD format
    /// - Returns: Boolean indicating if date is within current tour
    static func isDateInCurrentTour(_ date: String) -> Bool {
        return date >= currentTourStartDate && date <= currentTourEndDate
    }
    
    /// Get formatted tour badge text for current position
    /// - Parameter currentShow: Current show number within tour
    /// - Returns: Formatted string like "4/31" for tour position display
    static func tourPositionBadge(currentShow: Int) -> String {
        return "\(currentShow)/\(currentTourTotalShows)"
    }
    
    /// Generate sample track duration with current tour context
    /// - Parameters:
    ///   - id: Track identifier
    ///   - songName: Name of the song
    ///   - songId: Song database ID
    ///   - durationSeconds: Duration in seconds
    ///   - showDate: Show date in YYYY-MM-DD format
    ///   - setNumber: Set identifier
    ///   - venue: Venue name
    ///   - city: City name  
    ///   - state: State abbreviation
    ///   - showNumber: Show number within tour
    /// - Returns: TrackDuration with current tour context
    static func sampleTrackDuration(
        id: String,
        songName: String,
        songId: Int,
        durationSeconds: Int,
        showDate: String,
        setNumber: String,
        venue: String,
        city: String,
        state: String,
        showNumber: Int
    ) -> TrackDuration {
        let tourPosition = TourShowPosition(
            tourName: currentTourName,
            showNumber: showNumber,
            totalShows: currentTourTotalShows,
            tourYear: currentTourYear
        )
        
        return TrackDuration(
            id: id,
            songName: songName,
            songId: songId,
            durationSeconds: durationSeconds,
            showDate: showDate,
            setNumber: setNumber,
            venue: venue,
            venueRun: nil, // Can be set separately if needed
            city: city,
            state: state,
            tourPosition: tourPosition
        )
    }
    
    /// Generate sample song gap info with current tour context
    /// - Parameters:
    ///   - songId: Song database ID
    ///   - songName: Name of the song
    ///   - gap: Gap in shows since last played
    ///   - lastPlayed: Date last played
    ///   - timesPlayed: Total times played historically
    ///   - tourDate: Date played during current tour
    ///   - tourVenue: Venue where played in current tour
    ///   - tourCity: City where played in current tour
    ///   - tourState: State where played in current tour
    ///   - showNumber: Show number within current tour
    /// - Returns: SongGapInfo with current tour context
    static func sampleSongGapInfo(
        songId: Int,
        songName: String,
        gap: Int,
        lastPlayed: String,
        timesPlayed: Int,
        tourDate: String,
        tourVenue: String,
        tourCity: String,
        tourState: String,
        showNumber: Int
    ) -> SongGapInfo {
        let tourPosition = TourShowPosition(
            tourName: currentTourName,
            showNumber: showNumber,
            totalShows: currentTourTotalShows,
            tourYear: currentTourYear
        )
        
        return SongGapInfo(
            songId: songId,
            songName: songName,
            gap: gap,
            lastPlayed: lastPlayed,
            timesPlayed: timesPlayed,
            tourVenue: tourVenue,
            tourVenueRun: nil, // Can be set separately if needed
            tourDate: tourDate,
            tourCity: tourCity,
            tourState: tourState,
            tourPosition: tourPosition
        )
    }
}

// MARK: - Future Tour Support

/// Extension for managing tour transitions and multi-tour support
extension TourConfig {
    
    /// Detect if current date suggests a new tour period
    /// Can be used to prompt for tour configuration updates
    static var shouldCheckForNewTour: Bool {
        let today = Date().formatted(.iso8601.year().month().day())
        return today > currentTourEndDate
    }
    
    /// Placeholder for future dynamic tour detection
    /// Currently returns static configuration but can be enhanced
    /// to detect tours from API data or configuration files
    static func detectCurrentTour() -> (name: String, year: String, totalShows: Int) {
        return (
            name: currentTourName,
            year: currentTourYear, 
            totalShows: currentTourTotalShows
        )
    }
}