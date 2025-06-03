//
//  Untitled.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/2/25.
//

import Foundation

struct SetlistResponse: Codable {
    let data: [SetlistData]
}

struct SetlistData: Codable {
    let setlistData: String

    enum CodingKeys: String, CodingKey {
        case setlistData = "setlistdata"
    }
}


