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

                        HStack(spacing: 0) {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(songs.enumerated()), id: \.offset) { index, song in
                                        MostPlayedSongRowModular(song: song)

                                        if index < songs.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }

                            // Always-visible scroll track indicator
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 4)
                                .cornerRadius(2)
                                .padding(.vertical, 4)
                        }
                        .frame(height: 380)
                    }
                }
        }
    }
}