import SwiftUI

// First screen: shows a list of years to pick from
struct YearListView: View {
    // holds the list of years (1983–2025 excluding 2005–2007)
    @StateObject private var viewModel = YearListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Latest Show section (no header, positioned higher)
            VStack(alignment: .leading, spacing: 8) {
                LatestSetlistView()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // List of all valid years
            List(viewModel.years, id: \.self) { year in
                // when user taps a year, navigate to MonthListView
                NavigationLink(destination: MonthListView(year: year)) {
                    Text(year)
                }
            }
        }
        .background(Color(.systemGray6))
        .onAppear {
            // load the list of valid Phish touring years
            viewModel.fetchYears()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("QS_transparent")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 28)
            }
        }
    }
}
