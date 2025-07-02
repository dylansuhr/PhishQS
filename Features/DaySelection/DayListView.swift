import SwiftUI

// View to display all show days for a selected month and year
struct DayListView: View {
    let year: String           // selected year passed from previous view
    let month: String          // selected month passed from previous view

    // view model manages and stores the list of day strings
    @StateObject private var viewModel = DayListViewModel()

    var body: some View {
        // show list of days using SwiftUI List
        List(viewModel.days, id: \.self) { day in
            // each day is tappable and navigates to the setlist for that date
            NavigationLink(destination: SetlistView(year: year, month: month, day: day)) {
                Text(day) // display the day string (e.g. "28")
            }
        }
        .onAppear {
            // fetch list of days for the given year and month
            viewModel.fetchDays(for: year, month: month)
        }
        // sets nav bar title to something like "01 2025"
        .navigationTitle("\(month) \(year)")
    }
}
