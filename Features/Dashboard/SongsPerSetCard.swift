//
//  SongsPerSetCard.swift
//  PhishQS
//
//  Card displaying songs per set statistics - min/max songs for each set type
//  Features tabbed navigation and shared expandable card button
//

import SwiftUI

struct SongsPerSetCard: View {
    let setSongStats: [String: SetSongStats]

    @State private var selectedSetKey: String = "1"
    @State private var isExpanded: Bool = false
    @State private var animationWarmup = false

    private let threshold = 2  // Shows per column when collapsed

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

    // Calculate max items across both columns for expand button logic
    private var maxItemCount: Int {
        guard let stats = setSongStats[selectedSetKey] else { return 0 }
        return max(stats.min.shows.count, stats.max.shows.count)
    }

    var body: some View {
        ScrollViewReader { proxy in
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
                        isExpanded = false
                    }

                    // Content for selected set
                    if let stats = setSongStats[selectedSetKey] {
                        VStack(alignment: .leading, spacing: 0) {
                            // Header row: Labels
                            HStack(spacing: 0) {
                                Text("Shortest")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Divider()
                                    .frame(height: 16)

                                Text("Longest")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 12)
                            }
                            .padding(.bottom, 4)

                            // Count row
                            HStack(spacing: 0) {
                                Text("\(stats.min.count) \(stats.min.count == 1 ? "song" : "songs")")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.indigo)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Divider()
                                    .frame(height: 24)

                                Text("\(stats.max.count) \(stats.max.count == 1 ? "song" : "songs")")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.indigo)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 12)
                            }

                            // Full-width divider under counts
                            Divider()
                                .padding(.vertical, 8)

                            // Shows grid
                            ShowsGridView(
                                minShows: stats.min.shows,
                                maxShows: stats.max.shows,
                                isExpanded: isExpanded,
                                threshold: threshold
                            )

                            ExpandableCardButton(
                                isExpanded: $isExpanded,
                                itemCount: maxItemCount,
                                threshold: threshold,
                                cardId: "songsPerSetCard",
                                proxy: proxy,
                                scrollOnCollapse: false
                            )
                        }
                        .animation(.easeOut(duration: 0.4), value: isExpanded)
                    } else {
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
            .id("songsPerSetCard")
            .onAppear {
                withAnimation(.easeInOut(duration: 0.01)) {
                    animationWarmup.toggle()
                }
            }
        }
    }
}

// MARK: - Shows Grid View

private struct ShowsGridView: View {
    let minShows: [SetSongShow]
    let maxShows: [SetSongShow]
    let isExpanded: Bool
    let threshold: Int

    private var displayedMinShows: [SetSongShow] {
        if isExpanded || minShows.count <= threshold {
            return minShows
        }
        return Array(minShows.prefix(threshold))
    }

    private var displayedMaxShows: [SetSongShow] {
        if isExpanded || maxShows.count <= threshold {
            return maxShows
        }
        return Array(maxShows.prefix(threshold))
    }

    private var maxRowCount: Int {
        max(displayedMinShows.count, displayedMaxShows.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<maxRowCount, id: \.self) { index in
                // Row divider (except before first row)
                if index > 0 {
                    Divider()
                        .padding(.vertical, 8)
                }

                // Row content
                HStack(alignment: .top, spacing: 0) {
                    // Left column (min/shortest)
                    if index < displayedMinShows.count {
                        ShowInfoView(show: displayedMinShows[index])
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }

                    // Vertical divider
                    Divider()
                        .padding(.horizontal, 6)

                    // Right column (max/longest)
                    if index < displayedMaxShows.count {
                        ShowInfoView(show: displayedMaxShows[index])
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
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
