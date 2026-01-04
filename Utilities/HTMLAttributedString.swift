//
//  HTMLAttributedString.swift
//  PhishQS
//
//  Utility for converting HTML strings to AttributedString for SwiftUI display
//

import Foundation
import SwiftUI

extension String {
    /// Convert HTML string to plain text by stripping tags
    /// This is the safe, fast method that won't cause SwiftUI update cycles
    func htmlToPlainText() -> String {
        guard !self.isEmpty else { return "" }

        // Clean up common HTML entities and whitespace
        var cleaned = self
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")

        // Strip HTML tags
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Collapse multiple spaces
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// A view that safely displays setlist notes
struct SetlistNotesView: View {
    let notes: String
    let style: NotesStyle

    enum NotesStyle {
        case compact   // For dashboard
        case detailed  // For sheet
    }

    private var displayText: String {
        notes.htmlToPlainText()
    }

    var body: some View {
        switch style {
        case .compact:
            // Hero card: songs are .footnote, so notes are .caption
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                    .padding(.vertical, 4)

                Text("Notes")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .detailed:
            // SetlistView: songs are .body, so notes are .subheadline
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(displayText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

/// A view that displays the footnote legend at the bottom of setlists
struct FootnoteLegendView: View {
    let legend: [FootnoteLegendItem]
    let style: LegendStyle

    enum LegendStyle {
        case compact   // For LatestSetlistView (hero card)
        case detailed  // For SetlistView (sheet)
    }

    var body: some View {
        switch style {
        case .compact:
            VStack(alignment: .leading, spacing: 2) {
                ForEach(legend, id: \.index) { item in
                    Text("[\(item.index)] \(item.text)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

        case .detailed:
            VStack(alignment: .leading, spacing: 4) {
                ForEach(legend, id: \.index) { item in
                    Text("[\(item.index)] \(item.text)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
