//
//  CalendarModels.swift
//  PhishQS
//
//  Component D: Tour Calendar - Data Models
//

import Foundation
import SwiftUI

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
        let tourId: String
        let tourName: String
        let tourColor: Color
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
    let allTours: [TourInfo]
    let includeCurrentMonth: Bool
    let currentMonthComponents: DateComponents
    let tourMonths: Set<DateComponents>
    
    struct TourInfo {
        let id: String
        let name: String
        let showDates: [Date]
        let isCurrentTour: Bool
    }
    
    /// Create configuration from tour dashboard data including future tours
    static func from(currentTour: TourDashboardDataClient.TourDashboardData.CurrentTour, 
                    futureTours: [TourDashboardDataClient.TourDashboardData.FutureTour]) -> CalendarConfiguration? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let calendar = Calendar.current
        let currentDate = Date()
        let currentComponents = calendar.dateComponents([.year, .month], from: currentDate)
        
        // Process current tour
        guard let _ = dateFormatter.date(from: currentTour.startDate),
              let _ = dateFormatter.date(from: currentTour.endDate) else {
            return nil
        }
        
        let currentTourShowDates = currentTour.tourDates.compactMap { tourDate in
            dateFormatter.date(from: tourDate.date)
        }
        
        var allTours: [TourInfo] = [
            TourInfo(
                id: "current-\(currentTour.year)",
                name: currentTour.name,
                showDates: currentTourShowDates,
                isCurrentTour: true
            )
        ]
        
        // Process future tours
        for futureTour in futureTours {
            let futureTourShowDates = futureTour.tourDates.compactMap { tourDate in
                dateFormatter.date(from: tourDate.date)
            }
            
            allTours.append(TourInfo(
                id: "future-\(futureTour.year)",
                name: futureTour.name,
                showDates: futureTourShowDates,
                isCurrentTour: false
            ))
        }
        
        // Find unique months that contain tour dates
        var tourMonths: Set<DateComponents> = Set()
        for tour in allTours {
            for showDate in tour.showDates {
                let monthComponents = calendar.dateComponents([.year, .month], from: showDate)
                tourMonths.insert(monthComponents)
            }
        }
        
        // Check if current month should be included
        let currentMonthInTourMonths = tourMonths.contains(currentComponents)
        
        return CalendarConfiguration(
            startMonth: DateComponents(), // Not used in new approach
            endMonth: DateComponents(), // Not used in new approach  
            allTours: allTours,
            includeCurrentMonth: !currentMonthInTourMonths,
            currentMonthComponents: currentComponents,
            tourMonths: tourMonths
        )
    }
}

/// Helper to build calendar grid data
struct CalendarBuilder {
    private let calendar = Calendar.current
    
    /// Build calendar months from configuration
    func buildMonths(from config: CalendarConfiguration) -> [CalendarMonth] {
        var months: [CalendarMonth] = []
        
        // Collect all show dates from all tours
        var allShowDates: [Date] = []
        for tour in config.allTours {
            allShowDates.append(contentsOf: tour.showDates)
        }
        
        // Build only months that have tour dates
        for monthComponents in config.tourMonths {
            guard let monthDate = calendar.date(from: monthComponents),
                  let month = buildMonth(for: monthDate, showDates: allShowDates) else {
                continue
            }
            months.append(month)
        }
        
        // Add current month if it's not already included in tour months
        if config.includeCurrentMonth {
            guard let currentMonthDate = calendar.date(from: config.currentMonthComponents),
                  let currentMonth = buildMonth(for: currentMonthDate, showDates: allShowDates) else {
                return months.sorted { month1, month2 in
                    let date1 = calendar.date(from: DateComponents(year: month1.year, month: month1.month)) ?? Date.distantPast
                    let date2 = calendar.date(from: DateComponents(year: month2.year, month: month2.month)) ?? Date.distantPast
                    return date1 < date2
                }
            }
            months.append(currentMonth)
        }
        
        // Sort months chronologically
        return months.sorted { month1, month2 in
            let date1 = calendar.date(from: DateComponents(year: month1.year, month: month1.month)) ?? Date.distantPast
            let date2 = calendar.date(from: DateComponents(year: month2.year, month: month2.month)) ?? Date.distantPast
            return date1 < date2
        }
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

// MARK: - Unified Color Generation System

/// Generate a consistent color for any calendar element (tours, venues, etc.)
func generateConsistentColor(for identifier: String, seedText: String = "") -> Color {
    // Use seedText for better uniqueness, fallback to identifier
    let seedString = seedText.isEmpty ? identifier : seedText
    
    // Create a stable hash using string characters
    var hash = 0
    for char in seedString.lowercased() {
        hash = hash &* 31 &+ Int(char.asciiValue ?? 0)
    }
    
    // Consistent app-wide color palette (matches venue badge colors and statistics colors)
    // Red and pink removed to preserve current day indicator distinctiveness
    let appColors: [Color] = [
        .blue, .orange, .green, .purple, .teal, .indigo
    ]
    return appColors[abs(hash) % appColors.count]
}

/// Generate a consistent color for a tour based on its name and ID
func tourColor(for tourId: String, tourName: String = "") -> Color {
    return generateConsistentColor(for: tourId, seedText: tourName)
}