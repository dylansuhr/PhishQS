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
                        .padding(.bottom, 16)
                    }
                    
                    // Display setlist with inline songs using shared component
                    ForEach(viewModel.setlist, id: \.self) { line in
                        if !line.isEmpty {
                            SetlistLineView(line)
                                .padding(.top, (line.hasPrefix("Set ") || line.hasPrefix("Encore:")) && line != viewModel.setlist.first ? 16 : 0)
                        }
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
}
