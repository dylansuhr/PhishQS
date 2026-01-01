//
//  SetlistItem.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/2/25.
//

import Foundation

// one row of setlist data from the showdate-level API call
struct SetlistItem: Codable, Equatable {
    let set: String           // set number or label (e.g. "1", "Encore")
    let song: String          // song name
    let songId: Int?          // optional songid for reliable cross-API matching
    let transMark: String?    // transition marker (e.g. "->", ",")
    let venue: String         // venue name
    let city: String          // city name
    let state: String?        // state/province name (e.g. "NY", "PA")
    let showdate: String      // full show date, e.g. "2025-01-28"
    let permalink: String?    // URL slug for phish.net show page (e.g. "phish-december-29-2025-madison-square-garden-new-york-ny-usa")
    let setlistnotes: String? // HTML show notes (same for all items in a show)

    // match Swift property names to JSON keys
    enum CodingKeys: String, CodingKey {
        case set, song
        case songId = "songid"   // map to Phish.net API songid field
        case transMark = "trans_mark"
        case venue, city, state, showdate, permalink, setlistnotes
    }

    /// Full URL to the show page on phish.net
    var phishNetURL: URL? {
        guard let permalink = permalink else { return nil }
        return URL(string: "https://phish.net/setlists/\(permalink).html")
    }
}

// top-level response wrapper for a list of setlist items
struct SetlistResponse: Codable {
    let data: [SetlistItem]
}
