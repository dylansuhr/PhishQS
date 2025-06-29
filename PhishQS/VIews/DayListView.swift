import SwiftUI

struct DayListView: View {
    let year: String
    let month: String
    @StateObject private var viewModel = DayListViewModel()

    var body: some View {
        List(viewModel.days, id: \.self) { day in
            NavigationLink(destination: SetlistView(year: year, month: month, day: day)) {
                Text(day)
            }
        }
        .onAppear {
            viewModel.fetchDays(for: year, month: month)
        }
        .navigationTitle("\(month) \(year)")
    }
}
