import SwiftUI
import UIKit

// Modern dashboard-style home screen
struct TourDashboardView: View {
    // Feature flag: Set to true to enable date search (Component C)
    private let showDateSearchFeature = false

    @EnvironmentObject var latestSetlistViewModel: LatestSetlistViewModel
    @ObservedObject var calendarViewModel: TourCalendarViewModel
    @State private var showingDateSearch = false
    @State private var showingPhishNet = false
    @State private var showingYouTube = false
    @State private var animateCard1 = false
    @State private var animateCard2 = false
    @State private var animateCard3 = false
    @State private var showTourNameInNav = false
    @State private var animationWarmup = false  // Pre-warm animation system

    // Pre-warm haptic engine at dashboard level for all child components
    private let sharedHapticGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        DashboardGrid {
            // Tour Header at the very top
            if let statistics = latestSetlistViewModel.tourStatistics, statistics.hasData {
                TourStatisticsHeaderView(
                    tourName: statistics.tourName,
                    tourPosition: latestSetlistViewModel.tourPositionInfo,
                    onVisibilityChange: { isVisible in
                        showTourNameInNav = !isVisible
                    }
                )
            } else if let tourPosition = latestSetlistViewModel.tourPositionInfo {
                TourStatisticsHeaderView(
                    tourName: tourPosition.tourName,
                    tourPosition: tourPosition,
                    onVisibilityChange: { isVisible in
                        showTourNameInNav = !isVisible
                    }
                )
            }

            // Latest Show Hero Card
            DashboardSection {
                LatestShowHeroCard(viewModel: latestSetlistViewModel)
                    .modifier(StateCardAnimationModifier(animate: $animateCard1))
            }

            // Quick Links (Phish.net + YouTube)
            DashboardSection {
                HStack(spacing: 12) {
                    // Phish.net card - links to latest show
                    Button {
                        if latestSetlistViewModel.setlistItems.first?.phishNetURL != nil {
                            showingPhishNet = true
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image("phish_net_icon_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                            Text("Latest Show")
                                .font(.caption)
                                .foregroundColor(.appHeaderBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }

                    // YouTube card - tour videos
                    Button {
                        showingYouTube = true
                    } label: {
                        VStack(spacing: 8) {
                            Image("you_tube")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                            Text("Tour Videos")
                                .font(.caption)
                                .foregroundColor(.appHeaderBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
                .modifier(StateCardAnimationModifier(animate: $animateCard1))
            }

            // Tour Calendar (Component D)
            DashboardSection {
                TourCalendarCard(viewModel: calendarViewModel)
                    .modifier(StateCardAnimationModifier(animate: $animateCard2))
            }

            // Tour Statistics Cards
            if let statistics = latestSetlistViewModel.tourStatistics, statistics.hasData {
                DashboardSection {
                    TourStatisticsCards(statistics: statistics)
                        .modifier(StateCardAnimationModifier(animate: $animateCard3))
                }
            } else if latestSetlistViewModel.isTourStatisticsLoading && latestSetlistViewModel.latestShow != nil {
                // Show loading state for tour statistics while main content is already loaded
                DashboardSection {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading tour statistics...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .modifier(StateCardAnimationModifier(animate: $animateCard3))
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if showDateSearchFeature {
                FloatingSearchButton(showingDateSearch: $showingDateSearch)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if showTourNameInNav {
                    Text(currentTourName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appHeaderBlue)
                } else {
                    Image("blue_phish_td_transparent")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                }
            }
        }
        .sheet(isPresented: $showingDateSearch) {
            if showDateSearchFeature {
                NavigationStack {
                    YearListView()
                }
            }
        }
        .sheet(isPresented: $showingPhishNet) {
            if let url = latestSetlistViewModel.setlistItems.first?.phishNetURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showingYouTube) {
            TourVideosSheet(videos: latestSetlistViewModel.tourStatistics?.youtubeVideos ?? [])
        }
        .onAppear {
            // Pre-warm haptic engine immediately so first interaction is instant
            sharedHapticGenerator.prepare()

            // Pre-warm animation system with invisible animation
            withAnimation(.easeInOut(duration: 0.01)) {
                animationWarmup = true
            }

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
    }

    private func startAnimationSequence() {
        // Begin state-driven animation chain
        animateCard1 = true
    }

    private var currentTourName: String {
        if let statistics = latestSetlistViewModel.tourStatistics, let name = statistics.tourName {
            return name
        } else if let tourPosition = latestSetlistViewModel.tourPositionInfo {
            return tourPosition.tourName
        }
        return "PhishTD"
    }
}

/// Header view for tour statistics section showing tour name and progress
struct TourStatisticsHeaderView: View {
    let tourName: String?
    let tourPosition: TourShowPosition?
    var onVisibilityChange: ((Bool) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let tourName = tourName {
                Text("TOUR")
                    .font(.caption2)
                    .foregroundColor(.appHeaderBlue)
                    .textCase(.uppercase)
                    .tracking(0.5)

                HStack(alignment: .center, spacing: 8) {
                    Text(tourName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appHeaderBlue)

                    if let tourPosition = tourPosition {
                        BadgeView(text: "\(tourPosition.showNumber)/\(tourPosition.totalShows)", style: .blue)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.frame(in: .global).minY) { _, newValue in
                        // Header is "hidden" when it scrolls above the nav bar area (~100pt from top)
                        onVisibilityChange?(newValue > 50)
                    }
            }
        )
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
        TourDashboardView(calendarViewModel: TourCalendarViewModel())
            .environmentObject(LatestSetlistViewModel())
    }
}