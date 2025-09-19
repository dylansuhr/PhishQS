//
//  SpanningMarqueeBadge.swift
//  PhishQS
//
//  Venue badge component that spans multiple calendar days
//  Extracted from TourCalendarView.swift for better organization
//

import SwiftUI

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