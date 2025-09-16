//
//  WelcomeView.swift
//  PhishQS
//
//  Created for seamless launch transition
//

import SwiftUI

struct WelcomeView: View {
    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 1.0
    @State private var backgroundColor = Color.phishBlue
    @State private var showDashboard = false
    @State private var dashboardOpacity: Double = 0.0

    private let launchBackgroundColor = Color.phishBlue
    private let animationDuration = 0.8

    var body: some View {
        ZStack {
            // Background that matches launch screen exactly
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: animationDuration), value: backgroundColor)

            if !showDashboard {
                // Logo that matches launch screen positioning
                Image("white_phish_td_transparent")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .background(launchBackgroundColor)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: logoScale)
                    .animation(.easeInOut(duration: animationDuration), value: logoOpacity)
            }

            // Dashboard that fades in
            if showDashboard {
                NavigationStack {
                    TourDashboardView()
                }
                .opacity(dashboardOpacity)
                .animation(.easeInOut(duration: 0.4), value: dashboardOpacity)
            }
        }
        .onAppear {
            performWelcomeAnimation()
        }
    }

    private func performWelcomeAnimation() {
        // Phase 1: Hold the logo briefly (matches launch screen)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Phase 2: Scale up logo slightly with spring animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                logoScale = 1.05
            }
        }

        // Phase 3: Begin transition to dashboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                logoOpacity = 0.0
                logoScale = 1.1
            }

            // Show dashboard
            showDashboard = true

            // Fade in dashboard with slight delay for smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    dashboardOpacity = 1.0
                    backgroundColor = Color(.systemBackground)
                }
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}