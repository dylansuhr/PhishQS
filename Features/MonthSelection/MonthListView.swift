import SwiftUI

// View to display all months that have shows for a selected year
struct MonthListView: View {
    let year: String  // selected year passed from YearListView

    // view model loads and stores available months (e.g. "01", "02", etc.)
    @StateObject private var viewModel = MonthListViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading months...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Error loading months")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        viewModel.fetchMonths(for: year)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // list of tappable months
                List(viewModel.months, id: \.self) { month in
                    // tap month to navigate to list of days in that month
                    NavigationLink(destination: DayListView(year: year, month: month)) {
                        Text(month) // display raw month string like "01"
                    }
                }
            }
        }
        .onAppear {
            // fetch available months for this year from API
            viewModel.fetchMonths(for: year)
        }
        // sets nav bar title to the selected year (e.g. "2025")
        .navigationTitle(year)
    }
}
