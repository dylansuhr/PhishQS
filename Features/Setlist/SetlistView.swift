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
                            Text("\(firstItem.venue)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            let stateText = firstItem.state != nil ? ", \(firstItem.state!)" : ""
                            Text("\(firstItem.city)\(stateText)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
            
            // Parse individual songs from this setlist item
            var songLine = setlistItem.song
            if let transMark = setlistItem.transMark, !transMark.isEmpty {
                songLine += transMark
            }
            
            let songs = SongParser.parseSongs(from: songLine)
            
            for song in songs {
                let cleanSong = SongParser.cleanSongName(song)
                let duration = viewModel.formattedDuration(for: cleanSong)
                
                content.append(SetlistContentItem(
                    id: "song_\(itemIndex)_\(cleanSong)",
                    content: .song(name: cleanSong, duration: duration)
                ))
            }
            
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
