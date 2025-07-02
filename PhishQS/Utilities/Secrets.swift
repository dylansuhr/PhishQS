//
//  Secrets.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/27/25.
//

import Foundation

// helper class to safely read secrets from Secrets.plist at runtime
class Secrets {

    // lookup a value by key (e.g. "PhishNetAPIKey") from the plist
    static func value(for key: String) -> String {

        // try to find the Secrets.plist file in the main app bundle
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),

            // try to load the file data
            let data = try? Data(contentsOf: url),

            // attempt to decode the plist into a dictionary
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],

            // grab the string value for the given key
            let value = plist[key] as? String
        else {
            // if anything goes wrong, crash with a helpful message
            fatalError("Missing or invalid key: \(key) in Secrets.plist")
        }

        return value
    }
}
