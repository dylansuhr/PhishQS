//
//  TourCalendarView.swift
//  PhishQS
//
//  Component D: Tour Calendar - Main View
//

import SwiftUI

struct TourCalendarView: View {
    let month: CalendarMonth
    var onDateSelected: ((CalendarDay) -> Void)?
    
    // Calendar grid configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Month header
            monthHeader
            
            // Week day labels
            weekDayLabels
            
            // Calendar grid
            calendarGrid
        }
        .padding()
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
            ForEach(weekDays, id: \.self) { day in
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
            
            // Show indicator dot (smaller, below number)
            if day.isShowDate && !day.isCurrentDay {
                VStack(spacing: 2) {
                    Text("\(day.dayNumber)")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(textColor)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 4)
                }
            } else {
                // Regular day number
                Text("\(day.dayNumber)")
                    .font(.system(size: 15, weight: day.isShowDate ? .medium : .regular, design: .rounded))
                    .foregroundColor(textColor)
            }
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
        )
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
        )
    )
    .background(Color(.systemBackground))
}