//
//  CalendarCoordinateUtilities.swift
//  PhishQS
//
//  Coordinate management utilities for calendar badge positioning
//  Extracted from TourCalendarView.swift for better organization
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

    /// Clear all stored coordinates (call when month changes or view disappears)
    func clear() {
        coordinates.removeAll()
    }
}

// MARK: - Preference Key for Circle Positions

struct CirclePositionPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - Badge Geometry

struct RealBadgeSegment {
    let centerX: CGFloat
    let centerY: CGFloat
    let width: CGFloat
    let isFirstSegment: Bool
    let isLastSegment: Bool
}