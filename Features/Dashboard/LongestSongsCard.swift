//
//  LongestSongsCard.swift
//  PhishQS
//
//  Card displaying longest songs from the current tour with accordion expansion
//  Extracted from TourMetricCards.swift for better organization
//

import SwiftUI

struct LongestSongsCard: View {
    let songs: [TrackDuration]
    let showDurationAvailability: [ShowDurationAvailability]  // Single source of truth from statistics
    @State private var isExpanded: Bool = false
    @State private var showDataPopup: Bool = false
    @State private var animationWarmup = false  // Pre-warm animation system


    var body: some View {
        ScrollViewReader { proxy in
        VStack(alignment: .leading, spacing: 12) {
                // Custom header with data coverage info
                VStack(alignment: .leading, spacing: 4) {
                    Text("LONGEST SONGS")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    HStack {
                        Text(dataCoverageText)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: {
                            showDataPopup = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()
                    }
                }

                // Content
                if songs.isEmpty {
                    Text("Still waiting...for Phish.in song length data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(songs.prefix(isExpanded ? 10 : 3).enumerated()), id: \.offset) { index, song in
                            LongestSongRowModular(position: index + 1, song: song)

                            if index < min(songs.count, isExpanded ? 10 : 3) - 1 {
                                Divider()
                            }
                        }

                        ExpandableCardButton(
                            isExpanded: $isExpanded,
                            itemCount: songs.count,
                            threshold: 3,
                            cardId: "longestSongsCard",
                            proxy: proxy
                        )
                    }
                    .animation(.easeOut(duration: 0.4), value: isExpanded)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: .cardShadow, radius: 3, x: 0, y: 2)
            .id("longestSongsCard")
            .onAppear {
                // Pre-warm animation system in same view context
                withAnimation(.easeInOut(duration: 0.01)) {
                    animationWarmup.toggle()
                }
            }
            .sheet(isPresented: $showDataPopup) {
                LazySheetContent {
                    ShowDataAvailabilityPopup(
                        showDurationAvailability: showDurationAvailability,
                        isPresented: $showDataPopup
                    )
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var dataCoverageText: String {
        let withDurations = showDurationAvailability.filter { $0.durationsAvailable }.count
        let total = showDurationAvailability.count
        return "data from \(withDurations)/\(total) shows"
    }
}