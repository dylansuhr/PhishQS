//
//  TourCalendarCard.swift
//  PhishQS
//
//  Component D: Tour Calendar - Dashboard Card with Navigation
//

import SwiftUI
import UIKit

// MARK: - Tour Display Models

/// Unified tour info for display (works for both current and future tours)
struct TourDisplayInfo: Identifiable {
    let id = UUID()
    let name: String
    let totalShows: Int
    let startDate: String
    let venue: String  // First venue for color matching
}

/// Individual tour row with colored background
struct TourRow: View {
    let tour: TourDisplayInfo

    private var rowColor: Color {
        venueColor(for: tour.venue)
    }

    private var showCountText: String {
        tour.totalShows == 1 ? "1 show" : "\(tour.totalShows) shows"
    }

    var body: some View {
        HStack {
            Text(tour.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            Text(showCountText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(rowColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Tour Calendar Card

struct TourCalendarCard: View {
    @ObservedObject var viewModel: TourCalendarViewModel
    @State private var selectedShowDate: String?

    // Pre-warmed haptic generator to avoid first-tap delay
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    init(viewModel: TourCalendarViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        DashboardCard {
            VStack(spacing: 16) {
                // Header with navigation
                calendarHeader

                // Tour bars
                if !viewModel.allTours.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(viewModel.allTours) { tour in
                            TourRow(tour: tour)
                                .onTapGesture {
                                    viewModel.navigateToMonth(containing: tour.startDate)
                                }
                        }
                    }
                }

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
                    .frame(height: 350)
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

            // Pre-warm haptic engine so first tap is instant
            hapticGenerator.prepare()
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

        // Haptic feedback using pre-warmed generator
        hapticGenerator.impactOccurred()
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
        .frame(height: 350)
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
        .frame(height: 350)
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
        .frame(height: 350)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Tour Calendar Card") {
    ScrollView {
        TourCalendarCard(viewModel: TourCalendarViewModel())
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
