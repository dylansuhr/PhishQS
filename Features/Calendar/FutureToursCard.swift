//
//  FutureToursCard.swift
//  PhishQS
//
//  Tours Card - Shows current and future tours above the calendar
//

import SwiftUI

/// Unified tour info for display (works for both current and future tours)
struct TourDisplayInfo: Identifiable {
    let id = UUID()
    let name: String
    let totalShows: Int
    let startDate: String
    let venue: String  // First venue for color matching
}

struct ToursCard: View {
    let tours: [TourDisplayInfo]
    let onTourTapped: (String) -> Void  // Pass startDate

    var body: some View {
        // Only show if there are tours
        if !tours.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("TOUR DATES")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                // Stacked tour rows
                VStack(spacing: 8) {
                    ForEach(tours) { tour in
                        TourRow(tour: tour)
                            .onTapGesture {
                                onTourTapped(tour.startDate)
                            }
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }
}

struct TourRow: View {
    let tour: TourDisplayInfo

    private var rowColor: Color {
        // Use venueColor to match calendar spanning badges
        return venueColor(for: tour.venue)
    }

    private var showCountText: String {
        tour.totalShows == 1 ? "1 show" : "\(tour.totalShows) shows"
    }

    var body: some View {
        HStack {
            Text(tour.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            Text(showCountText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(rowColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview("Tours Card") {
    ToursCard(
        tours: [
            TourDisplayInfo(name: "2025 NYE Run", totalShows: 4, startDate: "2025-12-28", venue: "Madison Square Garden"),
            TourDisplayInfo(name: "2026 Mexico", totalShows: 4, startDate: "2026-01-28", venue: "Moon Palace"),
            TourDisplayInfo(name: "2026 Sphere", totalShows: 9, startDate: "2026-04-16", venue: "Sphere")
        ],
        onTourTapped: { _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Long Tour Name") {
    ToursCard(
        tours: [
            TourDisplayInfo(name: "2026 Summer Tour Presented by Live Nation", totalShows: 25, startDate: "2026-06-01", venue: "Some Amphitheater"),
            TourDisplayInfo(name: "2026 Sphere", totalShows: 9, startDate: "2026-04-16", venue: "Sphere")
        ],
        onTourTapped: { _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
