//
//  TourCalendarView.swift
//  PhishQS
//
//  Component D: Tour Calendar - Main View
//

import SwiftUI

// MARK: - Coordinate Collection System

class CircleCoordinateMap: ObservableObject {
    @Published var coordinates: [String: CGRect] = [:]
    
    func setCoordinate(for dayKey: String, rect: CGRect) {
        coordinates[dayKey] = rect
    }
    
    func getCoordinate(for dayKey: String) -> CGRect? {
        return coordinates[dayKey]
    }
    
    func hasCoordinatesFor(days: [Int]) -> Bool {
        return days.allSatisfy { coordinates["\($0)"] != nil }
    }
}

// MARK: - Preference Key for Circle Positions

struct CirclePositionPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - Real Badge Segment

struct RealBadgeSegment {
    let centerX: CGFloat
    let centerY: CGFloat
    let width: CGFloat
    let isFirstSegment: Bool
    let isLastSegment: Bool
}

struct TourCalendarView: View {
    let month: CalendarMonth
    let venueRunSpans: [VenueRunSpan]
    var onDateSelected: ((CalendarDay) -> Void)?
    
    // Calendar grid configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    // Coordinate tracking
    @StateObject private var coordinateMap = CircleCoordinateMap()
    @State private var showBadges = false
    
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
            
            // Spanning venue badges overlay - only show when ready
            if showBadges {
                spanningBadgesOverlay
            }
        }
        .coordinateSpace(name: "CalendarContainer")
        .onAppear {
            // Delay badge appearance to allow calendar transition to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showBadges = true
            }
        }
        .onChange(of: month.id) { _ in
            // Hide badges immediately when month changes, then show after transition
            showBadges = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showBadges = true
            }
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
                    coordinateMap: coordinateMap,
                    color: venueColor(for: span.venue)
                )
            }
        }
        // No offset needed - badges now calculate proper position internally
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
                                // Start from right edge when marquee is needed
                                offset = width
                            }
                        }
                    )
                    .offset(x: offset)
                    .frame(height: geometry.size.height, alignment: .center)
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
        // Calculate total scroll distance (from right edge to completely off left edge)
        let totalDistance = textWidth + width
        let scrollDuration = Double(totalDistance / 30.0) // 30 pixels per second
        
        // Start from right edge, scroll to left edge and beyond
        offset = width  // Start position: right edge of container
        
        withAnimation(.linear(duration: scrollDuration).repeatForever(autoreverses: false)) {
            offset = -textWidth - 20  // End position: completely off left edge
        }
    }
}

// MARK: - Spanning Badge Components

struct SpanningMarqueeBadge: View {
    let span: VenueRunSpan
    @ObservedObject var coordinateMap: CircleCoordinateMap
    let color: Color
    
    var body: some View {
        // Check if coordinates are ready before rendering
        if coordinatesReady {
            let coordinateSegments = calculateRealCoordinateSegments()
            
            ForEach(coordinateSegments.indices, id: \.self) { index in
                let segment = coordinateSegments[index]
                
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
                .clipped()  // Clip content to RoundedRectangle boundaries
                .position(
                    x: segment.centerX,
                    y: segment.centerY
                )
            }
        }
    }
    
    private var coordinatesReady: Bool {
        let requiredDays = getRequiredDaysFromSpan()
        return coordinateMap.hasCoordinatesFor(days: requiredDays)
    }
    
    private func getRequiredDaysFromSpan() -> [Int] {
        let calendar = Calendar.current
        var days: [Int] = []
        var current = span.startDate
        
        while current <= span.endDate {
            let dayNumber = calendar.component(.day, from: current)
            days.append(dayNumber)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        
        return days
    }
    
    private func calculateRealCoordinateSegments() -> [RealBadgeSegment] {
        // Group dates by week to handle Saturday-Sunday spans
        let datesByWeek = groupDatesByWeek()
        var segments: [RealBadgeSegment] = []
        
        for (weekIndex, dates) in datesByWeek.enumerated() {
            if let segment = createSegmentFromRealCoordinates(dates: dates, isFirst: weekIndex == 0, isLast: weekIndex == datesByWeek.count - 1) {
                segments.append(segment)
            }
        }
        
        return segments
    }
    
    private func groupDatesByWeek() -> [[Int]] {
        // Extract day numbers from the span's dates
        let calendar = Calendar.current
        var datesByWeek: [[Int]] = []
        var currentWeekDates: [Int] = []
        var lastWeekday: Int? = nil
        
        // Create date range from span
        var current = span.startDate
        while current <= span.endDate {
            let dayNumber = calendar.component(.day, from: current)
            let weekday = calendar.component(.weekday, from: current)
            
            // Check if we've moved to a new week (Sunday = 1)
            if let lastDay = lastWeekday, weekday == 1 && lastDay != 1 {
                // Starting a new week, save current and start fresh
                if !currentWeekDates.isEmpty {
                    datesByWeek.append(currentWeekDates)
                    currentWeekDates = []
                }
            }
            
            currentWeekDates.append(dayNumber)
            lastWeekday = weekday
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        
        // Add final week
        if !currentWeekDates.isEmpty {
            datesByWeek.append(currentWeekDates)
        }
        
        return datesByWeek
    }
    
    private func createSegmentFromRealCoordinates(dates: [Int], isFirst: Bool, isLast: Bool) -> RealBadgeSegment? {
        guard !dates.isEmpty else { return nil }
        
        // Get coordinates for first and last date in this week segment
        let firstDay = dates.first!
        let lastDay = dates.last!
        
        guard let firstRect = coordinateMap.getCoordinate(for: "\(firstDay)"),
              let lastRect = coordinateMap.getCoordinate(for: "\(lastDay)") else {
            return nil
        }
        
        // Calculate badge position from left edge of first circle to right edge of last circle
        let startX = firstRect.minX
        let endX = lastRect.maxX
        let width = endX - startX
        let centerX = startX + width / 2
        
        // Position badge so its center is slightly below the top edge of the circles
        let centerY = firstRect.minY + 2 // Move badge center 2pt below top edge
        
        return RealBadgeSegment(
            centerX: centerX,
            centerY: centerY,
            width: width,
            isFirstSegment: isFirst,
            isLastSegment: isLast
        )
    }
}

// MARK: - Day Cell Component

struct DayCell: View {
    let day: CalendarDay
    let coordinateMap: CircleCoordinateMap
    
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
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: CirclePositionPreferenceKey.self, value: [day.dayNumber: geometry.frame(in: .named("CalendarContainer"))])
            }
        )
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