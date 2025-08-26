import SwiftUI

// Modern dashboard-style home screen
struct TourDashboardView: View {
    @StateObject private var latestSetlistViewModel = LatestSetlistViewModel()
    @State private var showingDateSearch = false

    var body: some View {
        DashboardGrid {
            // Latest Show Hero Card
            DashboardSection {
                LatestShowHeroCard(viewModel: latestSetlistViewModel)
            }
            
            // Tour Statistics Cards
            if let statistics = latestSetlistViewModel.tourStatistics, statistics.hasData {
                DashboardSection("Tour Statistics") {
                    TourStatisticsCards(statistics: statistics)
                }
            }
            
            // Search Action Card
            DashboardSection {
                SearchActionCard(showingDateSearch: $showingDateSearch)
            }
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
        .sheet(isPresented: $showingDateSearch) {
            NavigationStack {
                YearListView()
            }
        }
    }
}

/// Action card for search functionality
struct SearchActionCard: View {
    @Binding var showingDateSearch: Bool
    
    var body: some View {
        DashboardCard {
            VStack(spacing: 16) {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Find Any Show")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Search setlists by date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    showingDateSearch = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Search by Date")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    NavigationStack {
        TourDashboardView()
    }
}