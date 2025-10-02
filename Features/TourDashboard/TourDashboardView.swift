import SwiftUI

// Modern dashboard-style home screen
struct TourDashboardView: View {
    @EnvironmentObject var latestSetlistViewModel: LatestSetlistViewModel
    @State private var showingDateSearch = false
    @State private var animateCards = false
    @State private var animateCard1 = false
    @State private var animateCard2 = false
    @State private var animateCard3 = false
    @State private var animateCard4 = false
    @State private var animateCard5 = false

    var body: some View {
        DashboardGrid {
            // Latest Show Hero Card
            DashboardSection {
                LatestShowHeroCard(viewModel: latestSetlistViewModel)
                    .modifier(StateCardAnimationModifier(animate: $animateCard1))
            }

            // Tour Calendar (Component D)
            DashboardSection {
                TourCalendarCard()
                    .modifier(StateCardAnimationModifier(animate: $animateCard2))
            }

            // Tour Statistics Cards
            if let statistics = latestSetlistViewModel.tourStatistics, statistics.hasData {
                DashboardSection {
                    TourStatisticsHeaderView(
                        tourName: statistics.tourName,
                        tourPosition: latestSetlistViewModel.tourPositionInfo
                    )
                    .modifier(StateCardAnimationModifier(animate: $animateCard3))

                    TourStatisticsCards(statistics: statistics)
                        .modifier(StateCardAnimationModifier(animate: $animateCard4))
                }
            } else if latestSetlistViewModel.isTourStatisticsLoading && latestSetlistViewModel.latestShow != nil {
                // Show loading state for tour statistics while main content is already loaded
                DashboardSection {
                    TourStatisticsLoadingView(
                        tourPosition: latestSetlistViewModel.tourPositionInfo
                    )
                    .modifier(StateCardAnimationModifier(animate: $animateCard3))
                }
            }

            // Search Action Card
            DashboardSection {
                SearchActionCard(showingDateSearch: $showingDateSearch)
                    .modifier(StateCardAnimationModifier(animate: $animateCard5))
            }
        }
        .background(
            // Blue background extending into safe area for status bar visibility
            Color.appHeaderBlue
                .ignoresSafeArea(.container, edges: .top)
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appHeaderBlue, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("white_phish_td_transparent")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
            }
        }
        .sheet(isPresented: $showingDateSearch) {
            NavigationStack {
                YearListView()
            }
        }
        .onAppear {
            // State-driven animation chain - start immediately
            startAnimationSequence()
        }
        .onChange(of: animateCard1) { _, isAnimated in
            if isAnimated {
                // Card 1 completed, trigger card 2
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateCard2 = true
                }
            }
        }
        .onChange(of: animateCard2) { _, isAnimated in
            if isAnimated {
                // Card 2 completed, trigger card 3
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateCard3 = true
                }
            }
        }
        .onChange(of: animateCard3) { _, isAnimated in
            if isAnimated {
                // Card 3 completed, trigger card 4
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateCard4 = true
                }
            }
        }
        .onChange(of: animateCard4) { _, isAnimated in
            if isAnimated {
                // Card 4 completed, trigger card 5
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateCard5 = true
                }
            }
        }
    }

    private func startAnimationSequence() {
        // Begin state-driven animation chain
        animateCard1 = true
    }
}

/// Header view for tour statistics section showing tour name and progress
struct TourStatisticsHeaderView: View {
    let tourName: String?
    let tourPosition: TourShowPosition?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tourName = tourName {
                HStack {
                    Spacer()
                    Text(tourName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(Color.appHeaderBlue)
                .cornerRadius(12)

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
                        .foregroundColor(.phishBlue)

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
                }
                .buttonStyle(.borderedProminent)
                .tint(.phishBlue)
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
        VStack(alignment: .leading, spacing: 12) {
            if let tourPosition = tourPosition {
                HStack {
                    Spacer()
                    Text(tourPosition.tourName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(Color.appHeaderBlue)
                .cornerRadius(12)
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
    }
}

// MARK: - Animation Modifiers

/// Legacy modifier for card entrance animations (deprecated)
struct CardAnimationModifier: ViewModifier {
    let animate: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                .delay(delay),
                value: animate
            )
    }
}

/// State-driven modifier for card entrance animations (professional approach)
struct StateCardAnimationModifier: ViewModifier {
    @Binding var animate: Bool

    func body(content: Content) -> some View {
        content
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8),
                value: animate
            )
            .onAppear {
                // Card becomes visible immediately when state changes
                if !animate {
                    withAnimation {
                        animate = true
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        TourDashboardView()
            .environmentObject(LatestSetlistViewModel())
    }
}