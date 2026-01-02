//
//  OpenersClosersCard.swift
//  PhishQS
//
//  Card displaying openers, closers, and encore statistics
//  Features tabbed navigation and shared expandable card button
//

import SwiftUI

struct OpenersClosersCard: View {
    let openersClosers: OpenersClosersStats

    @State private var selectedTab: String = "1"  // "1", "2", "3", "e"
    @State private var isExpanded: Bool = false
    @State private var animationWarmup = false

    private let threshold = 5  // Songs per column when collapsed

    // Visible tabs: always show 1, 2, e; dynamically show 3 if data exists
    private var visibleTabs: [String] {
        let alwaysShow = ["1", "2", "e"]
        let dynamic = ["3"]
        let allOrdered = ["1", "2", "3", "e"]
        let available = Set(openersClosers.keys.map { key -> String in
            let prefix = key.split(separator: "_").first.map(String.init) ?? ""
            return prefix
        })

        return allOrdered.filter { key in
            alwaysShow.contains(key) || (dynamic.contains(key) && available.contains(key))
        }
    }

    private func tabLabel(for tab: String) -> String {
        switch tab {
        case "1": return "Set 1"
        case "2": return "Set 2"
        case "3": return "Set 3"
        case "e": return "Encore"
        default: return tab
        }
    }

    // Get openers for the selected set
    private var openers: [PositionSong] {
        openersClosers["\(selectedTab)_opener"] ?? []
    }

    // Get closers for the selected set
    private var closers: [PositionSong] {
        openersClosers["\(selectedTab)_closer"] ?? []
    }

    // Get all encore songs (combined from e_all, e2_all, e3_all)
    private var encoreSongs: [PositionSong] {
        let encoreKeys = openersClosers.keys.filter { $0.hasPrefix("e") && $0.hasSuffix("_all") }
        var allEncores: [PositionSong] = []

        for key in encoreKeys.sorted() {
            if let songs = openersClosers[key] {
                allEncores.append(contentsOf: songs)
            }
        }

        return allEncores.sorted { a, b in
            if a.count != b.count {
                return a.count > b.count
            }
            return a.songName < b.songName
        }
    }

    // Calculate max items for expand button logic
    private var maxItemCount: Int {
        if selectedTab == "e" {
            return encoreSongs.count
        }
        return max(openers.count, closers.count)
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Text("OPENERS, CLOSERS, & ENCORES")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if openersClosers.isEmpty {
                    Text("No data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    // Tab picker
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(visibleTabs, id: \.self) { tab in
                            Text(tabLabel(for: tab)).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTab) { _, _ in
                        isExpanded = false
                    }

                    // Content based on selected tab
                    VStack(alignment: .leading, spacing: 8) {
                        if selectedTab == "e" {
                            // Encores: single column list
                            EncoreColumn(
                                songs: encoreSongs,
                                isExpanded: isExpanded,
                                threshold: threshold
                            )
                        } else {
                            // Set 1, 2, or 3: side-by-side openers and closers
                            HStack(alignment: .top, spacing: 16) {
                                SongListColumn(
                                    label: "Openers",
                                    songs: openers,
                                    isExpanded: isExpanded,
                                    threshold: threshold
                                )

                                SongListColumn(
                                    label: "Closers",
                                    songs: closers,
                                    isExpanded: isExpanded,
                                    threshold: threshold
                                )
                            }
                        }

                        ExpandableCardButton(
                            isExpanded: $isExpanded,
                            itemCount: maxItemCount,
                            threshold: threshold,
                            cardId: "openersClosersCard",
                            proxy: proxy,
                            scrollOnCollapse: false
                        )
                    }
                    .animation(.easeOut(duration: 0.4), value: isExpanded)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
            .id("openersClosersCard")
            .onAppear {
                if !visibleTabs.contains(selectedTab), let firstTab = visibleTabs.first {
                    selectedTab = firstTab
                }
                withAnimation(.easeInOut(duration: 0.01)) {
                    animationWarmup.toggle()
                }
            }
        }
    }
}

// MARK: - Song List Column (for Openers/Closers)

private struct SongListColumn: View {
    let label: String
    let songs: [PositionSong]
    let isExpanded: Bool
    let threshold: Int

    private var displayedSongs: [PositionSong] {
        if isExpanded || songs.count <= threshold {
            return songs
        }
        return Array(songs.prefix(threshold))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Column label
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            if songs.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                // Song rows
                ForEach(Array(displayedSongs.enumerated()), id: \.offset) { index, song in
                    if index > 0 {
                        Divider()
                            .padding(.vertical, 2)
                    }
                    SongRow(song: song)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Encore Column (single list for all encore songs)

private struct EncoreColumn: View {
    let songs: [PositionSong]
    let isExpanded: Bool
    let threshold: Int

    private var displayedSongs: [PositionSong] {
        if isExpanded || songs.count <= threshold {
            return songs
        }
        return Array(songs.prefix(threshold))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(displayedSongs.enumerated()), id: \.offset) { index, song in
                if index > 0 {
                    Divider()
                }
                SongRow(song: song)
            }
        }
    }
}

// MARK: - Song Row

private struct SongRow: View {
    let song: PositionSong

    var body: some View {
        HStack(spacing: 8) {
            // Song name
            Text(song.songName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Play count
            Text("\(song.count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.indigo)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Sample data
            OpenersClosersCard(openersClosers: [
                "1_opener": [
                    PositionSong(songName: "Carini", songId: 100, count: 5),
                    PositionSong(songName: "AC/DC Bag", songId: 101, count: 4),
                    PositionSong(songName: "Buried Alive", songId: 102, count: 3),
                    PositionSong(songName: "Mike's Song", songId: 103, count: 2),
                    PositionSong(songName: "Tweezer", songId: 104, count: 1)
                ],
                "1_closer": [
                    PositionSong(songName: "Reba", songId: 200, count: 4),
                    PositionSong(songName: "Stash", songId: 201, count: 3),
                    PositionSong(songName: "Divided Sky", songId: 202, count: 2)
                ],
                "2_opener": [
                    PositionSong(songName: "Down with Disease", songId: 300, count: 6),
                    PositionSong(songName: "Simple", songId: 301, count: 3)
                ],
                "2_closer": [
                    PositionSong(songName: "You Enjoy Myself", songId: 400, count: 5),
                    PositionSong(songName: "Slave to the Traffic Light", songId: 401, count: 4),
                    PositionSong(songName: "Harry Hood", songId: 402, count: 3),
                    PositionSong(songName: "Run Like an Antelope", songId: 403, count: 2)
                ],
                "e_all": [
                    PositionSong(songName: "Character Zero", songId: 500, count: 8),
                    PositionSong(songName: "First Tube", songId: 501, count: 6),
                    PositionSong(songName: "Julius", songId: 502, count: 4),
                    PositionSong(songName: "Possum", songId: 503, count: 3),
                    PositionSong(songName: "Golgi Apparatus", songId: 504, count: 2)
                ]
            ])

            // Empty state
            OpenersClosersCard(openersClosers: [:])
        }
        .padding()
        .background(Color(.systemGray6))
    }
}
