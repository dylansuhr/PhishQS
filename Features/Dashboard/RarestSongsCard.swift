//
//  RarestSongsCard.swift
//  PhishQS
//
//  Card displaying rarest songs (highest gap) from the current tour with accordion expansion
//  Extracted from TourMetricCards.swift for better organization
//

import SwiftUI
import UIKit

struct RarestSongsCard: View {
    let songs: [SongGapInfo]
    @State private var isExpanded: Bool = false

    // Pre-warmed haptic generator to mask first-tap delay
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        MetricCard("Biggest Song Gaps") {
                if songs.isEmpty {
                    Text("No gap data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(songs.prefix(isExpanded ? 10 : 3).enumerated()), id: \.offset) { index, song in
                            RarestSongRowModular(position: index + 1, song: song)

                            if index < min(songs.count, isExpanded ? 10 : 3) - 1 {
                                Divider()
                            }
                        }

                        // Show More/Less button when there are more than 3 songs
                        if songs.count > 3 {
                            HStack {
                                Text(isExpanded ? "Show Less" : "Show More")
                                    .font(.caption)
                                    .foregroundColor(.blue)

                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                hapticGenerator.impactOccurred()
                                isExpanded.toggle()
                            }
                        }
                    }
                }
        }
        .id("rarestSongsCard")
        .onAppear {
            hapticGenerator.prepare()
        }
    }
}