//
//  TourCalendarCard.swift
//  PhishQS
//
//  Component D: Tour Calendar - Dashboard Card with Navigation
//

import SwiftUI
import UIKit

struct TourCalendarCard: View {
    @StateObject private var viewModel = TourCalendarViewModel()
    @State private var selectedShowDate: String?
    
    var body: some View {
        DashboardCard {
            VStack(spacing: 16) {
                // Header with navigation
                calendarHeader
                
                // Calendar content
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.calendarMonths.isEmpty {
                    TabView(selection: $viewModel.currentMonthIndex) {
                        ForEach(Array(viewModel.calendarMonths.enumerated()), id: \.element.id) { index, month in
                            TourCalendarView(
                                month: month,
                                venueRunSpans: viewModel.venueRunSpans,
                                showBadges: viewModel.showBadges
                            ) { day in
                                handleDateSelection(day)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 370) // Compact layout for 6-week months
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentMonthIndex)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    emptyView
                }
            }
        }
        .onAppear {
            // Only load if we haven't loaded initial data yet
            if !viewModel.hasLoadedInitialData {
                Task {
                    await viewModel.loadTourCalendar()
                }
            }

            // Pre-warm singletons and view model on main thread so first date tap is instant
            Task {
                _ = SetlistViewModel()
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedShowDate != nil },
            set: { if !$0 { selectedShowDate = nil } }
        )) {
            if let date = selectedShowDate {
                NavigationStack {
                    SetlistView(
                        year: String(date.prefix(4)),
                        month: String(date.dropFirst(5).prefix(2)),
                        day: String(date.suffix(2))
                    )
                }
            }
        }
    }
    
    // MARK: - Date Selection
    
    private func handleDateSelection(_ day: CalendarDay) {
        // Format date as YYYY-MM-DD for SetlistView
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        selectedShowDate = formatter.string(from: day.date)

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Header (Empty for now)
    
    private var calendarHeader: some View {
        EmptyView()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading tour calendar...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.loadTourCalendar()
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.title)
                .foregroundColor(.gray)
            
            Text("No tour dates available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Tour Calendar Card") {
    ScrollView {
        TourCalendarCard()
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
