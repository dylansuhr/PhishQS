//
//  DayCell.swift
//  PhishQS
//
//  Individual calendar day cell component
//  Extracted from TourCalendarView.swift for better organization
//

import SwiftUI

struct DayCell: View {
    let day: CalendarDay
    let coordinateMap: CircleCoordinateMap

    var body: some View {
        ZStack {
            // Background layers
            if day.isCurrentDay && day.isShowDate {
                // Both current day and show date
                Circle()
                    .fill(showDateColor.opacity(0.2))
                    .overlay(
                        Circle()
                            .strokeBorder(Color(red: 0.961, green: 0.286, blue: 0.153), lineWidth: 7.0)
                    )
            } else if day.isCurrentDay {
                // Just current day
                Circle()
                    .strokeBorder(Color(red: 0.961, green: 0.286, blue: 0.153), lineWidth: 7.0)
            } else if day.isShowDate {
                // Just show date - filled circle with tour-specific color
                Circle()
                    .fill(showDateColor.opacity(0.2))
                    .overlay(
                        Circle()
                            .strokeBorder(showDateColor, lineWidth: 1.5)
                    )
            }

            // Day number
            Text("\(day.dayNumber)")
                .font(.system(size: 15, weight: day.isShowDate ? .medium : .regular, design: .rounded))
                .foregroundColor(textColor)
        }
        .frame(width: 40, height: 40)
        .contentShape(Rectangle())
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: CirclePositionPreferenceKey.self, value: [day.dayNumber: geometry.frame(in: .named("CalendarContainer"))])
            }
        )
    }

    private var textColor: Color {
        if day.isCurrentDay || day.isShowDate {
            return .primary
        } else {
            return .secondary.opacity(0.8)
        }
    }

    private var showDateColor: Color {
        // Use tour-specific color from showInfo, default to blue
        return day.showInfo?.tourColor ?? .blue
    }
}