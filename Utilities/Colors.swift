//
//  Colors.swift
//  PhishQS
//
//  Created by Claude on 9/14/25.
//

import SwiftUI

extension Color {
    /// Primary theme color - Phish blue used throughout the app
    /// RGB(39, 72, 134) / #274886 - Deep blue for branding consistency
    static let phishBlue = Color(red: 0.153, green: 0.282, blue: 0.525)

    /// Navigation bar and header color (same as primary theme)
    /// Using phishBlue for consistency across the app
    static let appHeaderBlue = phishBlue
}