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

    // MARK: - Adaptive Colors (Dark Mode Support)

    /// Card background - white in light mode, dark gray in dark mode
    static let cardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? .systemGray6
            : .white
    })

    /// Page background - light gray in light mode, near-black in dark mode
    static let pageBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? .systemBackground
            : .systemGray6
    })

    /// Shadow color - subtle in light mode, more visible in dark mode
    static let cardShadow = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? .black.withAlphaComponent(0.3)
            : .black.withAlphaComponent(0.05)
    })

    /// Stronger shadow for hero cards
    static let heroCardShadow = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? .black.withAlphaComponent(0.4)
            : .black.withAlphaComponent(0.08)
    })
}