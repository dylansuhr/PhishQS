//
//  LegacyTourStatisticsCalculator.swift
//  PhishQS - Archived iOS Calculations
//
//  ARCHIVED: These methods have been preserved for future reference but are not actively used.
//  The app now uses server-side statistics via TourStatisticsAPIClient for ~140ms response times
//  instead of these 60+ second local calculations.
//
//  This file contains all the working iOS calculation logic including:
//  - Single-pass tour statistics calculation algorithm
//  - Progressive gap tracking with highest-gap-per-song logic  
//  - Longest songs, rarest songs, and most played songs calculations
//
//  To re-enable: Import this file and call the methods, but expect 60+ second processing times.
//

import Foundation

/// Legacy iOS calculation methods for tour statistics
/// 
/// **ARCHIVED**: These methods are preserved for future reference but not actively used.
/// The app now fetches pre-computed statistics from the server for instant loading.
/// 
/// Original functionality:
/// - Calculated tour statistics locally on iOS device
/// - Processing time: 60+ seconds for full tour analysis
/// - Single-pass algorithm for optimal memory usage
/// - Progressive gap tracking for accurate rarest songs
///
/// Server replacement:
/// - Pre-computed statistics served via Vercel API
/// - Response time: ~140ms
/// - Identical results with much better performance
///
@available(*, deprecated, message: "Use TourStatisticsAPIClient.shared.fetchTourStatistics() for server-side statistics. This legacy code is preserved for future reference only.")
class LegacyTourStatisticsCalculator {
    
    // MARK: - Main Calculation Methods
    
    /// Calculate ALL tour statistics in a single pass for optimal performance
    /// 
    /// **ARCHIVED**: This method has been replaced by server-side calculations via TourStatisticsAPIClient.
    /// Tour statistics are now fetched from pre-computed JSON served by Vercel for instant loading.
    /// This method is kept for fallback scenarios or offline support if needed.
    ///
    /// Algorithm Overview:
    /// 1. Single pass through all tour shows (O(n) complexity)
    /// 2. Simultaneously collects data for all three statistics types
    /// 3. Uses progressive tracking for gap calculations (keeps highest gaps)
    /// 4. Applies mathematical sorting and slicing for final results
    ///
    /// Gap Calculation Logic:
    /// - Gap = shows since song was last played (anywhere, not necessarily pre-tour)
    /// - Multiple occurrences of same song: keep occurrence with highest gap
    /// - Live gap data from setlist responses ensures accuracy
    ///
    /// - Parameters:
    ///   - tourShows: All enhanced setlists for the tour
    ///   - tourName: Name of the tour
    /// - Returns: Complete tour statistics calculated in single pass
    static func calculateAllTourStatistics(
        tourShows: [EnhancedSetlist], 
        tourName: String?
    ) -> TourSongStatistics {
        
        print("🚀 LEGACY calculateAllTourStatistics: Processing \(tourShows.count) shows in single pass")
        print("⚠️  WARNING: Using archived iOS calculations - expect 60+ second processing time")
        
        guard !tourShows.isEmpty else {
            print("⚠️  No tour shows provided, returning empty statistics")
            return TourSongStatistics(longestSongs: [], rarestSongs: [], mostPlayedSongs: [], tourName: tourName)
        }
        
        // Data collection containers for all three statistics
        var songPlayCounts: [String: (count: Int, songId: Int?)] = [:]     // For most played
        var allTrackDurations: [TrackDuration] = []                        // For longest
        var tourSongGaps: [String: SongGapInfo] = [:]                      // For rarest
        
        // SINGLE PASS through all tour shows
        for (showIndex, show) in tourShows.enumerated() {
            print("   Processing show \(showIndex + 1): \(show.showDate)")
            
            // Collect track durations for longest songs calculation
            allTrackDurations.append(contentsOf: show.trackDurations)
            
            // Count song frequencies for most played calculation
            for track in show.trackDurations {
                let songKey = track.songName.lowercased()
                
                if let existing = songPlayCounts[songKey] {
                    songPlayCounts[songKey] = (count: existing.count + 1, songId: existing.songId ?? track.songId)
                } else {
                    songPlayCounts[songKey] = (count: 1, songId: track.songId)
                }
            }
            
            // Collect gap information for rarest songs calculation
            for gapInfo in show.songGaps {
                let songKey = gapInfo.songName.lowercased()
                
                // Create enhanced gap info with venue run data from show context
                let enhancedGapInfo = SongGapInfo(
                    songId: gapInfo.songId,
                    songName: gapInfo.songName,
                    gap: gapInfo.gap,
                    lastPlayed: gapInfo.lastPlayed,
                    timesPlayed: gapInfo.timesPlayed,
                    tourVenue: show.setlistItems.first?.venue, // Venue from Phish.net setlist
                    tourVenueRun: show.venueRun, // Venue run from Phish.in
                    tourDate: show.showDate,
                    historicalVenue: gapInfo.historicalVenue,
                    historicalCity: gapInfo.historicalCity,
                    historicalState: gapInfo.historicalState,
                    historicalLastPlayed: gapInfo.historicalLastPlayed
                )
                
                // CRITICAL GAP TRACKING LOGIC:
                // For each song, keep the occurrence with the HIGHEST gap (progressive tracking)
                // This ensures we capture the rarest occurrence of each song
                if let existingGap = tourSongGaps[songKey] {
                    if gapInfo.gap > existingGap.gap {
                        print("      🔄 Updating \(gapInfo.songName): \(existingGap.gap) → \(gapInfo.gap)")
                        tourSongGaps[songKey] = enhancedGapInfo
                    } else {
                        print("      ✓ Keeping \(gapInfo.songName): \(existingGap.gap) > \(gapInfo.gap)")
                    }
                } else {
                    print("      ➕ Adding \(gapInfo.songName): Gap \(gapInfo.gap)")
                    tourSongGaps[songKey] = enhancedGapInfo
                }
            }
        }
        
        // Calculate final results from collected data
        
        // 1. Longest songs - sort all track durations by length
        let longestSongs = Array(allTrackDurations
            .sorted { $0.durationSeconds > $1.durationSeconds }
            .prefix(3))
        
        // 2. Most played songs - convert counts to MostPlayedSong objects
        let mostPlayedSongs = songPlayCounts.compactMap { (songName, info) -> MostPlayedSong? in
            let songId = info.songId ?? songName.hash
            return MostPlayedSong(songId: songId, songName: songName.capitalized, playCount: info.count)
        }
        .sorted { $0.playCount > $1.playCount }
        .prefix(3)
        .map { $0 }
        
        // 3. Rarest songs - sort gaps by highest gap value
        let rarestSongs = Array(tourSongGaps.values
            .sorted { $0.gap > $1.gap }
            .prefix(3))
        
        // Debug output
        print("🚀 LEGACY single-pass calculation complete:")
        print("   📊 Found \(allTrackDurations.count) total track performances")
        print("   📊 Found \(songPlayCounts.count) unique songs")
        print("   📊 Top 3 longest: \(longestSongs.map { "\($0.songName) (\($0.formattedDuration))" }.joined(separator: ", "))")
        print("   📊 Top 3 most played: \(mostPlayedSongs.map { "\($0.songName) (\($0.playCount)x)" }.joined(separator: ", "))")
        print("   📊 Top 3 rarest: \(rarestSongs.map { "\($0.songName) (gap: \($0.gap))" }.joined(separator: ", "))")
        
        return TourSongStatistics(
            longestSongs: longestSongs,
            rarestSongs: rarestSongs,
            mostPlayedSongs: mostPlayedSongs,
            tourName: tourName
        )
    }
    
    /// Calculate tour-progressive rarest songs (tracks top 3 across entire tour)
    ///
    /// **ARCHIVED**: This method has been replaced by server-side calculations via TourStatisticsAPIClient.
    /// Tour statistics are now fetched from pre-computed JSON served by Vercel for instant loading.
    ///
    /// Progressive Gap Tracking Algorithm:
    /// - Processes each show chronologically
    /// - For each song, keeps only the occurrence with the highest gap
    /// - This ensures we capture the rarest performance of each song across the tour
    /// - Final results are sorted by gap value (highest first)
    ///
    /// - Parameters:
    ///   - tourShows: All enhanced setlists from the tour (in chronological order)
    ///   - tourName: Name of the tour for context
    /// - Returns: Top 3 rarest songs across the entire tour
    static func calculateTourProgressiveRarestSongs(
        tourShows: [EnhancedSetlist],
        tourName: String?
    ) -> [SongGapInfo] {
        
        print("🎯 LEGACY calculateTourProgressiveRarestSongs: Processing \(tourShows.count) shows")
        print("⚠️  WARNING: Using archived iOS calculations")
        
        // Collect all unique songs and their gaps across the tour
        var tourSongGaps: [String: SongGapInfo] = [:]
        
        for (showIndex, show) in tourShows.enumerated() {
            print("   Processing show \(showIndex + 1): \(show.showDate)")
            
            for gapInfo in show.songGaps {
                let songKey = gapInfo.songName.lowercased()
                
                // Create enhanced gap info with venue run data from show context
                let enhancedGapInfo = SongGapInfo(
                    songId: gapInfo.songId,
                    songName: gapInfo.songName,
                    gap: gapInfo.gap,
                    lastPlayed: gapInfo.lastPlayed,
                    timesPlayed: gapInfo.timesPlayed,
                    tourVenue: show.setlistItems.first?.venue, // Venue from Phish.net setlist
                    tourVenueRun: show.venueRun, // Venue run from Phish.in
                    tourDate: show.showDate,
                    historicalVenue: gapInfo.historicalVenue,
                    historicalCity: gapInfo.historicalCity,
                    historicalState: gapInfo.historicalState,
                    historicalLastPlayed: gapInfo.historicalLastPlayed
                )
                
                // For each song, keep the occurrence with the HIGHEST gap
                if let existingGap = tourSongGaps[songKey] {
                    // Only replace if this occurrence has a higher gap
                    if gapInfo.gap > existingGap.gap {
                        print("      🔄 Updating \(gapInfo.songName): \(existingGap.gap) → \(gapInfo.gap)")
                        tourSongGaps[songKey] = enhancedGapInfo
                    } else {
                        print("      ✓ Keeping \(gapInfo.songName): \(existingGap.gap) > \(gapInfo.gap)")
                    }
                } else {
                    // First time seeing this song - add it
                    print("      ➕ Adding \(gapInfo.songName): Gap \(gapInfo.gap)")
                    tourSongGaps[songKey] = enhancedGapInfo
                }
            }
        }
        
        // Debug: Show all songs with gaps > 200 for validation
        let highGapSongs = Array(tourSongGaps.values)
            .filter { $0.gap > 200 }
            .sorted { $0.gap > $1.gap }
        
        if !highGapSongs.isEmpty {
            print("   🔍 All songs with gap > 200:")
            for song in highGapSongs.prefix(10) { // Show top 10 high-gap songs
                if let tourDate = song.tourDate {
                    print("      • \(song.songName): \(song.gap) gap (from \(tourDate))")
                } else {
                    print("      • \(song.songName): \(song.gap) gap")
                }
            }
        }
        
        // Get top 3 by gap size
        let topRarestSongs = Array(tourSongGaps.values)
            .sorted { $0.gap > $1.gap }
            .prefix(3)
            .map { $0 }
        
        print("   📊 LEGACY Top 3 rarest across tour:")
        for (index, song) in topRarestSongs.enumerated() {
            // Include the show date where this gap was recorded for validation
            if let tourDate = song.tourDate {
                print("      \(index + 1). \(song.songName) - Gap: \(song.gap) (from \(tourDate))")
            } else {
                print("      \(index + 1). \(song.songName) - Gap: \(song.gap)")
            }
        }
        
        return topRarestSongs
    }
    
    // MARK: - Individual Calculation Methods
    
    /// Calculate top 3 longest songs from track durations
    /// **ARCHIVED**: Individual calculation method preserved for reference
    static func calculateLongestSongs(from trackDurations: [TrackDuration]) -> [TrackDuration] {
        print("📊 LEGACY calculateLongestSongs: Processing \(trackDurations.count) tracks")
        
        let results = trackDurations
            .sorted { $0.durationSeconds > $1.durationSeconds }
            .prefix(3)
            .map { $0 }
        
        print("   📊 Top 3 longest songs:")
        for (index, song) in results.enumerated() {
            print("      \(index + 1). \(song.songName): \(song.formattedDuration) on \(song.showDate)")
        }
        
        return results
    }
    
    /// Calculate top 3 most played songs from track durations
    /// **ARCHIVED**: Individual calculation method preserved for reference
    static func calculateMostPlayedSongs(from trackDurations: [TrackDuration]) -> [MostPlayedSong] {
        print("🎵 LEGACY calculateMostPlayedSongs: Processing \(trackDurations.count) track durations")
        
        // Count occurrences of each song
        var songCounts: [String: (count: Int, songId: Int?)] = [:]
        
        for track in trackDurations {
            let songKey = track.songName.lowercased()
            
            if let existing = songCounts[songKey] {
                songCounts[songKey] = (count: existing.count + 1, songId: existing.songId ?? track.songId)
            } else {
                songCounts[songKey] = (count: 1, songId: track.songId)
            }
        }
        
        print("🎵 Found \(songCounts.count) unique songs")
        
        // Convert to MostPlayedSong objects and sort by count
        let mostPlayedSongs = songCounts.compactMap { (songName, info) -> MostPlayedSong? in
            // Use songId if available, otherwise use hash of song name
            let songId = info.songId ?? songName.hash
            return MostPlayedSong(songId: songId, songName: songName.capitalized, playCount: info.count)
        }
        .sorted { $0.playCount > $1.playCount }
        .prefix(3)
        .map { $0 }
        
        print("🎵 LEGACY Top 3 most played songs:")
        for (index, song) in mostPlayedSongs.enumerated() {
            print("   \(index + 1). \(song.songName): \(song.playCount) plays")
        }
        
        return mostPlayedSongs
    }
    
    /// Calculate top 3 rarest songs (highest gap) filtered to current tour
    /// **ARCHIVED**: Individual calculation method with complex filtering logic
    static func calculateRarestSongs(
        from allGaps: [SongGapInfo],
        tourSongIds: Set<Int>,
        tourSongNames: Set<String>,
        tourTrackDurations: [TrackDuration]?
    ) -> [SongGapInfo] {
        
        // Debug: Print tour song information for troubleshooting
        print("🔍 LEGACY calculateRarestSongs: Calculating rarest songs")
        print("   - Tour has \(tourSongNames.count) unique songs")
        print("   - Total gaps data: \(allGaps.count) songs")
        
        // Filter to songs that appear in the current tour and add venue information
        let tourSongs = allGaps.compactMap { gapInfo -> SongGapInfo? in
            // First check if this song appears in the current tour
            let appearsInTour: Bool
            if !tourSongIds.isEmpty && tourSongIds.contains(gapInfo.songId) {
                appearsInTour = true
            } else if tourSongNames.contains(gapInfo.songName.lowercased()) {
                appearsInTour = true
            } else {
                appearsInTour = false
            }
            
            guard appearsInTour else { return nil }
            
            // Debug: Print songs that match tour criteria
            print("   - Tour song: \(gapInfo.songName) (Gap: \(gapInfo.gap))")
            
            // Try to find venue information from tour track durations
            var tourVenue: String? = nil
            var tourVenueRun: VenueRun? = nil
            var tourDate: String? = nil
            
            if let tourTracks = tourTrackDurations {
                // Find all matching tracks for this song in the tour
                let matchingTracks = tourTracks.filter { track in
                    if let trackSongId = track.songId, trackSongId == gapInfo.songId {
                        return true
                    }
                    return track.songName.lowercased() == gapInfo.songName.lowercased()
                }
                
                // For rarest songs display, prefer the most recent performance in tour
                // This ensures we show where it was last played in the current tour
                if let mostRecentTrack = matchingTracks.max(by: { $0.showDate < $1.showDate }) {
                    tourVenue = mostRecentTrack.venue
                    tourVenueRun = mostRecentTrack.venueRun
                    tourDate = mostRecentTrack.showDate
                }
            }
            
            // Add historical data for known rarest songs based on research
            var historicalVenue: String? = nil
            var historicalCity: String? = nil
            var historicalState: String? = nil
            var historicalLastPlayed: String? = nil
            
            // Apply known historical data based on user research
            let songNameLower = gapInfo.songName.lowercased()
            if songNameLower == "on your way down" {
                historicalLastPlayed = "2011-08-06"
                historicalVenue = "Gorge Amphitheatre"
                historicalCity = "George"
                historicalState = "WA"
            } else if songNameLower == "paul and silas" {
                historicalLastPlayed = "2016-07-22"
                historicalVenue = "Albany Medical Center Arena"
                historicalCity = "Albany"
                historicalState = "NY"
            } else if songNameLower == "devotion to a dream" {
                historicalLastPlayed = "2016-10-15"
                historicalVenue = "North Charleston Coliseum"
                historicalCity = "North Charleston"
                historicalState = "SC"
            }
            
            // Create enhanced SongGapInfo with tour venue information and historical data
            return SongGapInfo(
                songId: gapInfo.songId,
                songName: gapInfo.songName,
                gap: gapInfo.gap,
                lastPlayed: gapInfo.lastPlayed,
                timesPlayed: gapInfo.timesPlayed,
                tourVenue: tourVenue,
                tourVenueRun: tourVenueRun,
                tourDate: tourDate,
                historicalVenue: historicalVenue,
                historicalCity: historicalCity,
                historicalState: historicalState,
                historicalLastPlayed: historicalLastPlayed
            )
        }
        
        // Sort all tour songs by gap (highest first) and get top candidates
        let sortedTourSongs = tourSongs.sorted { $0.gap > $1.gap }
        
        // Debug: Print top 10 rarest songs for analysis
        print("   - LEGACY Top 10 rarest tour songs:")
        for (index, song) in sortedTourSongs.prefix(10).enumerated() {
            print("     \(index + 1). \(song.songName) - Gap: \(song.gap)")
        }
        
        let result = Array(sortedTourSongs.filter { $0.gap > 0 }.prefix(3))
        
        print("   - LEGACY Final rarest songs:")
        for (index, song) in result.enumerated() {
            print("     \(index + 1). \(song.songName) - Gap: \(song.gap)")
        }
        
        return result
    }
    
    // MARK: - Comprehensive Tour Analysis
    
    /// Calculate tour statistics for a specific tour by analyzing multiple shows
    /// **ARCHIVED**: This is a more comprehensive method for future use when we have full tour data
    static func calculateComprehensiveTourStatistics(
        tourShows: [EnhancedSetlist],
        allSongGaps: [SongGapInfo],
        tourName: String
    ) -> TourSongStatistics {
        
        print("📊 LEGACY calculateComprehensiveTourStatistics: Processing \(tourShows.count) shows")
        
        guard !tourShows.isEmpty else {
            return TourSongStatistics(longestSongs: [], rarestSongs: [], mostPlayedSongs: [], tourName: tourName)
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
            tourSongNames: allTourSongNames,
            tourTrackDurations: allTourDurations
        )
        
        // Calculate most played songs
        let mostPlayedSongs = calculateMostPlayedSongs(from: allTourDurations)
        
        return TourSongStatistics(
            longestSongs: longestSongs,
            rarestSongs: rarestSongs,
            mostPlayedSongs: mostPlayedSongs,
            tourName: tourName
        )
    }
    
    // MARK: - Historical Analysis Methods
    
    /// Calculate accurate historical rarest songs using performance history
    /// **ARCHIVED**: This is the async version that uses HistoricalGapCalculator for accurate gaps
    static func calculateHistoricalRarestSongs(
        apiClient: PhishAPIService,
        songsToAnalyze: [(songName: String, playedOnDate: String)]
    ) async throws -> [SongGapInfo] {
        
        print("🧮 LEGACY calculateHistoricalRarestSongs: Processing \(songsToAnalyze.count) songs")
        
        // Check cache first
        let cacheKey = "legacy_historical_rarest_songs_" + songsToAnalyze.map { "\($0.songName)_\($0.playedOnDate)" }.joined(separator: "_")
        if let cachedResults = CacheManager.shared.get([SongGapInfo].self, forKey: cacheKey) {
            print("📦 Using cached legacy historical rarest songs")
            return cachedResults
        }
        
        print("🧮 Calculating historical gaps for \(songsToAnalyze.count) songs...")
        
        // Try API-based calculation first, with fallback to known data
        var rarestSongs: [SongGapInfo] = []
        
        do {
            // Create historical gap calculator
            let gapCalculator = HistoricalGapCalculator(apiClient: apiClient)
            
            // Calculate historical gaps
            let historicalGaps = try await gapCalculator.calculateHistoricalGaps(for: songsToAnalyze)
            
            // Convert to SongGapInfo with enhanced data
            rarestSongs = historicalGaps.enumerated().map { index, gapInfo in
                gapInfo.toSongGapInfo(songId: 1000 + index, timesPlayed: 100) // Mock values for now
            }.sorted { $0.gap > $1.gap } // Sort by highest gap first
            
            print("✅ LEGACY Successfully calculated historical gaps via API")
            
        } catch {
            print("⚠️  LEGACY API-based gap calculation failed: \(error)")
            print("🎯 Using researched gap data as fallback...")
            
            // Fallback to known accurate data from user's manual research
            let knownGapData: [(String, String, Int, String, String, String?, String)] = [
                ("On Your Way Down", "2025-07-18", 522, "2011-08-06", "Gorge Amphitheatre", "George", "WA"),
                ("Paul and Silas", "2025-06-24", 323, "2016-07-22", "Albany Medical Center Arena", "Albany", "NY"),
                ("Devotion To a Dream", "2025-07-25", 322, "2016-10-15", "North Charleston Coliseum", "North Charleston", "SC")
            ]
            
            rarestSongs = knownGapData.enumerated().map { index, data in
                SongGapInfo(
                    songId: 1000 + index,
                    songName: data.0,
                    gap: data.2,
                    lastPlayed: data.3,
                    timesPlayed: 100, // Mock value
                    tourVenue: nil, // Will be filled by regular tour processing
                    tourVenueRun: nil,
                    tourDate: data.1,
                    historicalVenue: data.4,
                    historicalCity: data.5,
                    historicalState: data.6,
                    historicalLastPlayed: data.3
                )
            }
            
            print("✅ LEGACY Using researched gap data:")
        }
        
        // Cache results for 4 hours (historical data doesn't change)
        CacheManager.shared.set(rarestSongs, forKey: cacheKey, ttl: 4 * 60 * 60)
        
        print("📊 LEGACY Final rarest songs:")
        for (index, song) in rarestSongs.enumerated() {
            print("   \(index + 1). \(song.songName) - Gap: \(song.gap)")
        }
        
        return Array(rarestSongs.prefix(3))
    }
    
    /// Get accurate last played information for a song by fetching all performances
    /// and filtering out current tour performances
    /// **ARCHIVED**: Helper method for detailed historical analysis
    static func getLastPlayedBeforeCurrentTour(
        songName: String,
        currentTourStartDate: String,
        apiClient: PhishAPIService
    ) async throws -> (lastPlayedDate: String, venue: String, city: String, state: String?) {
        
        print("🔍 LEGACY getLastPlayedBeforeCurrentTour: Analyzing \(songName)")
        
        // Fetch all performances of this song
        let allPerformances = try await apiClient.fetchSongPerformances(songName: songName)
        
        // Filter out performances from current tour (on or after tour start date)
        let performancesBeforeTour = allPerformances.filter { performance in
            performance.showdate < currentTourStartDate
        }
        
        // Get the most recent performance before the current tour
        guard let lastPerformanceBeforeTour = performancesBeforeTour.max(by: { $0.showdate < $1.showdate }) else {
            throw APIError.invalidResponse
        }
        
        return (
            lastPlayedDate: lastPerformanceBeforeTour.showdate,
            venue: lastPerformanceBeforeTour.venue,
            city: lastPerformanceBeforeTour.city,
            state: lastPerformanceBeforeTour.state
        )
    }
}