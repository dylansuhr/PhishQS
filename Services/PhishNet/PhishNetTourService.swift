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
    /// Uses Phish.net show data to determine multi-night venue runs
    /// Matches the server-side venue run calculation logic for consistency
    func calculateVenueRuns(for shows: [Show]) -> [String: VenueRun] {
        print("🏟️  PhishNetTourService.calculateVenueRuns for \(shows.count) shows")
        var venueRuns: [String: VenueRun] = [:]
        
        // Sort shows by date to ensure proper chronological order
        let sortedShows = shows.sorted { $0.showdate < $1.showdate }
        
        // Log show venues for debugging
        for show in sortedShows.prefix(3) {
            print("   📅 \(show.showdate): \(show.venue ?? "no venue"), \(show.city ?? "no city"), \(show.state ?? "no state")")
        }
        if sortedShows.count > 3 {
            print("   ... and \(sortedShows.count - 3) more shows")
        }
        
        // Group consecutive shows by venue
        var venueGroups: [[Show]] = []
        var currentGroup: [Show] = []
        var currentVenue: String = ""
        
        for show in sortedShows {
            let showVenue = show.venue ?? "Unknown Venue"
            
            if showVenue == currentVenue && !currentGroup.isEmpty {
                // Same venue, add to current group
                currentGroup.append(show)
            } else {
                // New venue or first show - finish previous group if it exists
                if !currentGroup.isEmpty {
                    venueGroups.append(currentGroup)
                }
                // Start new group
                currentGroup = [show]
                currentVenue = showVenue
            }
        }
        
        // Don't forget the last group
        if !currentGroup.isEmpty {
            venueGroups.append(currentGroup)
        }
        
        print("   🎪 Found \(venueGroups.count) venue groups")
        
        // Generate venue runs for multi-night runs only
        for group in venueGroups {
            if group.count > 1 {
                print("   🏟️  Multi-night run: \(group[0].venue) (\(group.count) nights)")
                
                // Multi-night run - create venue run objects
                let showDates = group.map { $0.showdate }
                
                for (index, show) in group.enumerated() {
                    let venueRun = VenueRun(
                        venue: show.venue ?? "Unknown Venue",
                        city: show.city ?? "Unknown City",
                        state: show.state,
                        nightNumber: index + 1,
                        totalNights: group.count,
                        showDates: showDates
                    )
                    venueRuns[show.showdate] = venueRun
                    print("     📅 \(show.showdate): N\(index + 1)/\(group.count)")
                }
            } else {
                print("   🏟️  Single night: \(group[0].venue ?? "Unknown Venue") (\(group[0].showdate))")
            }
        }
        
        print("   ✅ Generated \(venueRuns.count) venue run objects")
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
        print("🎪 PhishNetTourService.getTourContext for \(showDate)")
        
        guard let tourName = try await getTourNameForShow(date: showDate) else {
            print("   ⚠️  No tour name found for \(showDate)")
            return (nil, nil)
        }
        
        print("   🎪 Found tour: \(tourName)")
        
        let year = String(showDate.prefix(4))
        let tourShows = try await fetchTourShows(year: year, tourName: tourName)
        print("   📋 Found \(tourShows.count) tour shows")
        
        let tourPosition = try await calculateTourPosition(for: showDate, tourName: tourName)
        print("   🎯 Tour position: \(tourPosition?.showNumber ?? 0)/\(tourPosition?.totalShows ?? 0)")
        
        let venueRun = getVenueRun(for: showDate, in: tourShows)
        if let venueRun = venueRun {
            print("   🏟️  Venue run: N\(venueRun.nightNumber)/\(venueRun.totalNights) at \(venueRun.venue)")
        } else {
            print("   🏟️  No venue run (single night show)")
        }
        
        return (tourPosition, venueRun)
    }
    
    // MARK: - Tour Name Normalization
    
    /// Normalize tour names for consistency
    /// Handles variations in tour name formatting between API responses
    static func normalizeTourName(_ tourName: String) -> String {
        // Handle common tour name variations
        if tourName == "Early Summer Tour 2025" {
            return "2025 Early Summer Tour"
        }
        if tourName == "Late Summer Tour 2025" {
            return "2025 Late Summer Tour"
        }
        
        // Add more mappings as needed
        return tourName
    }
}