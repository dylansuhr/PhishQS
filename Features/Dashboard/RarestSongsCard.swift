//
//  RarestSongsCard.swift
//  PhishQS
//
//  Card displaying rarest songs (highest gap) from the current tour with accordion expansion
//  Extracted from TourMetricCards.swift for better organization
//

import SwiftUI

struct RarestSongsCard: View {
    let songs: [SongGapInfo]
    @State private var isExpanded: Bool = false
    @State private var animationWarmup = false  // Pre-warm animation system

    var body: some View {
        ScrollViewReader { proxy in
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

                        ExpandableCardButton(
                            isExpanded: $isExpanded,
                            itemCount: songs.count,
                            threshold: 3,
                            cardId: "rarestSongsCard",
                            proxy: proxy
                        )
                    }
                    .animation(.easeOut(duration: 0.4), value: isExpanded)
                }
        }
        .id("rarestSongsCard")
        .onAppear {
            // Pre-warm animation system in same view context
            withAnimation(.easeInOut(duration: 0.01)) {
                animationWarmup.toggle()
            }
        }
        }
    }
}