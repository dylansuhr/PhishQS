//
//  PhishBackground.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/23/25.
//

import SwiftUI

/// View modifier for consistent grey background styling across the app
struct PhishBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat?
    
    func body(content: Content) -> some View {
        if let radius = cornerRadius {
            content
                .background(Color.pageBackground)
                .cornerRadius(radius)
        } else {
            content
                .background(Color.pageBackground)
        }
    }
}

extension View {
    /// Apply consistent Phish app background styling
    /// - Parameter cornerRadius: Optional corner radius for rounded backgrounds
    func phishBackground(cornerRadius: CGFloat? = nil) -> some View {
        modifier(PhishBackgroundModifier(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Standard Background")
            .padding()
            .phishBackground()
        
        Text("Rounded Background")
            .padding()
            .phishBackground(cornerRadius: 12)
    }
    .padding()
}