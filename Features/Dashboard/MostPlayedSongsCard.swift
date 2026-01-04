//
//  MostPlayedSongsCard.swift
//  PhishQS
//
//  Card displaying most played songs from the current tour with accordion expansion
//  Extracted from TourMetricCards.swift for better organization
//

import SwiftUI

struct MostPlayedSongsCard: View {
    let songs: [MostPlayedSong]

    @State private var isAtBottom = false

    var body: some View {
        MetricCard("All Songs Played") {
                if songs.isEmpty {
                    Text("No play count data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        // Unique songs count indicator
                        Text("\(songs.count) unique songs")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ZStack(alignment: .bottom) {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(songs.enumerated()), id: \.offset) { index, song in
                                        MostPlayedSongRowModular(song: song)

                                        if index < songs.count - 1 {
                                            Divider()
                                        }
                                    }

                                    // Bottom detector
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear { isAtBottom = true }
                                            .onDisappear { isAtBottom = false }
                                    }
                                    .frame(height: 1)
                                }
                                .padding(.vertical, 4)
                            }

                            // Gradient fade to indicate scrollable content
                            if !isAtBottom {
                                LinearGradient(
                                    colors: [Color.cardBackground.opacity(0), Color.cardBackground],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 30)
                                .allowsHitTesting(false)
                            }
                        }
                        .frame(height: 380)
                    }
                }
        }
    }
}