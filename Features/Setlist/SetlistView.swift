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
                            Text("\(firstItem.city)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Display setlist with inline songs
                    ForEach(viewModel.setlist, id: \.self) { line in
                        if !line.isEmpty {
                            Text(line)
                                .font(line.contains("Set ") || line.contains("Encore:") ? .headline : .body)
                                .fontWeight(line.contains("Set ") || line.contains("Encore:") ? .semibold : .regular)
                                .foregroundColor(line.contains("Set ") || line.contains("Encore:") ? .blue : .primary)
                                .padding(.top, (line.contains("Set ") || line.contains("Encore:")) && line != viewModel.setlist.first ? 16 : 0)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.fetchSetlist(for: date)
        }
        // set the navigation title to the current date
        .navigationTitle(date)
    }
}
