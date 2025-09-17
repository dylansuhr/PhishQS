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
    @State private var showBrandedLoading = true
    @State private var minimumLoadTimeElapsed = false
    @State private var hasInitialized = false
    @State private var hideStatusBar = true

    private var shouldShowBrandedLoading: Bool {
        // Don't show if we've already transitioned
        guard showBrandedLoading else { return false }

        // Show branded loading based on launch type and data state
        switch launchState.launchType {
        case .coldStart:
            // On cold start, show until both minimum time elapsed AND data loaded
            return !minimumLoadTimeElapsed || dashboardData.isLoading

        case .warmStart:
            // On warm start, only show if actually loading and no cached data
            return dashboardData.isLoading && !dashboardData.hasCachedData()

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
                    TourDashboardView()
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
        .onChange(of: dashboardData.isLoading) { _, isLoading in
            checkTransitionConditions()
        }
        .onChange(of: minimumLoadTimeElapsed) { _, _ in
            checkTransitionConditions()
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

        // Start loading data
        dashboardData.loadInitialData()
    }

    private func checkTransitionConditions() {
        // Determine if we should hide branded loading
        let shouldHide: Bool = {
            switch launchState.launchType {
            case .coldStart:
                // Hide when minimum time passed AND data loaded
                return minimumLoadTimeElapsed && !dashboardData.isLoading

            case .warmStart:
                // Hide when data loaded or cached data available
                return !dashboardData.isLoading || dashboardData.hasCachedData()

            case .backgroundReturn:
                // Always hide immediately
                return true
            }
        }()

        if shouldHide && showBrandedLoading {
            // Instant transition to eliminate flash
            showBrandedLoading = false
            // Animate status bar back smoothly
            withAnimation(.easeOut(duration: 0.2)) {
                hideStatusBar = false
            }
            launchState.markInitialLoadComplete()
        }
    }
}

struct SmartLaunchView_Previews: PreviewProvider {
    static var previews: some View {
        SmartLaunchView()
    }
}