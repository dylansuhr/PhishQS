//
//  TourMetricCards.swift
//  PhishQS
//
//  Re-export file for tour statistics cards
//  Components have been split into focused files for better organization
//

import SwiftUI

// Re-export all the individual card components for backward compatibility
// This ensures existing imports continue to work while providing better organization

// Individual cards
typealias LongestSongsCard = LongestSongsCard
typealias RarestSongsCard = RarestSongsCard
typealias MostPlayedSongsCard = MostPlayedSongsCard
typealias MostCommonSongsNotPlayedCard = MostCommonSongsNotPlayedCard
typealias TourOverviewCard = TourOverviewCard

// Row components
typealias MostCommonSongNotPlayedRow = MostCommonSongNotPlayedRow

// Main container
typealias TourStatisticsCards = TourStatisticsCards

// Note: The row components LongestSongRowModular, RarestSongRowModular, and MostPlayedSongRowModular
// are defined in SharedUIComponents.swift and are already available throughout the app.