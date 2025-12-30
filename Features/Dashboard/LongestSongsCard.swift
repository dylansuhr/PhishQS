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

                        // Show More/Less button when there are more than 3 songs
                        if songs.count > 3 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isExpanded.toggle()

                                    // Auto-scroll to card when collapsing to prevent blank screen
                                    if !isExpanded {
                                        // Calculate adaptive timing based on number of items being collapsed
                                        let itemsToCollapse = max(0, min(songs.count, 10) - 3)
                                        let baseDelay: Double = 0.2
                                        let itemDelay: Double = 0.005 // 5ms per item
                                        let adaptiveDelay = baseDelay + (Double(itemsToCollapse) * itemDelay)
                                        let maxDelay: Double = 0.6 // Cap at 600ms for very large lists
                                        let finalDelay = min(adaptiveDelay, maxDelay)

                                        DispatchQueue.main.asyncAfter(deadline: .now() + finalDelay) {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                proxy.scrollTo("longestSongsCard", anchor: .top)
                                            }
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
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
            .id("longestSongsCard")
            .sheet(isPresented: $showDataPopup) {
                ShowDataAvailabilityPopup(
                    showDurationAvailability: showDurationAvailability,
                    isPresented: $showDataPopup
                )
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