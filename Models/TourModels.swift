//
//  TourModels.swift
//  PhishQS
//
//  Split from SharedModels.swift for better organization
//  Contains tour-related data models
//

import Foundation

// MARK: - Tour Models

struct Tour: Codable, Identifiable {
    let id: String
    let name: String
    let year: String
    let startDate: String
    let endDate: String
    let showCount: Int
}

struct TourShowPosition: Codable {
    let tourName: String
    let showNumber: Int
    let totalShows: Int
    let tourYear: String

    var displayText: String {
        if totalShows > 1 {
            return "\(tourName) (\(showNumber)/\(totalShows))"
        }
        return tourName
    }

    var shortDisplayText: String {
        if totalShows > 1 {
            return "\(tourName) \(showNumber)/\(totalShows)"
        }
        return ""
    }
}

struct VenueRun: Codable {
    let venue: String
    let city: String
    let state: String?
    let nightNumber: Int
    let totalNights: Int
    let showDates: [String]

    var runDisplayText: String {
        if totalNights > 1 {
            return "N\(nightNumber)/\(totalNights)"
        }
        return ""
    }
}