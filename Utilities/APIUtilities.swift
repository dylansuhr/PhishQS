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

/// Base ViewModel functionality for consistent error handling and loading states
@MainActor
class BaseViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    /// Handle API errors consistently
    func handleError(_ error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
    }
    
    /// Clear error state
    func clearError() {
        errorMessage = nil
    }
    
    /// Set loading state
    func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            clearError()
        }
    }
}