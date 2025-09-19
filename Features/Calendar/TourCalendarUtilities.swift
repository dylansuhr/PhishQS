//
//  TourCalendarUtilities.swift
//  PhishQS
//
//  Split from TourCalendarView.swift for better organization
//  Contains utility functions and components for calendar
//

import SwiftUI

// MARK: - Venue Color Generation

/// Generate a consistent color for a venue based on its name
func venueColor(for venue: String) -> Color {
    return generateConsistentColor(for: venue)
}

// MarqueeText component moved to MarqueeText.swift