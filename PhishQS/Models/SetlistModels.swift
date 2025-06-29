//
//  Untitled.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/2/25.
//

import Foundation

struct SetlistItem: Codable {
    let set: String
    let song: String
    let transMark: String?

    enum CodingKeys: String, CodingKey {
        case set, song
        case transMark = "trans_mark"
    }
}
