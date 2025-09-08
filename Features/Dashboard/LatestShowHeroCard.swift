//
//  LatestShowHeroCard.swift
//  PhishQS
//
//  Created by Claude on 8/26/25.
//

import SwiftUI

/// Hero card displaying the latest show in a clean, dashboard-appropriate format
struct LatestShowHeroCard: View {
    @ObservedObject var viewModel: LatestSetlistViewModel
    
    var body: some View {
        HeroCard {
            if let show = viewModel.latestShow, !viewModel.setlistItems.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with date and venue info
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(show.showdate)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(DateUtilities.formatDateWithDayOfWeek(show.showdate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Venue info with reorganized badges
                        if let firstItem = viewModel.setlistItems.first {
                            VStack(alignment: .leading, spacing: 6) {
                                // Venue name with venue run badge
                                HStack {
                                    Text(firstItem.venue)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if let venueRun = viewModel.venueRunInfo, !venueRun.runDisplayText.isEmpty {
                                        BadgeView(text: venueRun.runDisplayText, style: .blue)
                                    }
                                }
                                
                                // City, State
                                HStack {
                                    Group {
                                        if let state = firstItem.state {
                                            Text("\(firstItem.city), \(state)")
                                        } else {
                                            Text(firstItem.city)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                                
                                // Tour name with tour position badge
                                if let tourPosition = viewModel.tourPositionInfo {
                                    HStack {
                                        Text(tourPosition.tourName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        BadgeView(text: "\(tourPosition.showNumber)/\(tourPosition.totalShows)", style: .blue)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Compact setlist display
                    CompactSetlistView(setlistItems: viewModel.setlistItems, viewModel: viewModel)
                }
            } else if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading latest show...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unable to load show")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                Text("No recent shows available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
        .onAppear {
            if viewModel.latestShow == nil && !viewModel.isLoading {
                viewModel.fetchLatestSetlist()
            }
        }
    }
}

/// Compact setlist view for dashboard display
struct CompactSetlistView: View {
    let setlistItems: [SetlistItem]
    let viewModel: LatestSetlistViewModel
    
    var body: some View {
        let groupedBySet = Dictionary(grouping: setlistItems) { $0.set }
        let setOrder = ["1", "2", "3", "E", "ENCORE"]
        let setsWithPositions = calculateSetPositions(groupedBySet: groupedBySet, setOrder: setOrder)
        
        VStack(alignment: .leading, spacing: 8) {
            ForEach(setsWithPositions, id: \.setKey) { setData in
                VStack(alignment: .leading, spacing: 4) {
                    // Set header
                    Text(formatSetName(setData.setKey))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    // Compact songs (first 3-4 per line)
                    CompactSetSongsView(setData.items, startPosition: setData.startPosition)
                }
            }
        }
    }
    
    /// Create compact view of songs with proper colors and transitions
    @ViewBuilder
    private func CompactSetSongsView(_ setItems: [SetlistItem], startPosition: Int) -> some View {
        let attributedText = createAttributedSetText(setItems, startPosition: startPosition)
        Text(attributedText)
            .font(.caption)
    }
    
    /// Create AttributedString with colors (simplified from main setlist view)
    private func createAttributedSetText(_ setItems: [SetlistItem], startPosition: Int) -> AttributedString {
        var result = AttributedString()
        
        for (index, item) in setItems.enumerated() {
            let songPosition = startPosition + index
            
            // Add colored song name
            var songText = AttributedString(item.song)
            let songColor = viewModel.colorForSong(at: songPosition, expectedName: item.song) ?? .primary
            songText.foregroundColor = songColor
            result += songText
            
            // Add transition mark
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
        
        for setKey in setOrder {
            if let setItems = groupedBySet[setKey] ?? groupedBySet[setKey.uppercased()] {
                result.append((setKey: setKey, items: setItems, startPosition: currentPosition))
                currentPosition += setItems.count
            }
        }
        
        // Add any remaining sets not in our order
        let processedKeys = Set(result.map { $0.setKey.uppercased() })
        for (setKey, setItems) in groupedBySet {
            if !processedKeys.contains(setKey.uppercased()) {
                result.append((setKey: setKey, items: setItems, startPosition: currentPosition))
                currentPosition += setItems.count
            }
        }
        
        return result
    }
    
    /// Format set names
    private func formatSetName(_ setIdentifier: String) -> String {
        switch setIdentifier.uppercased() {
        case "E", "ENCORE": return "Encore:"
        case "1": return "Set 1:"
        case "2": return "Set 2:"
        case "3": return "Set 3:"
        default: return "Set \\(setIdentifier):"
        }
    }
}

// BadgeView now available from SharedUIComponents.swift

#Preview {
    LatestShowHeroCard(viewModel: LatestSetlistViewModel())
        .padding()
        .background(Color(.systemGray6))
}