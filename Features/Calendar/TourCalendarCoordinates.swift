//
//  TourCalendarCoordinates.swift
//  PhishQS
//
//  Split from TourCalendarView.swift for better organization
//  Contains coordinate tracking system for calendar layout
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