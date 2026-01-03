//
//  SmartLaunchView.swift
//  PhishQS
//
//  State-aware launch system that adapts to cold start, warm start, and background return
//  Uses instant transitions (no fades) to match professional apps like Spotify/Zillow
//

import SwiftUI

struct SmartLaunchView: View {
    @StateObject private var launchState = LaunchStateManager.shared
    @StateObject private var dashboardData = LatestSetlistViewModel()
    @StateObject private var calendarViewModel = TourCalendarViewModel()
    @State private var showBrandedLoading = true
    @State private var minimumLoadTimeElapsed = false
    @State private var hasInitialized = false
    @State private var hideStatusBar = true
    @State private var shouldTransitionToDashboard = false

    private var shouldShowBrandedLoading: Bool {
        // Don't show if we've already transitioned
        guard showBrandedLoading else { return false }

        // Show branded loading based on launch type and data state
        switch launchState.launchType {
        case .coldStart:
            // On cold start, show until both minimum time elapsed AND all data loaded
            return !minimumLoadTimeElapsed || dashboardData.isLoading || calendarViewModel.isLoading

        case .warmStart:
            // On warm start, only show if actually loading and no cached data
            return (dashboardData.isLoading && !dashboardData.hasCachedData()) || calendarViewModel.isLoading

        case .backgroundReturn:
            // Never show on quick background return
            return false
        }
    }

    var body: some View {
        ZStack {
            // Dashboard wrapped in NavigationStack (instant appearance when ready)
            if !shouldShowBrandedLoading {
                NavigationStack {
                    TourDashboardView(calendarViewModel: calendarViewModel)
                        .environmentObject(dashboardData)
                }
            }

            // Branded loading overlay (when needed) - outside NavigationStack
            if shouldShowBrandedLoading {
                BrandedLoadingView()
            }
        }
        .statusBarHidden(hideStatusBar)
        .onAppear {
            if !hasInitialized {
                startLaunchSequence()
                hasInitialized = true
            }
        }
        .onChange(of: dashboardData.isLoading) { _, _ in
            checkTransitionConditions()
        }
        .onChange(of: calendarViewModel.isLoading) { _, _ in
            checkTransitionConditions()
        }
        .onChange(of: minimumLoadTimeElapsed) { _, _ in
            checkTransitionConditions()
        }
        .onChange(of: shouldTransitionToDashboard) { _, shouldTransition in
            if shouldTransition {
                // State-driven transition - instant response to readiness
                showBrandedLoading = false
                // Animate status bar back smoothly
                withAnimation(.easeOut(duration: 0.2)) {
                    hideStatusBar = false
                }
                launchState.markInitialLoadComplete()
                shouldTransitionToDashboard = false // Reset state
            }
        }
    }

    private func startLaunchSequence() {
        // Determine launch type
        launchState.launchType = launchState.determineLaunchType()

        // Set minimum display time based on launch type
        switch launchState.launchType {
        case .coldStart:
            // Ensure brand is visible for at least 1.2s on cold start (like Spotify)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                minimumLoadTimeElapsed = true
            }

        case .warmStart:
            // Shorter minimum for warm starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                minimumLoadTimeElapsed = true
            }

        case .backgroundReturn:
            // No minimum time for background returns
            minimumLoadTimeElapsed = true
            // Don't hide status bar on background returns
            hideStatusBar = false
        }

        // Start loading data (both in parallel)
        dashboardData.loadInitialData()
        Task {
            await calendarViewModel.loadTourCalendar()
        }
    }

    private func checkTransitionConditions() {
        // State-driven transition logic - determine readiness for dashboard
        let shouldTransition: Bool = {
            switch launchState.launchType {
            case .coldStart:
                // Transition when minimum time passed AND all data loaded
                return minimumLoadTimeElapsed && !dashboardData.isLoading && !calendarViewModel.isLoading

            case .warmStart:
                // Transition when all data loaded or cached data available
                return (!dashboardData.isLoading || dashboardData.hasCachedData()) && !calendarViewModel.isLoading

            case .backgroundReturn:
                // Always transition immediately
                return true
            }
        }()

        if shouldTransition && showBrandedLoading {
            // Trigger state-driven transition
            shouldTransitionToDashboard = true
        }
    }
}

struct SmartLaunchView_Previews: PreviewProvider {
    static var previews: some View {
        SmartLaunchView()
    }
}