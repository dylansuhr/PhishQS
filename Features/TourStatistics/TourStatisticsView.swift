//
//  TourStatisticsView.swift
//  PhishQS
//
//  Created by Claude on 8/26/25.
//

import SwiftUI

/// View displaying tour statistics: longest songs and rarest songs
struct TourStatisticsView: View {
    let statistics: TourSongStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if statistics.hasData {
                // Longest Songs Section
                if !statistics.longestSongs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top 3 Longest Songs")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        ForEach(Array(statistics.longestSongs.enumerated()), id: \.offset) { index, song in
                            LongestSongRowView(position: index + 1, song: song)
                        }
                    }
                }
                
                // Rarest Songs Section
                if !statistics.rarestSongs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top 3 Rarest Songs")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        ForEach(Array(statistics.rarestSongs.enumerated()), id: \.offset) { index, song in
                            RarestSongRowView(position: index + 1, song: song)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Row view for displaying longest song information
struct LongestSongRowView: View {
    let position: Int
    let song: TrackDuration
    
    var body: some View {
        HStack {
            Text("\\(position).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .leading)
            
            Text(song.songName)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(song.formattedDuration)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(formattedShowDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Formatted show date for display
    private var formattedShowDate: String {
        DateUtilities.formatDateForDisplay(song.showDate)
    }
}

/// Row view for displaying rarest song information
struct RarestSongRowView: View {
    let position: Int
    let song: SongGapInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\\(position).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20, alignment: .leading)
                
                Text(song.songName)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(song.gapDisplayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                    .frame(width: 20) // Align with song name
                
                Text(song.lastPlayedFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
}

#Preview {
    // Sample data for preview
    let sampleLongestSongs = [
        TrackDuration(
            id: "1",
            songName: "Tweezer",
            songId: 627,
            durationSeconds: 1425, // 23:45
            showDate: "2025-07-27",
            setNumber: "2"
        ),
        TrackDuration(
            id: "2",
            songName: "You Enjoy Myself",
            songId: 692,
            durationSeconds: 1112, // 18:32
            showDate: "2025-07-26",
            setNumber: "1"
        ),
        TrackDuration(
            id: "3",
            songName: "Ghost",
            songId: 294,
            durationSeconds: 947, // 15:47
            showDate: "2025-07-25",
            setNumber: "2"
        )
    ]
    
    let sampleRarestSongs = [
        SongGapInfo(
            songId: 251,
            songName: "Fluffhead",
            gap: 47,
            lastPlayed: "2023-08-15",
            timesPlayed: 87
        ),
        SongGapInfo(
            songId: 342,
            songName: "Icculus",
            gap: 23,
            lastPlayed: "2024-02-18",
            timesPlayed: 45
        ),
        SongGapInfo(
            songId: 398,
            songName: "McGrupp",
            gap: 15,
            lastPlayed: "2024-07-12",
            timesPlayed: 62
        )
    ]
    
    let sampleStatistics = TourSongStatistics(
        longestSongs: sampleLongestSongs,
        rarestSongs: sampleRarestSongs,
        tourName: "Summer Tour 2025"
    )
    
    return VStack {
        TourStatisticsView(statistics: sampleStatistics)
        Spacer()
    }
    .background(Color(.systemGray6))
}