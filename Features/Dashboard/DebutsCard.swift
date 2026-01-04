//
//  DebutsCard.swift
//  PhishQS
//
//  Card displaying songs that debuted during the current tour
//  Shows top 3 debuts by default, expandable to 10
//

import SwiftUI

struct DebutsCard: View {
    let debuts: DebutsStats
    @State private var isExpanded: Bool = false
    @State private var animationWarmup = false

    var body: some View {
        ScrollViewReader { proxy in
            MetricCard("Tour Debuts") {
                if debuts.songs.isEmpty {
                    // Empty state
                    Text(emptyStateText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(debuts.songs.prefix(isExpanded ? 10 : 3).enumerated()), id: \.offset) { index, debut in
                            DebutRowModular(position: index + 1, debut: debut)

                            if index < min(debuts.songs.count, isExpanded ? 10 : 3) - 1 {
                                Divider()
                            }
                        }

                        ExpandableCardButton(
                            isExpanded: $isExpanded,
                            itemCount: debuts.songs.count,
                            threshold: 3,
                            cardId: "debutsCard",
                            proxy: proxy
                        )
                    }
                    .animation(.easeOut(duration: 0.4), value: isExpanded)
                }
            }
            .id("debutsCard")
            .onAppear {
                withAnimation(.easeInOut(duration: 0.01)) {
                    animationWarmup.toggle()
                }
            }
        }
    }

    private var emptyStateText: String {
        if let positionText = debuts.tourPositionText {
            return "No debuts through \(positionText)"
        }
        return "No debuts yet this tour"
    }
}

/// Row component for debut songs - purple accent color
struct DebutRowModular: View {
    let position: Int
    let debut: DebutInfo

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Position number
            Text("\(position)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
                .frame(width: 20, alignment: .center)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 2) {
                // Song name
                Text(debut.songName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Original artist (for covers)
                if let artistText = debut.artistDisplayText {
                    Text(artistText)
                        .font(.caption2)
                        .foregroundColor(.purple.opacity(0.8))
                        .italic()
                }

                // Date
                Text(debut.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Venue
                if let venueText = debut.venueDisplayText {
                    Text(venueText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                // City, State
                if let cityStateText = debut.cityStateText {
                    Text(cityStateText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            // Debut badge - fixed size, aligned to top
            Text("DEBUT")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(6)
                .fixedSize()
                .padding(.top, 4)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Sample with debuts
        let sampleDebuts = DebutsStats(
            songs: [
                DebutInfo(
                    id: 1, songId: 1, songName: "Cream",
                    footnote: "Phish debut.", showDate: "2025-12-31",
                    venue: "Madison Square Garden",
                    venueRun: VenueRun(venue: "Madison Square Garden", city: "New York", state: "NY", nightNumber: 4, totalNights: 4, showDates: ["2025-12-31"]),
                    city: "New York", state: "NY", tourPosition: nil,
                    originalArtist: "Prince and the New Power Generation"
                ),
                DebutInfo(
                    id: 2, songId: 2, songName: "Sincere",
                    footnote: "Phish debut.", showDate: "2025-12-31",
                    venue: "Madison Square Garden",
                    venueRun: VenueRun(venue: "Madison Square Garden", city: "New York", state: "NY", nightNumber: 4, totalNights: 4, showDates: ["2025-12-31"]),
                    city: "New York", state: "NY", tourPosition: nil,
                    originalArtist: "The Buffalo Bills"
                ),
                DebutInfo(
                    id: 3, songId: 3, songName: "Original Song",
                    footnote: "Phish debut.",
                    showDate: "2025-06-28",
                    venue: "SPAC",
                    venueRun: nil,
                    city: "Saratoga Springs", state: "NY", tourPosition: nil,
                    originalArtist: "Phish"
                )
            ],
            latestShowDate: "2025-12-31",
            latestShowVenue: "Madison Square Garden",
            latestShowCity: "New York",
            latestShowState: "NY",
            latestShowVenueRun: VenueRun(venue: "Madison Square Garden", city: "New York", state: "NY", nightNumber: 4, totalNights: 4, showDates: ["2025-12-28", "2025-12-29", "2025-12-30", "2025-12-31"]),
            latestShowTourPosition: TourShowPosition(tourName: "2025 NYE Run", showNumber: 4, totalShows: 4, tourYear: "2025")
        )

        DebutsCard(debuts: sampleDebuts)

        // Empty state
        let emptyDebuts = DebutsStats(
            songs: [],
            latestShowDate: "2025-07-20",
            latestShowVenue: "Saratoga Performing Arts Center",
            latestShowCity: "Saratoga Springs",
            latestShowState: "NY",
            latestShowVenueRun: VenueRun(venue: "Saratoga Performing Arts Center", city: "Saratoga Springs", state: "NY", nightNumber: 2, totalNights: 2, showDates: ["2025-07-19", "2025-07-20"]),
            latestShowTourPosition: TourShowPosition(tourName: "2025 Summer", showNumber: 10, totalShows: 23, tourYear: "2025")
        )

        DebutsCard(debuts: emptyDebuts)

        Spacer()
    }
    .padding()
    .background(Color.pageBackground)
}
