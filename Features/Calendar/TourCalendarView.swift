//
//  TourCalendarView.swift
//  PhishQS
//
//  Component D: Tour Calendar - Main View
//

import SwiftUI

struct TourCalendarView: View {
    let month: CalendarMonth
    let venueRunSpans: [VenueRunSpan] // Add venue run spans parameter
    var onDateSelected: ((CalendarDay) -> Void)?
    
    // Calendar grid configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                // Month header
                monthHeader
                
                // Week day labels
                weekDayLabels
                
                // Calendar grid
                calendarGrid
            }
            .padding()
            
            // Spanning venue badges overlay
            spanningBadgesOverlay
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
        .padding(.bottom, 4)
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Add empty cells for proper day alignment
            ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                Color.clear
                    .frame(height: 44)
            }
            
            // Add day cells
            ForEach(month.days) { day in
                DayCell(day: day)
                    .onTapGesture {
                        if day.isShowDate {
                            onDateSelected?(day)
                        }
                    }
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
        // Filter spans that are relevant to this month
        let monthSpans = venueRunSpans.filter { span in
            let calendar = Calendar.current
            let monthStart = month.days.first?.date ?? Date()
            let monthEnd = month.days.last?.date ?? Date()
            
            // Include spans that intersect with this month
            return span.startDate <= monthEnd && span.endDate >= monthStart
        }
        
        return ZStack {
            ForEach(monthSpans) { span in
                SpanningMarqueeBadge(
                    span: span,
                    color: venueColor(for: span.venue)
                )
            }
        }
        .offset(y: 80) // Adjust to position over calendar grid (below headers)
    }
}

// MARK: - Venue Color Generation

/// Generate a consistent color for a venue based on its name
func venueColor(for venue: String) -> Color {
    // Use a simple hash of the venue name for consistent color assignment
    let hash = venue.hashValue
    let colors: [Color] = [
        .blue, .green, .orange, .purple, .red, .teal, .pink, .indigo
    ]
    return colors[abs(hash) % colors.count]
}

// MARK: - Marquee Text Component

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let width: CGFloat
    
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    
    private var shouldMarquee: Bool {
        textWidth > width - 8 // Account for padding
    }
    
    var body: some View {
        if shouldMarquee {
            // Category 2: Full marquee scroll
            GeometryReader { geometry in
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .fixedSize()
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear.onAppear {
                                textWidth = textGeometry.size.width
                            }
                        }
                    )
                    .offset(x: offset)
                    .clipped()
                    .onAppear {
                        startMarquee()
                    }
            }
            .frame(width: width)
        } else {
            // Category 1: Static display
            Text(text)
                .font(font)
                .foregroundColor(color)
                .background(
                    GeometryReader { textGeometry in
                        Color.clear.onAppear {
                            textWidth = textGeometry.size.width
                        }
                    }
                )
                .frame(width: width)
        }
    }
    
    private func startMarquee() {
        let scrollDuration = Double(textWidth / 30.0) // 30 pixels per second
        
        withAnimation(.linear(duration: scrollDuration).repeatForever(autoreverses: false)) {
            offset = -(textWidth + 20) // Extra padding at end
        }
    }
}

// MARK: - Spanning Badge Components

struct SpanningMarqueeBadge: View {
    let span: VenueRunSpan
    let cellWidth: CGFloat = 44.0
    let color: Color
    
    private var badgeGeometry: BadgeGeometry {
        calculateBadgeGeometry(for: span)
    }
    
    var body: some View {
        ForEach(badgeGeometry.segments.indices, id: \.self) { index in
            let segment = badgeGeometry.segments[index]
            
            RoundedRectangle(
                cornerRadius: segment.isFirstSegment && segment.isLastSegment ? 6 : 
                             segment.isFirstSegment ? 6 : 
                             segment.isLastSegment ? 6 : 0
            )
            .fill(color)
            .frame(width: segment.width, height: 16)
            .overlay(
                MarqueeText(
                    text: span.displayText,
                    font: .system(size: 10, weight: .bold),
                    color: .white,
                    width: segment.width - 8
                )
                .padding(.horizontal, 4)
            )
            .position(
                x: segment.startX + segment.width / 2,
                y: calculateBadgeY(for: segment.weekIndex)
            )
        }
    }
    
    private func calculateBadgeGeometry(for span: VenueRunSpan) -> BadgeGeometry {
        let sortedPositions = span.gridPositions.sorted { 
            ($0.weekIndex, $0.columnIndex) < ($1.weekIndex, $1.columnIndex) 
        }
        
        if span.spansWeeks {
            // Handle cross-week spans
            return createMultiSegmentBadge(positions: sortedPositions)
        } else {
            // Simple single-row badge
            return createSimpleBadge(positions: sortedPositions)
        }
    }
    
    private func createSimpleBadge(positions: [GridPosition]) -> BadgeGeometry {
        let startColumn = positions.first!.columnIndex
        let endColumn = positions.last!.columnIndex
        let weekIndex = positions.first!.weekIndex
        
        let width = CGFloat(endColumn - startColumn + 1) * cellWidth
        let startX = CGFloat(startColumn) * cellWidth
        
        let segment = BadgeSegment(
            startX: startX,
            width: width,
            weekIndex: weekIndex,
            isFirstSegment: true,
            isLastSegment: true
        )
        
        return BadgeGeometry(
            segments: [segment],
            totalWidth: width,
            shouldMarquee: span.displayText.count > Int(width / 8) // Rough character estimation
        )
    }
    
    private func createMultiSegmentBadge(positions: [GridPosition]) -> BadgeGeometry {
        // Group positions by week
        let positionsByWeek = Dictionary(grouping: positions) { $0.weekIndex }
        var segments: [BadgeSegment] = []
        let sortedWeeks = positionsByWeek.keys.sorted()
        
        for (index, weekIndex) in sortedWeeks.enumerated() {
            let weekPositions = positionsByWeek[weekIndex]!.sorted { $0.columnIndex < $1.columnIndex }
            let startColumn = weekPositions.first!.columnIndex
            let endColumn = weekPositions.last!.columnIndex
            
            let width = CGFloat(endColumn - startColumn + 1) * cellWidth
            let startX = CGFloat(startColumn) * cellWidth
            
            let segment = BadgeSegment(
                startX: startX,
                width: width,
                weekIndex: weekIndex,
                isFirstSegment: index == 0,
                isLastSegment: index == sortedWeeks.count - 1
            )
            
            segments.append(segment)
        }
        
        let totalWidth = segments.reduce(0) { $0 + $1.width }
        
        return BadgeGeometry(
            segments: segments,
            totalWidth: totalWidth,
            shouldMarquee: span.displayText.count > Int(totalWidth / 8)
        )
    }
    
    private func calculateBadgeY(for weekIndex: Int) -> CGFloat {
        // Badge positioned at top of each week row
        // Each cell is 44pt height + 8pt spacing = 52pt total per row
        // Add 22pt (half cell height) to center vertically on the cell row
        return CGFloat(weekIndex) * 52.0 + 22.0 // Center on cell
    }
}

// MARK: - Day Cell Component

struct DayCell: View {
    let day: CalendarDay
    
    var body: some View {
        ZStack {
            // Background layers
            if day.isCurrentDay && day.isShowDate {
                // Both current day and show date
                Circle()
                    .fill(Color.blue)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                    )
            } else if day.isCurrentDay {
                // Just current day
                Circle()
                    .fill(Color.blue.opacity(0.15))
            } else if day.isShowDate {
                // Just show date - filled circle like Apple Calendar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        Circle()
                            .strokeBorder(Color.blue, lineWidth: 1.5)
                    )
            }
            
            // Day number (unified for all cases)
            Text("\(day.dayNumber)")
                .font(.system(size: 15, weight: day.isShowDate ? .medium : .regular, design: .rounded))
                .foregroundColor(textColor)
            
            // Individual venue badges removed - replaced by spanning system
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    
    private var textColor: Color {
        if day.isCurrentDay && day.isShowDate {
            return .white
        } else if day.isCurrentDay {
            return .blue
        } else if day.isShowDate {
            return .primary
        } else {
            return .secondary.opacity(0.8)
        }
    }
}

// MARK: - Preview

#Preview("Tour Calendar - June 2025") {
    TourCalendarView(
        month: CalendarMonth(
            year: 2025,
            month: 6,
            monthName: "June",
            days: (1...30).map { dayNum in
                let showDates = [20, 21, 22, 24, 27, 28]
                return CalendarDay(
                    dayNumber: dayNum,
                    date: Date(),
                    dateComponents: DateComponents(year: 2025, month: 6, day: dayNum),
                    isShowDate: showDates.contains(dayNum),
                    isCurrentDay: dayNum == 15,
                    showInfo: nil
                )
            }
        ),
        venueRunSpans: []
    )
    .background(Color(.systemBackground))
}

#Preview("Tour Calendar - July 2025") {
    TourCalendarView(
        month: CalendarMonth(
            year: 2025,
            month: 7,
            monthName: "July",
            days: (1...31).map { dayNum in
                let showDates = [3, 4, 5, 9, 11, 12, 13, 16, 18, 19, 20, 23, 24, 26, 27]
                return CalendarDay(
                    dayNumber: dayNum,
                    date: Date(),
                    dateComponents: DateComponents(year: 2025, month: 7, day: dayNum),
                    isShowDate: showDates.contains(dayNum),
                    isCurrentDay: false,
                    showInfo: nil
                )
            }
        ),
        venueRunSpans: []
    )
    .background(Color(.systemBackground))
}