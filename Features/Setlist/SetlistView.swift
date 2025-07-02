import SwiftUI

// View that fetches and displays a full setlist for a specific year/month/day
struct SetlistView: View {
    let year: String    // passed in from DayListView
    let month: String   // passed in from DayListView
    let day: String     // passed in from DayListView

    // view model loads setlist data from API
    @StateObject private var viewModel = SetlistViewModel()

    var body: some View {
        // ensure we always use 2-digit month/day in API request (e.g., "04", not "4")
        let paddedMonth = month.count == 1 ? "0\(month)" : month
        let paddedDay = day.count == 1 ? "0\(day)" : day

        // build the full YYYY-MM-DD date string for API call
        let date = "\(year)-\(paddedMonth)-\(paddedDay)"

        ScrollView {
            // show loading spinner while setlist is empty
            if viewModel.setlist.isEmpty {
                ProgressView()
            } else {
                // once loaded, display each setlist line in a vertical stack
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.setlist, id: \.self) { line in
                        Text(line)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // fire the API request when view appears
            print("🗓️ Fetching setlist for date: \(date)")
            viewModel.fetchSetlist(for: date)
        }
        // set the navigation title to the current date
        .navigationTitle(date)
    }
}
