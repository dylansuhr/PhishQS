import SwiftUI

struct MonthListView: View {
    let year: String
    @StateObject private var viewModel = MonthListViewModel()

    var body: some View {
        List(viewModel.months, id: \.self) { month in
            NavigationLink(destination: DayListView(year: year, month: month)) {
                Text(month) // just "01", "02", ..., "12"
            }
        }
        .onAppear {
            viewModel.fetchMonths(for: year)
        }
        .navigationTitle(year)
    }
}
