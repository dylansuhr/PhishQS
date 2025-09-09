//
//  TourCalendarViewModel.swift
//  PhishQS
//
//  Component D: Tour Calendar - ViewModel
//

import Foundation
import SwiftUI

@MainActor
class TourCalendarViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var calendarMonths: [CalendarMonth] = []
    @Published var currentMonthIndex: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var tourName: String = ""
    
    // MARK: - Dependencies
    
    private let dataClient = TourDashboardDataClient.shared
    private let calendarBuilder = CalendarBuilder()
    
    // MARK: - Computed Properties
    
    var currentMonth: CalendarMonth? {
        guard currentMonthIndex < calendarMonths.count else { return nil }
        return calendarMonths[currentMonthIndex]
    }
    
    var hasMultipleMonths: Bool {
        calendarMonths.count > 1
    }
    
    var canNavigateBack: Bool {
        currentMonthIndex > 0
    }
    
    var canNavigateForward: Bool {
        currentMonthIndex < calendarMonths.count - 1
    }
    
    // MARK: - Initialization
    
    init() {
        // Will load data when view appears
    }
    
    // MARK: - Public Methods
    
    func loadTourCalendar() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch tour dashboard data
            let dashboardData = try await dataClient.fetchCurrentTourData()
            
            // Create calendar configuration
            guard let config = CalendarConfiguration.from(tourData: dashboardData.currentTour) else {
                throw CalendarError.invalidTourData
            }
            
            // Build calendar months
            let months = calendarBuilder.buildMonths(from: config)
            
            // Enrich with show information
            let enrichedMonths = enrichMonths(months, with: dashboardData.currentTour)
            
            // Update state
            self.calendarMonths = enrichedMonths
            self.tourName = dashboardData.currentTour.name
            
            // Set current month to the one containing today (if within tour)
            setCurrentMonthToToday()
            
            isLoading = false
            
        } catch {
            errorMessage = "Failed to load tour calendar"
            isLoading = false
            print("Calendar loading error: \(error)")
        }
    }
    
    func navigateToPreviousMonth() {
        guard canNavigateBack else { return }
        currentMonthIndex -= 1
    }
    
    func navigateToNextMonth() {
        guard canNavigateForward else { return }
        currentMonthIndex += 1
    }
    
    func handleDateSelection(_ day: CalendarDay) {
        guard day.isShowDate else { return }
        
        // For now, just print - will be enhanced in later step
        if let showInfo = day.showInfo {
            print("Selected show: \(showInfo.venue) - \(day.date)")
        }
    }
    
    // MARK: - Private Methods
    
    private func enrichMonths(_ months: [CalendarMonth], with tourData: TourDashboardDataClient.TourDashboardData.CurrentTour) -> [CalendarMonth] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Create a map of dates to tour information
        var dateToShowInfo: [String: CalendarDay.ShowInfo] = [:]
        
        for (index, tourDate) in tourData.tourDates.enumerated() {
            // Calculate venue run info
            let venueRun = calculateVenueRun(for: index, in: tourData.tourDates)
            
            let showInfo = CalendarDay.ShowInfo(
                venue: tourDate.venue,
                city: tourDate.city,
                state: tourDate.state,
                showNumber: tourDate.showNumber,
                venueRun: venueRun
            )
            
            dateToShowInfo[tourDate.date] = showInfo
        }
        
        // Enrich calendar days with show information
        return months.map { month in
            var enrichedMonth = month
            enrichedMonth.days = month.days.map { day in
                var enrichedDay = day
                
                // Format the day's date to match tour date format
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "yyyy-MM-dd"
                let dayDateString = dayFormatter.string(from: day.date)
                
                if let showInfo = dateToShowInfo[dayDateString] {
                    enrichedDay.showInfo = showInfo
                }
                
                return enrichedDay
            }
            return enrichedMonth
        }
    }
    
    private func calculateVenueRun(for index: Int, in tourDates: [TourDashboardDataClient.TourDashboardData.TourDate]) -> String? {
        let currentVenue = tourDates[index].venue
        
        // Find all shows at this venue
        var venueShows: [Int] = []
        for (i, date) in tourDates.enumerated() {
            if date.venue == currentVenue {
                venueShows.append(i)
            }
        }
        
        // If only one show at venue, no run indicator
        guard venueShows.count > 1 else { return nil }
        
        // Find position in venue run
        if let position = venueShows.firstIndex(of: index) {
            return "N\(position + 1)"
        }
        
        return nil
    }
    
    private func setCurrentMonthToToday() {
        let today = Date()
        let calendar = Calendar.current
        
        for (index, month) in calendarMonths.enumerated() {
            let hasToday = month.days.contains { day in
                calendar.isDate(day.date, inSameDayAs: today)
            }
            
            if hasToday {
                currentMonthIndex = index
                return
            }
        }
        
        // Default to last month (latest tour month) if today not in tour
        currentMonthIndex = max(0, calendarMonths.count - 1)
    }
}

// MARK: - Error Types

enum CalendarError: LocalizedError {
    case invalidTourData
    case noShowDates
    
    var errorDescription: String? {
        switch self {
        case .invalidTourData:
            return "Invalid tour data format"
        case .noShowDates:
            return "No show dates available"
        }
    }
}