import SwiftUI

// First screen: shows a list of years to pick from
struct YearListView: View {
    // holds the list of years (1983–2025 excluding 2005–2007)
    @StateObject private var viewModel = YearListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Latest setlist at the top
            LatestSetlistView()
                .padding(.horizontal)
                .padding(.top)
            
            // list of all valid years
            List(viewModel.years, id: \.self) { year in
                // when user taps a year, navigate to MonthListView
                NavigationLink(destination: MonthListView(year: year)) {
                    Text(year)
                }
            }
        }
        .onAppear {
            // load the list of valid Phish touring years
            viewModel.fetchYears()
        }
        // screen title
        .navigationTitle("Select Year")
    }
}
