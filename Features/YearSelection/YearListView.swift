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
            .padding(.bottom)
            
            // Select Year section  
            VStack(spacing: 0) {
                HStack {
                    Text("Select Year")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    Spacer()
                }
                
                // list of all valid years
                List(viewModel.years, id: \.self) { year in
                    // when user taps a year, navigate to MonthListView
                    NavigationLink(destination: MonthListView(year: year)) {
                        Text(year)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color(.systemGray6))
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
                Image("QS_trasnparent")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 28)
            }
        }
    }
}
