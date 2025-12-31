//
//  TourCalendarView.swift
//  PhishQS
//
//  Component D: Tour Calendar - Main View
//  Refactored into focused components for better organization
//

import SwiftUI

struct TourCalendarView: View {
    let month: CalendarMonth
    let venueRunSpans: [VenueRunSpan]
    let showBadges: Bool // Pass from ViewModel instead of local state
    var onDateSelected: ((CalendarDay) -> Void)?

    // Calendar grid configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]

    // Coordinate tracking
    @StateObject private var coordinateMap = CircleCoordinateMap()

    // Badge reset trigger - changes when month changes to force marquee reset
    @State private var badgeResetID = UUID()

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Month header - fixed at top, consistent across all months
                monthHeader
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Week labels + calendar grid - centered in remaining space
                VStack(spacing: 8) {
                    Spacer(minLength: 0)

                    // Week day labels
                    weekDayLabels

                    // Calendar grid
                    calendarGrid

                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            // Spanning venue badges overlay - only show when ready
            if showBadges {
                spanningBadgesOverlay
            }
        }
        .coordinateSpace(name: "CalendarContainer")
        .onAppear {
            // Reset all marquee animations to start fresh with consistent timing
            badgeResetID = UUID()
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Text(month.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()
        }
    }

    // MARK: - Week Day Labels

    private var weekDayLabels: some View {
        HStack(spacing: 2) {
            ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 2)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            // Add empty cells for proper day alignment
            ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                Color.clear
                    .frame(height: 40)
            }

            // Add day cells
            ForEach(month.days) { day in
                DayCell(day: day, coordinateMap: coordinateMap)
                    .onTapGesture {
                        if day.isShowDate {
                            onDateSelected?(day)
                        }
                    }
            }
        }
        .coordinateSpace(name: "CalendarGrid")
        .onPreferenceChange(CirclePositionPreferenceKey.self) { positions in
            // Update coordinate map when preferences change
            for (dayNumber, rect) in positions {
                coordinateMap.setCoordinate(for: "\(dayNumber)", rect: rect)
            }
        }
    }

    // Calculate offset for first day of month
    private var firstWeekdayOffset: Int {
        guard let firstDay = month.days.first else { return 0 }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: firstDay.date)
        return weekday - 1
    }

    // MARK: - Spanning Badges Overlay

    private var spanningBadgesOverlay: some View {
        // Get month boundaries for filtering
        let monthStart = month.days.first?.date ?? Date()
        let monthEnd = month.days.last?.date ?? Date()

        // Filter spans that are relevant to this month
        let monthSpans = venueRunSpans.filter { span in
            // Include spans that intersect with this month
            return span.startDate <= monthEnd && span.endDate >= monthStart
        }

        return ZStack {
            ForEach(monthSpans) { span in
                SpanningMarqueeBadge(
                    span: span,
                    coordinateMap: coordinateMap,
                    color: venueColor(for: span.venue),
                    monthStartDate: monthStart,
                    monthEndDate: monthEnd
                )
                .id("\(span.id)-\(badgeResetID)") // Force view recreation when reset ID changes
            }
        }
        // No offset needed - badges now calculate proper position internally
    }
}

// MARK: - Venue Color Generation

/// Generate a consistent color for a venue based on its name
// venueColor function moved to TourCalendarUtilities.swift

// MARK: - Preview

// Preview removed - sample data methods not available