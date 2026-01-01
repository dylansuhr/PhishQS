//
//  SongsPerSetCard.swift
//  PhishQS
//
//  Card displaying songs per set statistics - min/max songs for each set type
//  Features tabbed navigation and collapsible tie lists
//

import SwiftUI
import UIKit

struct SongsPerSetCard: View {
    let setSongStats: [String: SetSongStats]

    @State private var selectedSetKey: String = "1"
    @State private var minExpanded: Bool = false
    @State private var maxExpanded: Bool = false

    // Visible tabs: always show 1, 2, e; dynamically show 3, e2, e3 if data exists
    private var visibleSetKeys: [String] {
        let alwaysShow = ["1", "2", "e"]
        let dynamic = ["3", "e2", "e3"]
        let allOrdered = ["1", "2", "3", "e", "e2", "e3"]
        let available = Set(setSongStats.keys)

        return allOrdered.filter { key in
            alwaysShow.contains(key) || (dynamic.contains(key) && available.contains(key))
        }
    }

    private func tabLabel(for key: String) -> String {
        switch key.lowercased() {
        case "1": return "Set 1"
        case "2": return "Set 2"
        case "3": return "Set 3"
        case "e": return "Encore"
        case "e2": return "Enc 2"
        case "e3": return "Enc 3"
        default: return "Set \(key)"
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
                // Tab picker
                Picker("Set", selection: $selectedSetKey) {
                    ForEach(visibleSetKeys, id: \.self) { key in
                        Text(tabLabel(for: key)).tag(key)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedSetKey) { _, _ in
                    // Reset expand states when switching tabs
                    minExpanded = false
                    maxExpanded = false
                }

                // Content for selected set
                if let stats = setSongStats[selectedSetKey] {
                    HStack(alignment: .top, spacing: 16) {
                        ExtremeColumn(
                            label: "Shortest",
                            count: stats.min.count,
                            shows: stats.min.shows,
                            isExpanded: $minExpanded
                        )

                        ExtremeColumn(
                            label: "Longest",
                            count: stats.max.count,
                            shows: stats.max.shows,
                            isExpanded: $maxExpanded
                        )
                    }
                    .animation(.easeOut(duration: 0.4), value: minExpanded)
                    .animation(.easeOut(duration: 0.4), value: maxExpanded)
                } else {
                    // No data for selected set (shouldn't happen for always-show tabs, but handle gracefully)
                    Text("No data available for this set")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Extreme Column (Shortest/Longest)

private struct ExtremeColumn: View {
    let label: String
    let count: Int
    let shows: [SetSongShow]
    @Binding var isExpanded: Bool

    private let threshold = 2
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    private var displayedShows: [SetSongShow] {
        if isExpanded || shows.count <= threshold {
            return shows
        }
        return Array(shows.prefix(threshold))
    }

    private var hasMoreShows: Bool {
        shows.count > threshold
    }

    private var remainingCount: Int {
        shows.count - threshold
    }

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

            // Shows (with collapsible behavior)
            ForEach(Array(displayedShows.enumerated()), id: \.offset) { index, show in
                if index > 0 {
                    Divider()
                        .padding(.vertical, 2)
                }
                ShowInfoView(show: show)
            }

            // Show More/Less button
            if hasMoreShows {
                HStack {
                    Text(isExpanded ? "Show Less" : "+ \(remainingCount) more")
                        .font(.caption)
                        .foregroundColor(.blue)

                    if isExpanded {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    hapticGenerator.impactOccurred()
                    isExpanded.toggle()
                }
                .onAppear {
                    hapticGenerator.prepare()
                }
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
            // Sample data with ties
            SongsPerSetCard(setSongStats: [
                "1": SetSongStats(
                    min: SetSongExtreme(count: 7, shows: [
                        SetSongShow(date: "2025-12-29", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N2"),
                        SetSongShow(date: "2025-12-28", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N1"),
                        SetSongShow(date: "2025-12-30", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N3"),
                        SetSongShow(date: "2025-09-01", venue: "Dick's Sporting Goods Park", city: "Commerce City", state: "CO", venueRun: "N1")
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
                "3": SetSongStats(
                    min: SetSongExtreme(count: 5, shows: [
                        SetSongShow(date: "2025-12-31", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N4")
                    ]),
                    max: SetSongExtreme(count: 5, shows: [
                        SetSongShow(date: "2025-12-31", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N4")
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
