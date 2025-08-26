import SwiftUI

// View for displaying the latest Phish setlist with simple navigation
struct LatestSetlistView: View {
    @ObservedObject var viewModel: LatestSetlistViewModel
    
    
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
                            
                            // Show tour position info with blue highlighting for show numbers
                            if let tourPosition = viewModel.tourPositionInfo {
                                createStyledTourText(tourPosition.tourName, showNumbers: "\(tourPosition.showNumber)/\(tourPosition.totalShows)")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Full setlist display
                if !viewModel.setlistItems.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        createDirectSetlistView()
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
    
    /// Create setlist view directly from SetlistItem array
    @ViewBuilder
    private func createDirectSetlistView() -> some View {
        let groupedBySet = Dictionary(grouping: viewModel.setlistItems) { $0.set }
        let setOrder = ["1", "2", "3", "E", "ENCORE"]
        let setsWithPositions = calculateSetPositions(groupedBySet: groupedBySet, setOrder: setOrder)
        
        ForEach(setsWithPositions, id: \.setKey) { setData in
            // Set header
            Text(formatSetName(setData.setKey))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            // Songs in this set
            createSetSongsView(setData.items, startPosition: setData.startPosition)
            
            // Add spacing between sets (but not after the last set)
            let isLastSet = setData.setKey.uppercased() == "E" || setData.setKey.uppercased() == "ENCORE"
            if !isLastSet {
                Text("")
                    .font(.caption2)
            }
        }
    }
    
    /// Create a view for all songs in a set with proper coloring and transitions
    @ViewBuilder
    private func createSetSongsView(_ setItems: [SetlistItem], startPosition: Int) -> some View {
        let attributedText = createAttributedSetText(setItems, startPosition: startPosition)
        Text(attributedText)
            .font(.caption)
    }
    
    /// Create AttributedString for a set's songs with proper colors and transitions
    private func createAttributedSetText(_ setItems: [SetlistItem], startPosition: Int) -> AttributedString {
        var result = AttributedString()
        
        for (index, item) in setItems.enumerated() {
            let songPosition = startPosition + index
            
            // Add colored song name
            var songText = AttributedString(item.song)
            let songColor = viewModel.colorForSong(at: songPosition, expectedName: item.song) ?? .primary
            songText.foregroundColor = songColor
            result += songText
            
            // Add transition mark in black if it exists
            if let transMark = item.transMark, !transMark.isEmpty {
                var transitionText = AttributedString(transMark)
                transitionText.foregroundColor = .primary
                result += transitionText
            }
            
            // Add space between songs (except last)
            if index < setItems.count - 1 {
                result += AttributedString(" ")
            }
        }
        
        return result
    }
    
    /// Calculate starting positions for each set
    private func calculateSetPositions(groupedBySet: [String: [SetlistItem]], setOrder: [String]) -> [(setKey: String, items: [SetlistItem], startPosition: Int)] {
        var result: [(setKey: String, items: [SetlistItem], startPosition: Int)] = []
        var currentPosition = 0
        
        // First, add sets that match our expected order
        for setKey in setOrder {
            if let setItems = groupedBySet[setKey] ?? groupedBySet[setKey.uppercased()] {
                result.append((setKey: setKey, items: setItems, startPosition: currentPosition))
                currentPosition += setItems.count
            }
        }
        
        // Then add any remaining sets not in our order (for edge cases)
        let processedKeys = Set(result.map { $0.setKey.uppercased() })
        for (setKey, setItems) in groupedBySet {
            if !processedKeys.contains(setKey.uppercased()) {
                result.append((setKey: setKey, items: setItems, startPosition: currentPosition))
                currentPosition += setItems.count
            }
        }
        
        return result
    }
    
    /// Create styled tour text with blue highlighted show numbers
    @ViewBuilder
    private func createStyledTourText(_ tourName: String, showNumbers: String) -> some View {
        HStack(spacing: 2) {
            Text(tourName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(showNumbers)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(3)
        }
    }
    
    /// Format set names properly (1→"Set 1", 2→"Set 2", E→"Encore", etc.)
    private func formatSetName(_ setIdentifier: String) -> String {
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
    
}

#Preview {
    LatestSetlistView(viewModel: LatestSetlistViewModel())
} 
