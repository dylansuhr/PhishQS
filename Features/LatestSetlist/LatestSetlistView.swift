import SwiftUI

// View for displaying the latest Phish setlist with simple navigation
struct LatestSetlistView: View {
    @StateObject private var viewModel = LatestSetlistViewModel()
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Navigation buttons at top
            HStack {
                Button(action: {
                    viewModel.navigateToPreviousShow()
                }) {
                    Text("Previous")
                        .foregroundColor(viewModel.canNavigatePrevious ? .blue : .gray)
                }
                .disabled(!viewModel.canNavigatePrevious)
                
                Spacer()
                
                Button(action: {
                    viewModel.navigateToNextShow()
                }) {
                    Text("Next")
                        .foregroundColor(viewModel.canNavigateNext ? .blue : .gray)
                }
                .disabled(!viewModel.canNavigateNext)
            }
            .padding(.horizontal)
            
            // Show info
            if let show = viewModel.latestShow {
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(show.showdate)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(DateUtilities.formatDateWithDayOfWeek(show.showdate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Show venue info if available from setlist items
                    if let firstItem = viewModel.setlistItems.first {
                        VStack(alignment: .leading, spacing: 2) {
                            VStack(alignment: .leading, spacing: 1) {
                                HStack {
                                    Text(firstItem.venue)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    
                                    // Show venue run info if available
                                    if let venueRun = viewModel.venueRunInfo {
                                        Spacer()
                                        Text(venueRun.runDisplayText)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(3)
                                    }
                                }
                                
                                let stateText = firstItem.state != nil ? ", \(firstItem.state!)" : ""
                                Text("\(firstItem.city)\(stateText)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Show tour position info if available
                            if let tourPosition = viewModel.tourPositionInfo {
                                Text(tourPosition.shortDisplayText)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Full setlist display
                if !viewModel.setlistItems.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(StringFormatters.formatSetlist(viewModel.setlistItems).enumerated()), id: \.offset) { index, line in
                            if !line.isEmpty {
                                coloredSetlistLine(line)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            } else {
                Text("No recent shows available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.fetchLatestSetlist()
        }
    }
    
    /// Create a colored setlist line with individual song colors
    @ViewBuilder
    private func coloredSetlistLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Handle set headers
        if (trimmed.hasPrefix("Set ") && trimmed.hasSuffix(":")) || trimmed.hasPrefix("Encore:") {
            Text(line)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        } else {
            // Parse and color individual songs within the line to match detailed view
            createColoredSetlistLine(line)
        }
    }
    
    /// Create a colored setlist line with individual song colors matching the detailed view
    @ViewBuilder
    private func createColoredSetlistLine(_ line: String) -> some View {
        let components = parseLineIntoColoredComponents(line)
        
        // Use AttributedString for proper inline coloring
        let attributedText = components.reduce(AttributedString()) { result, component in
            var attributed = AttributedString(component.text)
            attributed.foregroundColor = component.color
            return result + attributed
        }
        
        Text(attributedText)
            .font(.caption)
    }
    
    /// Parse a formatted setlist line into individual colored components
    /// Uses position-based color matching for accurate duplicate song handling
    private func parseLineIntoColoredComponents(_ line: String) -> [(text: String, color: Color)] {
        var components: [(text: String, color: Color)] = []
        var remainingLine = line
        var songPosition = getCurrentLineStartPosition(line)
        
        // Split by transition marks while preserving them
        let separators = [" > ", " -> ", ", "]
        
        while !remainingLine.isEmpty {
            var earliestMatch: (separator: String, range: Range<String.Index>)? = nil
            
            // Find the earliest occurring separator
            for separator in separators {
                if let range = remainingLine.range(of: separator) {
                    if earliestMatch == nil || range.lowerBound < earliestMatch!.range.lowerBound {
                        earliestMatch = (separator, range)
                    }
                }
            }
            
            if let match = earliestMatch {
                // Add song before separator with position-based color
                let songText = String(remainingLine[..<match.range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if !songText.isEmpty {
                    let songColor = viewModel.colorForSong(at: songPosition, expectedName: songText) ?? .primary
                    components.append((text: songText, color: songColor))
                    songPosition += 1  // Increment position for next song
                }
                
                // Add separator in black
                components.append((text: match.separator, color: .primary))
                
                // Continue with rest of line
                remainingLine = String(remainingLine[match.range.upperBound...])
            } else {
                // No more separators, add remaining text as song
                let songText = remainingLine.trimmingCharacters(in: .whitespaces)
                if !songText.isEmpty {
                    let songColor = viewModel.colorForSong(at: songPosition, expectedName: songText) ?? .primary
                    components.append((text: songText, color: songColor))
                }
                break
            }
        }
        
        return components
    }
    
    /// Calculate the starting position for songs in the current line
    /// This tracks position across the formatted setlist to maintain accuracy
    private func getCurrentLineStartPosition(_ currentLine: String) -> Int {
        // Count total songs in all previous lines
        let formattedLines = StringFormatters.formatSetlist(viewModel.setlistItems)
        var totalSongs = 0
        
        for line in formattedLines {
            if line == currentLine {
                break  // Found current line, return position
            }
            
            // Skip set headers
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if (trimmed.hasPrefix("Set ") && trimmed.hasSuffix(":")) || trimmed.hasPrefix("Encore:") {
                continue
            }
            
            // Count songs in this line
            let separators = [" > ", " -> ", ", "]
            var lineText = line
            var songsInLine = 0
            
            while !lineText.isEmpty {
                var earliestMatch: Range<String.Index>? = nil
                
                for separator in separators {
                    if let range = lineText.range(of: separator) {
                        if earliestMatch == nil || range.lowerBound < earliestMatch!.lowerBound {
                            earliestMatch = range
                        }
                    }
                }
                
                if let match = earliestMatch {
                    let songText = String(lineText[..<match.lowerBound]).trimmingCharacters(in: .whitespaces)
                    if !songText.isEmpty {
                        songsInLine += 1
                    }
                    lineText = String(lineText[match.upperBound...])
                } else {
                    let songText = lineText.trimmingCharacters(in: .whitespaces)
                    if !songText.isEmpty {
                        songsInLine += 1
                    }
                    break
                }
            }
            
            totalSongs += songsInLine
        }
        
        return totalSongs
    }
    
}

#Preview {
    LatestSetlistView()
} 
