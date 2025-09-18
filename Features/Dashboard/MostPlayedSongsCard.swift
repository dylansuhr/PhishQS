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
    @State private var isExpanded: Bool = false
    @State private var shouldScrollToTop: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            MetricCard("All Songs Played") {
                if songs.isEmpty {
                    Text("No play count data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(songs.prefix(isExpanded ? songs.count : 5).enumerated()), id: \.offset) { index, song in
                            MostPlayedSongRowModular(position: index + 1, song: song)

                            if index < min(songs.count, isExpanded ? songs.count : 5) - 1 {
                                Divider()
                            }
                        }

                        // Show More/Less button when there are more than 5 songs
                        if songs.count > 5 {
                            Button(action: {
                                let wasExpanded = isExpanded

                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isExpanded.toggle()

                                    // Trigger scroll when collapsing
                                    if wasExpanded {
                                        shouldScrollToTop = true
                                    }
                                }
                            }) {
                                HStack {
                                    Text(isExpanded ? "Show Less" : "Show All")
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
            .id("mostPlayedCard")
            .onChange(of: shouldScrollToTop) { _, newValue in
                if newValue && !isExpanded {
                    // Wait a moment for collapse animation to complete, then scroll
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo("mostPlayedCard", anchor: .top)
                        }
                        shouldScrollToTop = false
                    }
                }
            }
        }
    }
}