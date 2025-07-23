//
//  DateUtilities.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/23/25.
//

import Foundation

/// Utilities for parsing and formatting dates from Phish.net API
struct DateUtilities {
    
    /// Parse a show date string (YYYY-MM-DD) into components
    static func parseShowDate(_ dateString: String) -> (year: String, month: String, day: String)? {
        let components = dateString.split(separator: "-")
        guard components.count == 3 else { return nil }
        
        return (
            year: String(components[0]),
            month: String(components[1]),
            day: String(components[2])
        )
    }
    
    /// Extract unique months from shows for a given year
    static func extractMonths(from shows: [Show], forYear year: String) -> [String] {
        let monthInts = Set(shows
            .filter { APIUtilities.isPhishShow($0) }
            .compactMap { show -> Int? in
                let components = show.showdate.split(separator: "-")
                return components.count > 1 ? Int(components[1]) : nil
            })
        
        return monthInts.sorted().reversed().map { String(format: "%02d", $0) }
    }
    
    /// Extract unique days from shows for a given year and month
    static func extractDays(from shows: [Show], forYear year: String, month: String) -> [String] {
        let uniqueDates = Set(shows
            .filter { APIUtilities.isPhishShow($0) }
            .map { $0.showdate })
        
        let dayStrings = uniqueDates.compactMap { date -> String? in
            guard let parsed = parseShowDate(date) else { return nil }
            return (parsed.year == year && parsed.month == month) ? parsed.day : nil
        }
        
        return dayStrings
            .compactMap { Int($0) }
            .sorted()
            .reversed()
            .map { String(format: "%02d", $0) }
    }
    
    /// Format a date string for display (e.g., "2025-01-28" → "January 28, 2025")
    static func formatDateForDisplay(_ dateString: String) -> String {
        guard let parsed = parseShowDate(dateString) else { return dateString }
        
        // Simple month names - could be enhanced with DateFormatter
        let monthNames = [
            "01": "January", "02": "February", "03": "March", "04": "April",
            "05": "May", "06": "June", "07": "July", "08": "August",
            "09": "September", "10": "October", "11": "November", "12": "December"
        ]
        
        let monthName = monthNames[parsed.month] ?? parsed.month
        return "\(monthName) \(Int(parsed.day) ?? 0), \(parsed.year)"
    }
    
    /// Ensure date components are properly padded (e.g., "1" → "01")
    static func padDateComponents(year: String, month: String, day: String) -> String {
        let paddedMonth = month.count == 1 ? "0\(month)" : month
        let paddedDay = day.count == 1 ? "0\(day)" : day
        return "\(year)-\(paddedMonth)-\(paddedDay)"
    }
}