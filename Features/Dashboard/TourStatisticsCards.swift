//
//  TourStatisticsCards.swift
//  PhishQS
//
//  Combined statistics cards in a vertical layout
//  Extracted from TourMetricCards.swift for better organization
//

import SwiftUI

struct TourStatisticsCards: View {
    let statistics: TourSongStatistics?

    var body: some View {
        if let stats = statistics, stats.hasData {
            VStack(alignment: .leading, spacing: 16) {
                LongestSongsCard(
                    songs: stats.longestSongs,
                    showDurationAvailability: stats.showDurationAvailability ?? []
                )
                if let setSongStats = stats.setSongStats, !setSongStats.isEmpty {
                    SongsPerSetCard(setSongStats: setSongStats)
                }
                if let debuts = stats.debuts {
                    DebutsCard(debuts: debuts)
                }
                RarestSongsCard(songs: stats.rarestSongs)
                if let openersClosers = stats.openersClosers, !openersClosers.isEmpty {
                    OpenersClosersCard(openersClosers: openersClosers)
                }
                if let repeats = stats.repeats, !repeats.shows.isEmpty {
                    RepeatsGraphCard(repeats: repeats)
                }
                if let mostCommonSongs = stats.mostCommonSongsNotPlayed, !mostCommonSongs.isEmpty {
                    MostCommonSongsNotPlayedCard(songs: mostCommonSongs)
                }
                MostPlayedSongsCard(songs: stats.mostPlayedSongs)
            }
        }
    }
}

// MARK: - Preview

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

        // Sample most common songs not played
        let sampleMostCommonSongsNotPlayed = [
            MostCommonSongNotPlayed(songId: 101, songName: "Harry Hood", historicalPlayCount: 1250, originalArtist: "Phish"),
            MostCommonSongNotPlayed(songId: 214, songName: "Bathtub Gin", historicalPlayCount: 1189, originalArtist: "Phish"),
            MostCommonSongNotPlayed(songId: 367, songName: "Also Sprach Zarathustra", historicalPlayCount: 987, originalArtist: "Strauss"),
            MostCommonSongNotPlayed(songId: 445, songName: "Possum", historicalPlayCount: 923, originalArtist: "Phish"),
            MostCommonSongNotPlayed(songId: 512, songName: "Golgi Apparatus", historicalPlayCount: 856, originalArtist: "Phish")
        ]

        // Sample duration availability
        let sampleAvailability = [
            ShowDurationAvailability(
                date: "2025-07-27",
                venue: "Madison Square Garden",
                city: "New York",
                state: "NY",
                durationsAvailable: true
            ),
            ShowDurationAvailability(
                date: "2025-07-26",
                venue: "Broadview Stage at SPAC",
                city: "Saratoga Springs",
                state: "NY",
                durationsAvailable: true
            )
        ]

        // Sample openers, closers, and encores
        let sampleOpenersClosers: OpenersClosersStats = [
            "1_opener": [
                PositionSong(songName: "Carini", songId: 100, count: 5),
                PositionSong(songName: "AC/DC Bag", songId: 101, count: 4),
                PositionSong(songName: "Buried Alive", songId: 102, count: 3)
            ],
            "1_closer": [
                PositionSong(songName: "Reba", songId: 200, count: 4),
                PositionSong(songName: "Stash", songId: 201, count: 3)
            ],
            "2_opener": [
                PositionSong(songName: "Down with Disease", songId: 300, count: 6),
                PositionSong(songName: "Simple", songId: 301, count: 3)
            ],
            "2_closer": [
                PositionSong(songName: "You Enjoy Myself", songId: 400, count: 5),
                PositionSong(songName: "Slave to the Traffic Light", songId: 401, count: 4)
            ],
            "e_all": [
                PositionSong(songName: "Character Zero", songId: 500, count: 8),
                PositionSong(songName: "First Tube", songId: 501, count: 6),
                PositionSong(songName: "Julius", songId: 502, count: 4)
            ]
        ]

        // Sample debuts
        let sampleDebuts = DebutsStats(
            songs: [
                DebutInfo(
                    id: 999, songId: 999, songName: "Brand New Song",
                    footnote: "Phish debut.", showDate: "2025-07-27",
                    venue: "Madison Square Garden", venueRun: sampleVenueRun,
                    city: "New York", state: "NY", tourPosition: sampleTourPosition,
                    originalArtist: "Some Artist"
                )
            ],
            latestShowDate: "2025-07-27"
        )

        TourStatisticsCards(
            statistics: TourSongStatistics(
                longestSongs: sampleLongestSongs,
                rarestSongs: sampleRarestSongs,
                mostPlayedSongs: sampleMostPlayedSongs,
                mostCommonSongsNotPlayed: sampleMostCommonSongsNotPlayed,
                setSongStats: [
                    "1": SetSongStats(
                        min: SetSongExtreme(count: 8, shows: [SetSongShow(date: "2025-12-28", venue: "MSG", city: "New York", state: "NY", venueRun: "N1")]),
                        max: SetSongExtreme(count: 11, shows: [SetSongShow(date: "2025-12-30", venue: "MSG", city: "New York", state: "NY", venueRun: "N3")])
                    ),
                    "2": SetSongStats(
                        min: SetSongExtreme(count: 7, shows: [SetSongShow(date: "2025-12-29", venue: "MSG", city: "New York", state: "NY", venueRun: "N2")]),
                        max: SetSongExtreme(count: 9, shows: [SetSongShow(date: "2025-12-28", venue: "MSG", city: "New York", state: "NY", venueRun: "N1")])
                    ),
                    "e": SetSongStats(
                        min: SetSongExtreme(count: 1, shows: [SetSongShow(date: "2025-12-28", venue: "MSG", city: "New York", state: "NY", venueRun: "N1")]),
                        max: SetSongExtreme(count: 3, shows: [SetSongShow(date: "2025-12-30", venue: "MSG", city: "New York", state: "NY", venueRun: "N3")])
                    )
                ],
                openersClosers: sampleOpenersClosers,
                repeats: RepeatsStats(
                    shows: [
                        RepeatShowData(date: "2025-12-28", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N1", totalSongs: 18, repeats: 0, repeatPercentage: 0, averageGap: 15.2, showNumber: 1, totalTourShows: 4),
                        RepeatShowData(date: "2025-12-29", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N2", totalSongs: 19, repeats: 0, repeatPercentage: 0, averageGap: 18.9, showNumber: 2, totalTourShows: 4),
                        RepeatShowData(date: "2025-12-30", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N3", totalSongs: 18, repeats: 0, repeatPercentage: 0, averageGap: 16.4, showNumber: 3, totalTourShows: 4),
                        RepeatShowData(date: "2025-12-31", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N4", totalSongs: 27, repeats: 0, repeatPercentage: 0, averageGap: 17.4, showNumber: 4, totalTourShows: 4)
                    ],
                    hasRepeats: false,
                    maxPercentage: 0,
                    maxAverageGap: 18.9,
                    totalShows: 4
                ),
                debuts: sampleDebuts,
                tourName: TourConfig.currentTourName,
                showDurationAvailability: sampleAvailability,
                youtubeVideos: nil
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