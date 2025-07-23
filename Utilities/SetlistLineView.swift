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
    
    init(_ line: String, fontSize: Font = .body) {
        self.line = line
        self.fontSize = fontSize
    }
    
    /// Determines if the line is a set header (Set 1:, Set 2:, Encore:)
    private var isSetHeader: Bool {
        line.hasPrefix("Set ") || line.hasPrefix("Encore:")
    }
    
    var body: some View {
        Text(line)
            .font(isSetHeader ? .headline : fontSize)
            .fontWeight(isSetHeader ? .semibold : .regular)
            .foregroundColor(isSetHeader ? .blue : .primary)
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