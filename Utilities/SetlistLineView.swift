//
//  SetlistLineView.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/23/25.
//

import SwiftUI

/// Reusable component for displaying setlist lines with consistent styling
/// Handles set headers (blue) and song lines (black) automatically
struct SetlistLineView: View {
    let line: String
    let fontSize: Font
    let songColor: Color?
    
    init(_ line: String, fontSize: Font = .body, songColor: Color? = nil) {
        self.line = line
        self.fontSize = fontSize
        self.songColor = songColor
    }
    
    /// Determines if the line is a set header (Set 1:, Set 2:, Encore:)
    private var isSetHeader: Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Match exact patterns: "Set X:" where X is a number, or "Encore:"
        if trimmed.hasPrefix("Encore:") {
            return true
        }
        
        // Use regex to match "Set [number]:" pattern exactly
        let setPattern = "^Set\\s+\\d+:$"
        let regex = try? NSRegularExpression(pattern: setPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return regex?.firstMatch(in: trimmed, options: [], range: range) != nil
    }
    
    var body: some View {
        Text(line)
            .font(isSetHeader ? .headline : fontSize)
            .fontWeight(isSetHeader ? .semibold : .regular)
            .foregroundColor(isSetHeader ? .blue : (songColor ?? .primary))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 4) {
        SetlistLineView("Set 1: The Moma Dance > Rift, Sigma Oasis")
        SetlistLineView("Set 2: Wolfman's Brother, Stash, Blaze On")
        SetlistLineView("Encore: I Am the Walrus")
    }
    .padding()
}