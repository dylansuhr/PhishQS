//
//  DashboardGrid.swift
//  PhishQS
//
//  Created by Claude on 8/26/25.
//

import SwiftUI

/// Responsive grid layout for dashboard cards
struct DashboardGrid<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                content
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }
}

/// Dashboard grid item that can specify column span
struct DashboardGridItem<Content: View>: View {
    let content: Content
    let columnSpan: Int
    
    init(columnSpan: Int = 1, @ViewBuilder content: () -> Content) {
        self.columnSpan = columnSpan
        self.content = content()
    }
    
    var body: some View {
        content
    }
}

/// Adaptive two-column grid for metric cards
struct MetricGrid<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(columns: adaptiveColumns, spacing: 16) {
            content
        }
    }
    
    private var adaptiveColumns: [SwiftUI.GridItem] {
        [
            SwiftUI.GridItem(.flexible(), spacing: 8),
            SwiftUI.GridItem(.flexible(), spacing: 8)
        ]
    }
}

/// Dashboard section with optional header
struct DashboardSection<Content: View>: View {
    let title: String?
    let content: Content
    
    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
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
                    .padding(.horizontal, 4)
            }
            
            content
        }
    }
}

#Preview {
    DashboardGrid {
        // Hero Section
        DashboardSection {
            HeroCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("2025-07-27")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Broadview Stage at SPAC")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        BadgeView(text: "N3/3", style: .blue)
                        BadgeView(text: "23/23", style: .blue)
                    }
                }
            }
        }
        
        // Statistics Section
        DashboardSection("Tour Statistics") {
            HStack(spacing: 16) {
                MetricCard("Longest Songs") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(1...3), id: \.self) { index in
                            HStack {
                                Text("\(index)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                    .frame(width: 16)
                                
                                Text("Song Name")
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("12:34")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            if index < 3 { Divider() }
                        }
                    }
                }
                
                MetricCard("Rarest Songs") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(1...3), id: \.self) { index in
                            HStack {
                                Text("\(index)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                    .frame(width: 16)
                                
                                Text("Rare Song")
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("\(index * 10) ago")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            
                            if index < 3 { Divider() }
                        }
                    }
                }
            }
        }
        
        // Future expandable section
        DashboardSection("More Metrics") {
            HStack(spacing: 16) {
                MetricCard("Tour Overview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summer Tour 2025")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("23")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("Shows")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("147")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Songs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                MetricCard("Next Show") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upcoming")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("Check tour dates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}