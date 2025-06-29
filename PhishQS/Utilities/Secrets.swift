//
//  Secrets.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/27/25.
//


import Foundation

class Secrets {
    static func value(for key: String) -> String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let value = plist[key] as? String
        else {
            fatalError("Missing or invalid key: \(key) in Secrets.plist")
        }
        return value
    }
}
