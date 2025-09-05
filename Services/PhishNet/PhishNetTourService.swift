//
//  PhishNetTourService.swift
//  PhishQS
//
//  Created by Claude on 9/4/25.
//

import Foundation

/// Service for fetching tour-related data from Phish.net API
/// Provides authoritative tour organization, show counts, and tour positions using Phish.net data
class PhishNetTourService {
    
    private let phishNetClient: PhishAPIClient
    
    init(phishNetClient: PhishAPIClient = PhishAPIClient.shared) {
        self.phishNetClient = phishNetClient
    }
    
    // MARK: - Tour Show Methods
    
    /// Fetch all shows for a specific tour by year and tour name
    /// Provides complete tour show listing from Phish.net API
    func fetchTourShows(year: String, tourName: String) async throws -> [Show] {
        let allYearShows = try await phishNetClient.fetchShows(forYear: year)
        
        // Filter shows by tour name (exact match)
        let tourShows = allYearShows.filter { show in
            show.tour_name == tourName
        }
        
        // Sort by date to ensure proper order
        return tourShows.sorted { $0.showdate < $1.showdate }
    }
    
    /// Get all shows for a year (used for tour detection)
    func fetchAllShowsForYear(_ year: String) async throws -> [Show] {
        return try await phishNetClient.fetchShows(forYear: year)
    }
    
    // MARK: - Tour Position Calculation
    
    /// Calculate tour position for a specific show
    /// Determines show number within tour using Phish.net show ordering
    func calculateTourPosition(for showDate: String, tourName: String) async throws -> TourShowPosition? {
        // Extract year from show date
        let year = String(showDate.prefix(4))
        
        // Get all shows for the tour
        let tourShows = try await fetchTourShows(year: year, tourName: tourName)
        
        // Find the show in the tour
        guard let currentShowIndex = tourShows.firstIndex(where: { $0.showdate == showDate }) else {
            return nil
        }
        
        return TourShowPosition(
            tourName: tourName,
            showNumber: currentShowIndex + 1,
            totalShows: tourShows.count,
            tourYear: year
        )
    }
    
    // MARK: - Tour Detection
    
    /// Extract tour name from a show (if available)
    /// Uses Phish.net tour_name field for consistent tour identification
    func extractTourFromShow(_ show: Show) -> String? {
        return show.tour_name
    }
    
    /// Get tour name for a specific show date by fetching show data
    func getTourNameForShow(date: String) async throws -> String? {
        let year = String(date.prefix(4))
        let allYearShows = try await fetchAllShowsForYear(year)
        
        guard let show = allYearShows.first(where: { $0.showdate == date }) else {
            return nil
        }
        
        return extractTourFromShow(show)
    }
    
    // MARK: - Venue Run Calculation
    
    /// Calculate venue runs for a set of shows
    /// Note: Venue information comes from setlist data, not show data
    /// This method is preserved for interface compatibility but venue runs
    /// are calculated in the enhanced setlist service using venue-rich setlist data
    func calculateVenueRuns(for shows: [Show]) -> [String: VenueRun] {
        // Venue runs are calculated from setlist data which includes venue information
        // The enhanced setlist service handles venue run detection using setlist venue data
        // This method returns empty for Show-only data as venue info is not available
        return [:]
    }
    
    /// Get venue run for a specific show date within a tour
    func getVenueRun(for showDate: String, in tourShows: [Show]) -> VenueRun? {
        let venueRuns = calculateVenueRuns(for: tourShows)
        return venueRuns[showDate]
    }
    
    // MARK: - Convenience Methods
    
    /// Get complete tour context for a show (position + venue run)
    func getTourContext(for showDate: String) async throws -> (tourPosition: TourShowPosition?, venueRun: VenueRun?) {
        guard let tourName = try await getTourNameForShow(date: showDate) else {
            return (nil, nil)
        }
        
        let year = String(showDate.prefix(4))
        let tourShows = try await fetchTourShows(year: year, tourName: tourName)
        
        let tourPosition = try await calculateTourPosition(for: showDate, tourName: tourName)
        let venueRun = getVenueRun(for: showDate, in: tourShows)
        
        return (tourPosition, venueRun)
    }
    
    // MARK: - Tour Name Normalization
    
    /// Normalize tour names for consistency
    /// Handles variations in tour name formatting between API responses
    static func normalizeTourName(_ tourName: String) -> String {
        // Handle common tour name variations
        if tourName == "Summer Tour 2025" {
            return "2025 Summer Tour"
        }
        
        // Add more mappings as needed
        return tourName
    }
}