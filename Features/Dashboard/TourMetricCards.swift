//
//  TourMetricCards.swift
//  PhishQS
//
//  Created by Claude on 8/26/25.
//

import SwiftUI

/// Card displaying top 3 longest songs from the current tour
struct LongestSongsCard: View {
    let songs: [TrackDuration]
    
    var body: some View {
        MetricCard("Longest Songs") {
            if songs.isEmpty {
                Text("No duration data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(songs.prefix(3).enumerated()), id: \.offset) { index, song in
                        LongestSongRow(position: index + 1, song: song)
                        
                        if index < min(songs.count, 3) - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

/// Individual row for longest song display
struct LongestSongRow: View {
    let position: Int
    let song: TrackDuration
    
    var body: some View {
        HStack(spacing: 12) {
            // Position number
            Text("\(position)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.songName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(DateUtilities.formatDateForDisplay(song.showDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // Show venue and night information if available
                if let venueText = song.venueDisplayText {
                    Text(venueText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(1)
            
            Spacer(minLength: 8)
            
            Text(song.formattedDuration)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .layoutPriority(2)
        }
    }
}

/// Card displaying top 3 rarest songs (highest gap) from the current tour
struct RarestSongsCard: View {
    let songs: [SongGapInfo]
    
    var body: some View {
        MetricCard("Rarest Songs") {
            if songs.isEmpty {
                Text("No gap data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(songs.prefix(3).enumerated()), id: \.offset) { index, song in
                        RarestSongRow(position: index + 1, song: song)
                        
                        if index < min(songs.count, 3) - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

/// Individual row for rarest song display
struct RarestSongRow: View {
    let position: Int
    let song: SongGapInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // Position number
            Text("\(position)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
                .frame(width: 20, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.songName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Show current show date and venue in one line: "2025-07-27 - Broadview Stage at SPAC"
                if let tourDate = song.tourDate, let tourVenue = song.tourVenue {
                    Text("\(DateUtilities.formatDateForDisplay(tourDate)) - \(tourVenue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if let tourDate = song.tourDate {
                    Text(DateUtilities.formatDateForDisplay(tourDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if let tourVenue = song.tourVenue {
                    Text(tourVenue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(1)
            
            Spacer(minLength: 8)
            
            VStack(alignment: .trailing, spacing: 2) {
                // Gap number
                if song.gap == 0 {
                    Text("Recent")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                } else {
                    Text("\(song.gap)")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                // Last played date (the date that created this gap)
                if let historicalDate = song.historicalLastPlayed {
                    Text(DateUtilities.formatDateForDisplay(historicalDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if song.gap > 0 {
                    Text(DateUtilities.formatDateForDisplay(song.lastPlayed))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(2)
        }
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
        let sampleVenueRun = VenueRun(venue: "Madison Square Garden", city: "New York", state: "NY", nightNumber: 3, totalNights: 4, showDates: ["2025-07-25", "2025-07-26", "2025-07-27", "2025-07-28"])
        
        let sampleLongestSongs = [
            TrackDuration(id: "1", songName: "Tweezer", songId: 627, durationSeconds: 1383, showDate: "2025-07-27", setNumber: "2", venue: "Madison Square Garden", venueRun: sampleVenueRun),
            TrackDuration(id: "2", songName: "You Enjoy Myself", songId: 692, durationSeconds: 1037, showDate: "2025-07-26", setNumber: "1", venue: "Broadview Stage at SPAC", venueRun: nil),
            TrackDuration(id: "3", songName: "Ghost", songId: 294, durationSeconds: 947, showDate: "2025-07-25", setNumber: "2", venue: "Alpine Valley Music Theatre", venueRun: nil)
        ]
        
        // Sample rarest songs with tour venue information
        let sampleRarestSongs = [
            SongGapInfo(songId: 251, songName: "Fluffhead", gap: 47, lastPlayed: "2023-08-15", timesPlayed: 87, tourVenue: "Madison Square Garden", tourVenueRun: sampleVenueRun, tourDate: "2025-07-27"),
            SongGapInfo(songId: 342, songName: "Icculus", gap: 23, lastPlayed: "2024-02-18", timesPlayed: 45, tourVenue: "Broadview Stage at SPAC", tourVenueRun: nil, tourDate: "2025-07-26"),
            SongGapInfo(songId: 398, songName: "McGrupp", gap: 15, lastPlayed: "2024-07-12", timesPlayed: 62, tourVenue: "Alpine Valley Music Theatre", tourVenueRun: nil, tourDate: "2025-07-25")
        ]
        
        TourStatisticsCards(
            statistics: TourSongStatistics(
                longestSongs: sampleLongestSongs,
                rarestSongs: sampleRarestSongs,
                tourName: "Summer Tour 2025"
            )
        )
        
        TourOverviewCard(
            tourName: "Summer Tour 2025",
            showCount: 23,
            totalSongs: 147
        )
        
        Spacer()
    }
    .padding()
    .background(Color(.systemGray6))
}