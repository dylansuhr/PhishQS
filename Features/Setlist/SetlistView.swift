import SwiftUI

// View that fetches and displays a full setlist for a specific year/month/day
struct SetlistView: View {
    let year: String    // passed in from DayListView
    let month: String   // passed in from DayListView
    let day: String     // passed in from DayListView

    // view model loads setlist data from API
    @StateObject private var viewModel = SetlistViewModel()
    @State private var cachedContent: [SetlistContentItem] = []

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
                LazyVStack(alignment: .leading, spacing: 8) {
                    // Show header with date and venue info
                    if let firstItem = viewModel.setlistItems.first {
                        VStack(alignment: .leading, spacing: 8) {
                            // Large bold date
                            Text(date)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            // Formatted readable date
                            Text(DateUtilities.formatDateWithDayOfWeek(date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Venue name
                            Text(firstItem.venue)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.top, 4)

                            // City, State
                            let stateText = firstItem.state != nil ? ", \(firstItem.state!)" : ""
                            Text("\(firstItem.city)\(stateText)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Phish.in data availability indicator
                            HStack(spacing: 4) {
                                Text("phish.in")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                if viewModel.hasValidDurations {
                                    Text("✓")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                } else {
                                    Text("✗")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.top, 2)
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Display setlist with individual songs and durations
                    ForEach(cachedContent, id: \.id) { item in
                        DetailedSetlistLineView(content: item.content)
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.fetchSetlist(for: date)
        }
        .onChange(of: viewModel.setlistItems) { _, _ in
            cachedContent = groupedSetlistContent()
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
            let transitionMark = setlistItem.transMark?.isEmpty == false ? setlistItem.transMark : nil

            // Only include duration if valid data exists
            let duration: String? = viewModel.hasValidDurations
                ? viewModel.formattedDuration(at: itemIndex, expectedName: cleanSongName)
                : nil

            content.append(SetlistContentItem(
                id: "song_\(itemIndex)_\(cleanSongName)",
                content: .song(name: cleanSongName, duration: duration, transitionMark: transitionMark, durationColor: nil)
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
