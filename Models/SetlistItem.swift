//
//  SetlistItem.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/2/25.
//

import Foundation

// one row of setlist data from the showdate-level API call
struct SetlistItem: Codable {
    let set: String           // set number or label (e.g. "1", "Encore")
    let song: String          // song name
    let songId: Int?          // optional songid for reliable cross-API matching
    let transMark: String?    // transition marker (e.g. "->", ",")
    let venue: String         // venue name
    let city: String          // city name
    let state: String?        // state/province name (e.g. "NY", "PA")
    let showdate: String      // full show date, e.g. "2025-01-28"

    // match Swift property names to JSON keys
    enum CodingKeys: String, CodingKey {
        case set, song
        case songId = "songid"   // map to Phish.net API songid field
        case transMark = "trans_mark"
        case venue, city, state, showdate
    }
}

// top-level response wrapper for a list of setlist items
struct SetlistResponse: Codable {
    let data: [SetlistItem]
}
