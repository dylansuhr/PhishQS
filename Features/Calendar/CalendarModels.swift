//
//  CalendarModels.swift
//  PhishQS
//
//  Component D: Tour Calendar - Data Models
//

import Foundation

// MARK: - Calendar Display Models

/// Represents a single month to be displayed in the calendar
struct CalendarMonth: Identifiable, Equatable {
    let id = UUID()
    let year: Int
    let month: Int
    let monthName: String
    var days: [CalendarDay]
    
    var displayTitle: String {
        "\(monthName) \(year)"
    }
}

/// Represents a single day in the calendar
struct CalendarDay: Identifiable, Equatable {
    let id = UUID()
    let dayNumber: Int
    let date: Date
    let dateComponents: DateComponents
    let isShowDate: Bool
    let isCurrentDay: Bool
    var showInfo: ShowInfo?
    
    /// Information about a show on this date
    struct ShowInfo: Equatable {
        let venue: String
        let city: String
        let state: String
        let showNumber: Int
        let venueRun: String? // e.g., "N1", "N2", "N3"
    }
}

// MARK: - Venue Run Spanning Models

/// Represents a grid position within the calendar
struct GridPosition: Equatable {
    let weekIndex: Int    // Which week row (0, 1, 2, 3, 4)
    let columnIndex: Int  // Day of week (0=Sun, 6=Sat)
    let date: Date
}

/// Represents a venue run spanning multiple dates
struct VenueRunSpan: Identifiable, Equatable {
    let id = UUID()
    let venue: String
    let city: String
    let state: String
    let startDate: Date
    let endDate: Date
    let dates: [Date]
    let gridPositions: [GridPosition]
    
    var displayText: String {
        "\(city), \(state)"
    }
    
    var spansWeeks: Bool {
        let calendar = Calendar.current
        let startWeek = calendar.component(.weekOfYear, from: startDate)
        let endWeek = calendar.component(.weekOfYear, from: endDate)
        return startWeek != endWeek
    }
    
    var spansMonths: Bool {
        let calendar = Calendar.current
        let startMonth = calendar.component(.month, from: startDate)
        let endMonth = calendar.component(.month, from: endDate)
        return startMonth != endMonth
    }
}

/// Badge geometry for complex spanning layouts
struct BadgeGeometry {
    let segments: [BadgeSegment]
    let totalWidth: CGFloat
    let shouldMarquee: Bool
}

/// Individual segment of a potentially multi-segment badge
struct BadgeSegment {
    let startX: CGFloat
    let width: CGFloat
    let weekIndex: Int
    let isFirstSegment: Bool
    let isLastSegment: Bool
}

/// Configuration for calendar display
struct CalendarConfiguration {
    let startMonth: DateComponents
    let endMonth: DateComponents
    let showDates: [Date]
    let tourName: String
    
    /// Create configuration from tour dashboard data
    static func from(tourData: TourDashboardDataClient.TourDashboardData.CurrentTour) -> CalendarConfiguration? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = dateFormatter.date(from: tourData.startDate),
              let endDate = dateFormatter.date(from: tourData.endDate) else {
            return nil
        }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month], from: endDate)
        
        let showDates = tourData.tourDates.compactMap { tourDate in
            dateFormatter.date(from: tourDate.date)
        }
        
        return CalendarConfiguration(
            startMonth: startComponents,
            endMonth: endComponents,
            showDates: showDates,
            tourName: tourData.name
        )
    }
}

/// Helper to build calendar grid data
struct CalendarBuilder {
    private let calendar = Calendar.current
    
    /// Build calendar months from configuration
    func buildMonths(from config: CalendarConfiguration) -> [CalendarMonth] {
        var months: [CalendarMonth] = []
        
        guard let startDate = calendar.date(from: config.startMonth),
              let endDate = calendar.date(from: config.endMonth) else {
            return []
        }
        
        var currentDate = startDate
        
        while currentDate <= endDate {
            if let month = buildMonth(for: currentDate, showDates: config.showDates) {
                months.append(month)
            }
            
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextMonth
        }
        
        return months
    }
    
    /// Build a single month
    private func buildMonth(for date: Date, showDates: [Date]) -> CalendarMonth? {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year,
              let month = components.month,
              let monthDate = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: monthDate) else {
            return nil
        }
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let monthName = monthFormatter.string(from: monthDate)
        
        var days: [CalendarDay] = []
        let today = Date()
        
        for day in range {
            var dayComponents = components
            dayComponents.day = day
            
            if let dayDate = calendar.date(from: dayComponents) {
                let isShowDate = showDates.contains { calendar.isDate($0, inSameDayAs: dayDate) }
                let isCurrentDay = calendar.isDate(today, inSameDayAs: dayDate)
                
                let calendarDay = CalendarDay(
                    dayNumber: day,
                    date: dayDate,
                    dateComponents: dayComponents,
                    isShowDate: isShowDate,
                    isCurrentDay: isCurrentDay,
                    showInfo: nil // Will be populated by ViewModel
                )
                days.append(calendarDay)
            }
        }
        
        return CalendarMonth(
            year: year,
            month: month,
            monthName: monthName,
            days: days
        )
    }
}