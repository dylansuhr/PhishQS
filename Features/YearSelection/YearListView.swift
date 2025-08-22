import SwiftUI

// Year selection view for date search flow
struct YearListView: View {
    // holds the list of years (1983–2025 excluding 2005–2007)
    @StateObject private var viewModel = YearListViewModel()

    var body: some View {
        List(viewModel.years, id: \.self) { year in
            // when user taps a year, navigate to MonthListView
            NavigationLink(destination: MonthListView(year: year)) {
                Text(year)
                    .font(.body)
                    .padding(.vertical, 8)
            }
        }
        .background(Color(.systemGray6))
        .onAppear {
            // load the list of valid Phish touring years
            viewModel.fetchYears()
        }
        .navigationTitle("Select Year")
        .navigationBarTitleDisplayMode(.inline)
    }
}
