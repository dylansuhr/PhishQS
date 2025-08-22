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
}

// MARK: - Audio Provider Protocol

/// Protocol for APIs that provide audio/recording information
protocol AudioProviderProtocol: APIClientProtocol {
    func fetchTrackDurations(for showDate: String) async throws -> [TrackDuration]
    func fetchRecordings(for showDate: String) async throws -> [Recording]
}

// MARK: - Tour Provider Protocol

/// Protocol for APIs that provide tour and venue run information
protocol TourProviderProtocol: APIClientProtocol {
    func fetchTours(forYear year: String) async throws -> [Tour]
    func fetchVenueRuns(for showDate: String) async throws -> VenueRun?
    func fetchTourPosition(for showDate: String) async throws -> TourShowPosition?
    func fetchShowsInTour(_ tourId: String) async throws -> [Show]
}

// MARK: - User Data Provider Protocol

/// Protocol for APIs that provide user interaction features
protocol UserDataProviderProtocol: APIClientProtocol {
    func authenticateUser(username: String, password: String) async throws -> UserSession
    func fetchUserLikes() async throws -> [String] // show IDs
    func fetchUserPlaylists() async throws -> [Playlist]
}