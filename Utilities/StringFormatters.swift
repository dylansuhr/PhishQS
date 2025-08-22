//
//  StringFormatters.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/23/25.
//

import Foundation

/// Utilities for formatting display strings throughout the app
struct StringFormatters {
    
    /// Format setlist items into display lines with sets and inline songs
    static func formatSetlist(_ setlistItems: [SetlistItem]) -> [String] {
        var formatted: [String] = []
        var currentSet = ""
        var currentSetSongs: [String] = []
        
        for item in setlistItems {
            if item.set != currentSet {
                // Finish previous set if it exists
                if !currentSet.isEmpty && !currentSetSongs.isEmpty {
                    let setHeader = formatSetName(currentSet)
                    let songsLine = currentSetSongs.joined(separator: " ")
                    formatted.append(setHeader)  // Header on its own line
                    formatted.append(songsLine)  // Songs on separate line
                    
                    // Add extra spacing before Set 2 and Encore (but not Set 1)
                    if item.set == "2" || item.set.uppercased() == "E" || item.set.uppercased() == "ENCORE" {
                        formatted.append("")  // Regular spacing
                        formatted.append("")  // Extra spacing
                    } else {
                        formatted.append("")  // Regular spacing only
                    }
                }
                
                currentSet = item.set
                currentSetSongs = []
            }
            
            var songWithTransition = item.song
            if let transMark = item.transMark, !transMark.isEmpty {
                // API already includes proper spacing in transition markers, just append directly
                songWithTransition += transMark
            }
            currentSetSongs.append(songWithTransition)
        }
        
        // Add the final set
        if !currentSet.isEmpty && !currentSetSongs.isEmpty {
            let setHeader = formatSetName(currentSet)
            let songsLine = currentSetSongs.joined(separator: " ")
            formatted.append(setHeader)  // Header on its own line
            formatted.append(songsLine)  // Songs on separate line
            formatted.append("")  // Add consistent spacing after final set too
        }
        
        return formatted
    }
    
    /// Format set names properly (1→"Set 1", 2→"Set 2", E→"Encore", etc.)
    private static func formatSetName(_ setIdentifier: String) -> String {
        switch setIdentifier.uppercased() {
        case "E", "ENCORE":
            return "Encore:"
        case "1":
            return "Set 1:"
        case "2":
            return "Set 2:"
        case "3":
            return "Set 3:"
        default:
            return "Set \(setIdentifier):"
        }
    }
    
    /// Format a simple setlist for compact display (no set headers)
    static func formatSimpleSetlist(_ setlistItems: [SetlistItem]) -> [String] {
        return setlistItems.map { item in
            var line = item.song
            if let transMark = item.transMark, !transMark.isEmpty {
                line += " \(transMark)"
            }
            return line
        }
    }
    
    /// Format navigation title for month/year combination
    static func formatMonthYearTitle(month: String, year: String) -> String {
        return "\(year)-\(month)"
    }
}