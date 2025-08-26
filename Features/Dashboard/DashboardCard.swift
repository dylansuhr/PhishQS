//
//  DashboardCard.swift
//  PhishQS
//
//  Created by Claude on 8/26/25.
//

import SwiftUI

/// Base card component for dashboard with consistent styling
struct DashboardCard<Content: View>: View {
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

/// Hero-sized card for featured content (spans full width)
struct HeroCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

/// Compact metric card for statistics and key numbers
struct MetricCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            content
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Hero Card Example
        HeroCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("2025-07-27")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Latest Show Content")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        
        // Metric Cards in Grid
        HStack(spacing: 16) {
            MetricCard("Longest Songs") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tweezer")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("23:45")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            MetricCard("Rarest Songs") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fluffhead")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("47 shows ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        
        Spacer()
    }
    .padding()
    .background(Color(.systemGray6))
}