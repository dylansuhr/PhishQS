//
//  TourMetricCards.swift
//  PhishQS
//
//  Created by Claude on 8/26/25.
//

import SwiftUI

/// Card displaying longest songs from the current tour with accordion expansion
struct LongestSongsCard: View {
    let songs: [TrackDuration]
    @State private var isExpanded: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            MetricCard("Longest Songs") {
                if songs.isEmpty {
                    Text("Still waiting...for Phish.in song length data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(songs.prefix(isExpanded ? 10 : 3).enumerated()), id: \.offset) { index, song in
                            LongestSongRow(position: index + 1, song: song)

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
            .id("longestSongsCard")
        }
    }
}

/// Individual row for longest song display (Legacy - will be deprecated)
/// Use LongestSongRowModular from SharedUIComponents for new implementations
struct LongestSongRow: View {
    let position: Int
    let song: TrackDuration
    
    var body: some View {
        // Use new modular component
        LongestSongRowModular(position: position, song: song)
    }
}

/// Card displaying rarest songs (highest gap) from the current tour with accordion expansion
struct RarestSongsCard: View {
    let songs: [SongGapInfo]
    @State private var isExpanded: Bool = false

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
                            RarestSongRow(position: index + 1, song: song)

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
                                                proxy.scrollTo("rarestSongsCard", anchor: .top)
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
            .id("rarestSongsCard")
        }
    }
}

/// Individual row for rarest song display (Legacy - will be deprecated)
/// Use RarestSongRowModular from SharedUIComponents for new implementations
struct RarestSongRow: View {
    let position: Int
    let song: SongGapInfo
    
    var body: some View {
        // Use new modular component
        RarestSongRowModular(position: position, song: song)
    }
}

/// Card displaying most played songs from the current tour with accordion expansion
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
                            MostPlayedSongRow(position: index + 1, song: song)

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

/// Individual row for most played song display (Legacy - will be deprecated)
/// Use MostPlayedSongRowModular from SharedUIComponents for new implementations
struct MostPlayedSongRow: View {
    let position: Int
    let song: MostPlayedSong
    
    var body: some View {
        // Use new modular component
        MostPlayedSongRowModular(position: position, song: song)
    }
}

/// Combined statistics cards in a vertical layout
struct TourStatisticsCards: View {
    let statistics: TourSongStatistics?

    var body: some View {
        if let stats = statistics, stats.hasData {
            VStack(alignment: .leading, spacing: 16) {
                LongestSongsCard(songs: stats.longestSongs)
                RarestSongsCard(songs: stats.rarestSongs)
                MostPlayedSongsCard(songs: stats.mostPlayedSongs)
            }
        }
    }
}

/// Example metric card for future features
struct TourOverviewCard: View {
    let tourName: String?
    let showCount: Int?
    let totalSongs: Int?
    
    var body: some View {
        MetricCard("Tour Overview") {
            VStack(alignment: .leading, spacing: 12) {
                if let tourName = tourName {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Tour")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(tourName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                HStack {
                    if showCount != nil {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(showCount!)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("Shows")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if totalSongs != nil {
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(totalSongs!)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text("Unique Songs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Sample longest songs
        let sampleVenueRun = TourConfig.sampleVenueRun
        let sampleTourPosition = TourConfig.sampleTourPosition
        
        let sampleLongestSongs = [
            TrackDuration(
                id: "1", songName: "Tweezer", songId: 627, durationSeconds: 1383,
                showDate: "2025-07-27", setNumber: "2", venue: "Madison Square Garden",
                venueRun: sampleVenueRun, city: "New York", state: "NY", 
                tourPosition: sampleTourPosition
            ),
            TrackDuration(
                id: "2", songName: "You Enjoy Myself", songId: 692, durationSeconds: 1037,
                showDate: "2025-07-26", setNumber: "1", venue: "Broadview Stage at SPAC",
                venueRun: nil, city: "Saratoga Springs", state: "NY", 
                tourPosition: TourShowPosition(
                    tourName: TourConfig.currentTourName, showNumber: 3, 
                    totalShows: TourConfig.currentTourTotalShows, tourYear: TourConfig.currentTourYear
                )
            ),
            TrackDuration(
                id: "3", songName: "Ghost", songId: 294, durationSeconds: 947,
                showDate: "2025-07-25", setNumber: "2", venue: "Alpine Valley Music Theatre",
                venueRun: nil, city: "East Troy", state: "WI", 
                tourPosition: TourShowPosition(
                    tourName: TourConfig.currentTourName, showNumber: 2,
                    totalShows: TourConfig.currentTourTotalShows, tourYear: TourConfig.currentTourYear
                )
            )
        ]
        
        // Sample rarest songs with tour venue information  
        let sampleRarestSongs = [
            SongGapInfo(
                songId: 251, songName: "Fluffhead", gap: 47, lastPlayed: "2023-08-15", 
                timesPlayed: 87, tourVenue: "Madison Square Garden", tourVenueRun: sampleVenueRun,
                tourDate: "2025-07-27", tourCity: "New York", tourState: "NY", 
                tourPosition: sampleTourPosition
            ),
            SongGapInfo(
                songId: 342, songName: "Icculus", gap: 23, lastPlayed: "2024-02-18",
                timesPlayed: 45, tourVenue: "Broadview Stage at SPAC", tourVenueRun: nil,
                tourDate: "2025-07-26", tourCity: "Saratoga Springs", tourState: "NY", 
                tourPosition: TourShowPosition(
                    tourName: TourConfig.currentTourName, showNumber: 3,
                    totalShows: TourConfig.currentTourTotalShows, tourYear: TourConfig.currentTourYear
                )
            ),
            SongGapInfo(
                songId: 398, songName: "McGrupp", gap: 15, lastPlayed: "2024-07-12",
                timesPlayed: 62, tourVenue: "Alpine Valley Music Theatre", tourVenueRun: nil,
                tourDate: "2025-07-25", tourCity: "East Troy", tourState: "WI", 
                tourPosition: TourShowPosition(
                    tourName: TourConfig.currentTourName, showNumber: 2,
                    totalShows: TourConfig.currentTourTotalShows, tourYear: TourConfig.currentTourYear
                )
            )
        ]
        
        // Sample most played songs
        let sampleMostPlayedSongs = [
            MostPlayedSong(songId: 473, songName: "You Enjoy Myself", playCount: 8),
            MostPlayedSong(songId: 627, songName: "Tweezer", playCount: 7),
            MostPlayedSong(songId: 294, songName: "Ghost", playCount: 6)
        ]
        
        TourStatisticsCards(
            statistics: TourSongStatistics(
                longestSongs: sampleLongestSongs,
                rarestSongs: sampleRarestSongs,
                mostPlayedSongs: sampleMostPlayedSongs,
                tourName: TourConfig.currentTourName
            )
        )
        
        TourOverviewCard(
            tourName: TourConfig.currentTourName,
            showCount: TourConfig.samplePlayedShows,
            totalSongs: 147
        )
        
        Spacer()
    }
    .padding()
    .background(Color(.systemGray6))
}