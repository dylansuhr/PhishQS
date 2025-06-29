//
//  ShowModels.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/27/25.
//



import Foundation

struct ShowResponse: Codable {
    let data: [Show]
}

struct Show: Codable {
    let showyear: String
    let showdate: String
}
