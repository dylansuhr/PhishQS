//
//  APIProtocols.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//

import Foundation

// MARK: - Base API Client Protocol

/// Base protocol that all API clients should conform to
protocol APIClientProtocol {
    var baseURL: String { get }
    var isAvailable: Bool { get }
}

// MARK: - Setlist Provider Protocol

/// Protocol for APIs that provide setlist data
protocol SetlistProviderProtocol: APIClientProtocol {
    func fetchShows(forYear year: String) async throws -> [Show]
    func fetchLatestShow() async throws -> Show?
    func fetchSetlist(for date: String) async throws -> [SetlistItem]
    func searchShows(query: String) async throws -> [Show]
}

/// Legacy protocol for backward compatibility with existing ViewModels
protocol PhishAPIService {
    func fetchShows(forYear year: String) async throws -> [Show]
    func fetchLatestShow() async throws -> Show?
    func fetchSetlist(for date: String) async throws -> [SetlistItem]
    func searchShows(query: String) async throws -> [Show]
    func fetchAllSongsWithGaps() async throws -> [SongGapInfo]
    func fetchSongPerformances(songName: String) async throws -> [SongPerformance]
    func fetchShowCountBetween(startDate: String, endDate: String) async throws -> Int
}

// MARK: - Audio Provider Protocol

/// Protocol for APIs that provide audio/recording information
protocol AudioProviderProtocol: APIClientProtocol {
    func fetchTrackDurations(for showDate: String) async throws -> [TrackDuration]
    func fetchTourTrackDurations(tourName: String) async throws -> [TrackDuration]
    func fetchRecordings(for showDate: String) async throws -> [Recording]
}

// MARK: - Tour Provider Protocol

/// Protocol for APIs that provide tour and venue run information
protocol TourProviderProtocol: APIClientProtocol {
    func fetchTours(forYear year: String) async throws -> [Tour]
    func fetchVenueRuns(for showDate: String) async throws -> VenueRun?
    func fetchTourPosition(for showDate: String) async throws -> TourShowPosition?
}

// MARK: - Gap Data Provider Protocol

/// Protocol for APIs that provide gap information between song performances
protocol GapDataProviderProtocol: APIClientProtocol {
    /// Fetch gap information for a specific song on a specific show date
    func fetchSongGap(songName: String, showDate: String) async throws -> SongGapInfo?
    
    /// Fetch gap information for multiple songs on a specific show date
    func fetchSongGaps(songNames: [String], showDate: String) async throws -> [SongGapInfo]
    
    /// Fetch complete performance history for a song (includes gap data for each performance)
    func fetchSongPerformanceHistory(songName: String) async throws -> [SongPerformance]
}

