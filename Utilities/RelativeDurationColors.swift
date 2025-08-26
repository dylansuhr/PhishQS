//
//  RelativeDurationColors.swift
//  PhishQS
//
//  Created by Claude on 8/24/25.
//

import SwiftUI

/// Utility for calculating relative color scales for song durations within a setlist
/// Each show has its own color scale: shortest song = green, longest song = red
struct RelativeDurationColors {
    
    /// Calculate color for a song duration relative to other songs in the same setlist using percentile-based distribution
    /// - Parameters:
    ///   - duration: Duration of the current song in seconds
    ///   - allDurations: All song durations in the setlist
    /// - Returns: Color from green (shortest) to red (longest) based on percentile rank
    static func colorForDuration(_ duration: Int, in allDurations: [Int]) -> Color {
        guard !allDurations.isEmpty else { return .secondary }
        
        // Handle edge case: only one song or all songs same duration
        guard allDurations.count > 1 else { return .green }
        
        // Sort durations to calculate percentile rank
        let sortedDurations = allDurations.sorted()
        
        // Find how many songs are shorter than or equal to current duration
        let songsAtOrBelow = sortedDurations.filter { $0 <= duration }.count
        
        // Calculate percentile rank (0.0 = shortest, 1.0 = longest)
        let percentile = Double(songsAtOrBelow - 1) / Double(sortedDurations.count - 1)
        
        return interpolateGreenToRed(percentage: percentile)
    }
    
    /// Create a color interpolation from green (0%) to red (100%) through yellow/orange
    /// - Parameter percentage: Value from 0.0 to 1.0
    /// - Returns: Bold, readable color along the green → yellow → orange → red spectrum
    private static func interpolateGreenToRed(percentage: Double) -> Color {
        // Clamp percentage to valid range
        let clampedPercentage = max(0.0, min(1.0, percentage))
        
        // Use HSB color space for smooth gradient with bold, readable colors
        // Hue: 120° (green) → 0° (red)
        // Higher saturation and optimized brightness for bold, readable text
        
        let hue = 120.0 * (1.0 - clampedPercentage) / 360.0  // 120° to 0° in SwiftUI's 0-1 range
        let saturation = 0.85  // High saturation for bold, vibrant colors
        let brightness = 0.65  // Lower brightness for better contrast against light backgrounds
        
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    
    /// Get a neutral color for songs without duration data
    static var unavailableColor: Color {
        return .secondary
    }
}