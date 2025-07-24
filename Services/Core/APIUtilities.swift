//
//  APIUtilities.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/23/25.
//

import Foundation

/// Shared utilities for API data processing
struct APIUtilities {
    
    /// Check if a show is a Phish show (filters out other artists)
    static func isPhishShow(_ show: Show) -> Bool {
        return show.artist_name.lowercased() == "phish"
    }
    
    /// Filter shows to only include Phish shows
    static func filterPhishShows(_ shows: [Show]) -> [Show] {
        return shows.filter(isPhishShow)
    }
    
    /// Extract unique show dates from a list of shows
    static func extractUniqueDates(from shows: [Show]) -> Set<String> {
        return Set(filterPhishShows(shows).map { $0.showdate })
    }
}

