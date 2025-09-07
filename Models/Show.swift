//
//  ShowModels.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/27/25.
//

import Foundation

// individual show from the Phish.net API year-level query
struct Show: Codable {
    let showyear: String      // full year string, e.g. "2025"
    let showdate: String      // full date string, e.g. "2025-01-28"
    let artist_name: String   // artist name, e.g. "Phish"
    let tour_name: String?    // tour name, e.g. "2025 Early Summer Tour" (optional for shows not part of tours)
    let venue: String?        // venue name, e.g. "Madison Square Garden" (optional in case API doesn't include it)
    let city: String?         // city name, e.g. "New York" (optional in case API doesn't include it)
    let state: String?        // state abbreviation, e.g. "NY" (optional for international shows)
}

// top-level response wrapper for array of shows
struct ShowResponse: Codable {
    let data: [Show]          // list of Show structs
}
