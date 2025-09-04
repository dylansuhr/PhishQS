//
//  PhishNetTourService.swift
//  PhishQS
//
//  Created by Claude on 9/4/25.
//

import Foundation

/// Service for fetching tour-related data from Phish.net API
/// Replaces Phish.in as the authoritative source for tour organization, show counts, and venue runs
class PhishNetTourService {
    
    private let phishNetClient: PhishAPIClient
    
    init(phishNetClient: PhishAPIClient = PhishAPIClient.shared) {
        self.phishNetClient = phishNetClient
    }
    
    // MARK: - Tour Show Methods
    
    /// Fetch all shows for a specific tour by year and tour name
    /// Replaces Phish.in getCachedTourShows functionality
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
    /// Replaces Phish.in fetchTourPosition functionality
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
    /// Replaces Phish.in tour_name field usage
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
    /// Replaces Phish.in venue run detection
    func calculateVenueRuns(for shows: [Show]) -> [String: VenueRun] {
        var venueRuns: [String: VenueRun] = [:]
        
        // Group shows by venue
        let venueGroups = Dictionary(grouping: shows) { show in
            "\(show.venue ?? "Unknown")-\(show.city ?? "Unknown")-\(show.state ?? "Unknown")"
        }
        
        for (venueKey, venueShows) in venueGroups {
            let sortedShows = venueShows.sorted { $0.showdate < $1.showdate }
            
            // Only create venue runs for multi-night stands
            if sortedShows.count > 1 {
                let showDates = sortedShows.map { $0.showdate }
                
                // Use first show for venue info
                guard let firstShow = sortedShows.first else { continue }
                
                for (index, show) in sortedShows.enumerated() {
                    let venueRun = VenueRun(
                        venue: firstShow.venue ?? "Unknown Venue",
                        city: firstShow.city ?? "Unknown City", 
                        state: firstShow.state,
                        nightNumber: index + 1,
                        totalNights: sortedShows.count,
                        showDates: showDates
                    )
                    
                    venueRuns[show.showdate] = venueRun
                }
            }
        }
        
        return venueRuns
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
    
    /// Normalize tour names between different API sources
    /// Maps Phish.in format to Phish.net format
    static func normalizeTourName(_ tourName: String) -> String {
        // Handle common tour name variations
        if tourName == "Summer Tour 2025" {
            return "2025 Summer Tour"
        }
        
        // Add more mappings as needed
        return tourName
    }
}