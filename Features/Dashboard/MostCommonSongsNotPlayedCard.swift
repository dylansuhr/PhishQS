//
//  MostCommonSongsNotPlayedCard.swift
//  PhishQS
//
//  Card displaying most common songs not played on current tour with accordion expansion
//  Extracted from TourMetricCards.swift for better organization
//

import SwiftUI
import UIKit

struct MostCommonSongsNotPlayedCard: View {
    let songs: [MostCommonSongNotPlayed]
    @State private var isExpanded: Bool = false
    @State private var shouldScrollToTop: Bool = false

    // Pre-warmed haptic generator to mask first-tap delay
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ScrollViewReader { proxy in
            MetricCard("Most Common Songs Not Played") {
                if songs.isEmpty {
                    Text("All popular songs have been played")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(songs.prefix(isExpanded ? min(songs.count, 20) : 5).enumerated()), id: \.offset) { index, song in
                            MostCommonSongNotPlayedRow(position: index + 1, song: song)

                            if index < min(songs.count, isExpanded ? min(songs.count, 20) : 5) - 1 {
                                Divider()
                            }
                        }

                        // Show More/Less button when there are more than 5 songs
                        if songs.count > 5 {
                            Button(action: {
                                // Haptic first for immediate feedback
                                hapticGenerator.impactOccurred()

                                // Defer state change to next run loop for snappier tap response
                                let wasExpanded = isExpanded
                                DispatchQueue.main.async {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isExpanded.toggle()

                                        // Trigger scroll when collapsing
                                        if wasExpanded {
                                            shouldScrollToTop = true
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    Text(isExpanded ? "Show Less" : "Show More")
                                        .font(.caption)
                                        .foregroundColor(.blue)

                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .id("mostCommonNotPlayedCard")
            .onAppear {
                hapticGenerator.prepare()
            }
            .onChange(of: shouldScrollToTop) { _, newValue in
                if newValue && !isExpanded {
                    // Wait a moment for collapse animation to complete, then scroll
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo("mostCommonNotPlayedCard", anchor: .top)
                        }
                        shouldScrollToTop = false
                    }
                }
            }
        }
    }
}

// MARK: - Row Component

/// Individual row for most common song not played display
struct MostCommonSongNotPlayedRow: View {
    let position: Int
    let song: MostCommonSongNotPlayed

    var body: some View {
        HStack(spacing: 12) {
            // Position number
            Text("\(position)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
                .frame(width: 20, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                // Song name
                Text(song.songName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    // Historical play count
                    Text("\(song.historicalPlayCount) times")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if song.originalArtist != nil && song.originalArtist != "Phish" {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(song.songTypeDisplay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
    }
}