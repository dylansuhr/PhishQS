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
            
            // Tour Calendar (Component D)
            DashboardSection {
                TourCalendarCard()
            }
            
            // Tour Statistics Cards
            if let statistics = latestSetlistViewModel.tourStatistics, statistics.hasData {
                DashboardSection {
                    TourStatisticsHeaderView(
                        tourName: statistics.tourName,
                        tourPosition: latestSetlistViewModel.tourPositionInfo
                    )
                    TourStatisticsCards(statistics: statistics)
                }
            } else if latestSetlistViewModel.isTourStatisticsLoading && latestSetlistViewModel.latestShow != nil {
                // Show loading state for tour statistics while main content is already loaded
                DashboardSection {
                    TourStatisticsLoadingView(
                        tourPosition: latestSetlistViewModel.tourPositionInfo
                    )
                }
            }
            
            // Search Action Card
            DashboardSection {
                SearchActionCard(showingDateSearch: $showingDateSearch)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDateSearch) {
            NavigationStack {
                YearListView()
            }
        }
    }
}

/// Header view for tour statistics section showing tour name and progress
struct TourStatisticsHeaderView: View {
    let tourName: String?
    let tourPosition: TourShowPosition?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tour Statistics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if let tourName = tourName {
                HStack {
                    Text(tourName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    if let tourPosition = tourPosition {
                        Spacer()
                        
                        Text("\(tourPosition.showNumber)/\(tourPosition.totalShows)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
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

/// Loading view for tour statistics
struct TourStatisticsLoadingView: View {
    let tourPosition: TourShowPosition?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tour Statistics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if let tourPosition = tourPosition {
                HStack {
                    Text(tourPosition.tourName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(tourPosition.showNumber)/\(tourPosition.totalShows)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            // Loading indicator
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading tour statistics...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

#Preview {
    NavigationStack {
        TourDashboardView()
    }
}