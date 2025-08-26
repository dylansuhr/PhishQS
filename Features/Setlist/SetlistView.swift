import SwiftUI

// View that fetches and displays a full setlist for a specific year/month/day
struct SetlistView: View {
    let year: String    // passed in from DayListView
    let month: String   // passed in from DayListView
    let day: String     // passed in from DayListView

    // view model loads setlist data from API
    @StateObject private var viewModel = SetlistViewModel()

    var body: some View {
        // build the full YYYY-MM-DD date string for API call
        let date = DateUtilities.padDateComponents(year: year, month: month, day: day)

        ScrollView {
            Color.clear
            if viewModel.isLoading {
                ProgressView("Loading setlist...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Error loading setlist")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        viewModel.fetchSetlist(for: date)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.setlist.isEmpty {
                Text("No setlist available for this date")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // Show venue info if available
                    if let firstItem = viewModel.setlistItems.first {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(firstItem.venue)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                // Show venue run info if available
                                if let venueRun = viewModel.venueRunInfo {
                                    Spacer()
                                    Text(venueRun.runDisplayText)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            let stateText = firstItem.state != nil ? ", \(firstItem.state!)" : ""
                            Text("\(firstItem.city)\(stateText)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Show tour position info if available
                            if let tourPosition = viewModel.tourPositionInfo {
                                Text(tourPosition.displayText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Duration availability status
                    if !viewModel.hasEnhancedData {
                        Text("Song durations unavailable (Phish.in API key required)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 12)
                    }
                    
                    // Display setlist with individual songs and durations
                    ForEach(groupedSetlistContent(), id: \.id) { item in
                        DetailedSetlistLineView(content: item.content)
                    }
                }
                .padding()
            }
        }
        .phishBackground()
        .onAppear {
            viewModel.fetchSetlist(for: date)
        }
        // set the navigation title to the current date
        .navigationTitle(date)
    }
    
    // MARK: - Helper Methods
    
    private func groupedSetlistContent() -> [SetlistContentItem] {
        var content: [SetlistContentItem] = []
        var currentSet = ""
        var itemIndex = 0
        
        for setlistItem in viewModel.setlistItems {
            // Add set header when we encounter a new set
            if setlistItem.set != currentSet {
                currentSet = setlistItem.set
                let setHeader = formatSetName(currentSet)
                content.append(SetlistContentItem(
                    id: "header_\(currentSet)",
                    content: .setHeader(setHeader)
                ))
            }
            
            // Display the song with its transition mark preserved
            let cleanSongName = SongParser.cleanSongName(setlistItem.song)
            // Use position-based matching for accurate durations with duplicate song names
            let duration = viewModel.formattedDuration(at: itemIndex, expectedName: cleanSongName)
            let transitionMark = setlistItem.transMark?.isEmpty == false ? setlistItem.transMark : nil
            let durationColor = viewModel.colorForSong(at: itemIndex, expectedName: cleanSongName)
            
            content.append(SetlistContentItem(
                id: "song_\(itemIndex)_\(cleanSongName)",
                content: .song(name: cleanSongName, duration: duration, transitionMark: transitionMark, durationColor: durationColor)
            ))
            
            itemIndex += 1
        }
        
        return content
    }
    
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

// MARK: - Supporting Types

struct SetlistContentItem {
    let id: String
    let content: DetailedSetlistLineView.LineContent
}
