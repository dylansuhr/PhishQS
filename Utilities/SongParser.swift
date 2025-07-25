//
//  SongParser.swift
//  PhishQS
//
//  Created by Claude on 7/25/25.
//

import Foundation

/// Utility for parsing individual songs from formatted setlist lines
struct SongParser {
    
    /// Parse a combined song line into individual songs
    /// Input: "The Moma Dance > Rift, Sigma Oasis"
    /// Output: ["The Moma Dance", "Rift", "Sigma Oasis"]
    static func parseSongs(from line: String) -> [String] {
        // First split by commas to separate distinct song groups
        let songGroups = line.components(separatedBy: ",")
        
        var allSongs: [String] = []
        
        for group in songGroups {
            // Split each group by transition markers (> or ->)
            let transitionMarkers = [" > ", " -> ", ">", "->"]
            var groupSongs = [group.trimmingCharacters(in: .whitespaces)]
            
            for marker in transitionMarkers {
                var newSongs: [String] = []
                for song in groupSongs {
                    let parts = song.components(separatedBy: marker)
                    newSongs.append(contentsOf: parts.map { $0.trimmingCharacters(in: .whitespaces) })
                }
                groupSongs = newSongs
            }
            
            // Add cleaned songs to the result
            allSongs.append(contentsOf: groupSongs.filter { !$0.isEmpty })
        }
        
        return allSongs
    }
    
    /// Clean a song name for duration matching
    /// Removes extra whitespace and normalizes format
    static func cleanSongName(_ songName: String) -> String {
        return songName.trimmingCharacters(in: .whitespaces)
    }
    
    /// Check if a line is a set header (Set 1:, Encore:, etc.)
    static func isSetHeader(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("Set ") || trimmed.hasPrefix("Encore:")
    }
}