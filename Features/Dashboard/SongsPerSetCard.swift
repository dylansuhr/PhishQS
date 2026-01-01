//
//  SongsPerSetCard.swift
//  PhishQS
//
//  Card displaying songs per set statistics - min/max songs for each set type
//

import SwiftUI

struct SongsPerSetCard: View {
    let setSongStats: [String: SetSongStats]

    // Ordered set keys for display
    private var orderedSetKeys: [String] {
        let order = ["1", "2", "3", "e", "e2", "e3"]
        return setSongStats.keys.sorted { key1, key2 in
            let index1 = order.firstIndex(of: key1) ?? 999
            let index2 = order.firstIndex(of: key2) ?? 999
            return index1 < index2
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("SONGS PER SET")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            if setSongStats.isEmpty {
                Text("No set data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(orderedSetKeys, id: \.self) { setKey in
                        if let stats = setSongStats[setKey] {
                            SetTypeSection(setKey: setKey, stats: stats)

                            if setKey != orderedSetKeys.last {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Set Type Section

private struct SetTypeSection: View {
    let setKey: String
    let stats: SetSongStats

    private var setDisplayName: String {
        switch setKey.lowercased() {
        case "1": return "Set 1"
        case "2": return "Set 2"
        case "3": return "Set 3"
        case "e": return "Encore"
        case "e2": return "Encore 2"
        case "e3": return "Encore 3"
        default: return "Set \(setKey)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Set label
            Text(setDisplayName.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            // Min and Max side by side
            HStack(alignment: .top, spacing: 16) {
                ExtremeColumn(
                    label: "Shortest",
                    count: stats.min.count,
                    shows: stats.min.shows
                )

                ExtremeColumn(
                    label: "Longest",
                    count: stats.max.count,
                    shows: stats.max.shows
                )
            }
        }
    }
}

// MARK: - Extreme Column (Shortest/Longest)

private struct ExtremeColumn: View {
    let label: String
    let count: Int
    let shows: [SetSongShow]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Count
            Text("\(count) \(count == 1 ? "song" : "songs")")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.indigo)

            // Shows (handle ties)
            ForEach(Array(shows.enumerated()), id: \.offset) { index, show in
                if index > 0 {
                    Divider()
                        .padding(.vertical, 2)
                }
                ShowInfoView(show: show)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Show Info View

private struct ShowInfoView: View {
    let show: SetSongShow

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Date
            Text(show.formattedDate)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Venue with run
            Text(show.venueDisplayText)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // City, State
            Text(show.cityStateText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Sample data
            SongsPerSetCard(setSongStats: [
                "1": SetSongStats(
                    min: SetSongExtreme(count: 7, shows: [
                        SetSongShow(date: "2025-12-29", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N2")
                    ]),
                    max: SetSongExtreme(count: 11, shows: [
                        SetSongShow(date: "2025-09-13", venue: "Dick's Sporting Goods Park", city: "Commerce City", state: "CO", venueRun: nil)
                    ])
                ),
                "2": SetSongStats(
                    min: SetSongExtreme(count: 8, shows: [
                        SetSongShow(date: "2025-12-28", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N1")
                    ]),
                    max: SetSongExtreme(count: 12, shows: [
                        SetSongShow(date: "2025-12-30", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N3")
                    ])
                ),
                "e": SetSongStats(
                    min: SetSongExtreme(count: 1, shows: [
                        SetSongShow(date: "2025-12-28", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N1"),
                        SetSongShow(date: "2025-12-30", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N3")
                    ]),
                    max: SetSongExtreme(count: 4, shows: [
                        SetSongShow(date: "2025-12-29", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N2")
                    ])
                )
            ])

            // Empty state
            SongsPerSetCard(setSongStats: [:])
        }
        .padding()
        .background(Color(.systemGray6))
    }
}
