import SwiftUI

// View that fetches and displays a full setlist for a specific year/month/day
struct SetlistView: View {
    let year: String    // passed in from DayListView
    let month: String   // passed in from DayListView
    let day: String     // passed in from DayListView

    // view model loads setlist data from API
    @StateObject private var viewModel = SetlistViewModel()
    @State private var cachedContent: [SetlistContentItem] = []
    @State private var contentOpacity: Double = 0

    var body: some View {
        // build the full YYYY-MM-DD date string for API call
        let date = DateUtilities.padDateComponents(year: year, month: month, day: day)

        ScrollView {
            Color.clear
            LazyVStack(alignment: .leading, spacing: 8) {
                // Show header with date and venue info (from metadata)
                if let metadata = viewModel.showMetadata {
                    VStack(alignment: .leading, spacing: 6) {
                        // Formatted readable date
                        Text(DateUtilities.formatDateWithDayOfWeek(date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Venue name
                        Text(metadata.venue)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        // City, State
                        let stateText = metadata.state.isEmpty ? "" : ", \(metadata.state)"
                        Text("\(metadata.city)\(stateText)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Phish.in data availability indicator (only show if setlist exists)
                        if !viewModel.setlistItems.isEmpty {
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
                            .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    // Divider between header and setlist
                    if !viewModel.setlistItems.isEmpty {
                        Divider()
                            .padding(.vertical, 8)
                    }
                }

                // Display setlist with individual songs and durations (if available)
                ForEach(cachedContent, id: \.id) { item in
                    DetailedSetlistLineView(content: item.content)
                }
            }
            .padding(.horizontal)
            .opacity(contentOpacity)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.fetchSetlist(for: date)
        }
        .onChange(of: viewModel.showMetadata?.date) { _, newValue in
            // Fade in when metadata loads
            if newValue != nil && contentOpacity == 0 {
                withAnimation(.easeIn(duration: 0.2)) {
                    contentOpacity = 1
                }
            }
        }
        .onChange(of: viewModel.setlistItems) { _, newItems in
            cachedContent = groupedSetlistContent()
            // Also fade in when setlist loads (in case metadata was instant from cache)
            if !newItems.isEmpty && contentOpacity == 0 {
                withAnimation(.easeIn(duration: 0.2)) {
                    contentOpacity = 1
                }
            }
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            // Fallback: fade in when loading completes
            if !isLoading && contentOpacity == 0 && viewModel.showMetadata != nil {
                withAnimation(.easeIn(duration: 0.2)) {
                    contentOpacity = 1
                }
            }
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
