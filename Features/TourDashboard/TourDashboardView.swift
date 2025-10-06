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
        }
        .safeAreaInset(edge: .bottom) {
            FloatingSearchButton(showingDateSearch: $showingDateSearch)
        }
        .navigationTitle("PhishTD")
        .navigationBarTitleDisplayMode(.inline)
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

/// Floating search button with iOS 26 liquid glass effect
struct FloatingSearchButton: View {
    @Binding var showingDateSearch: Bool

    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                showingDateSearch = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.blue)

                    Text("Search")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.blue)
                }
                .frame(width: 70, height: 70)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
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