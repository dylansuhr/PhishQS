//
//  TourDashboardDataClient.swift
//  PhishQS
//
//  Created by Claude on 9/7/25.
//

import Foundation

/// Client for fetching tour dashboard data from remote API endpoints
/// Provides Component A with access to pre-generated tour data via Vercel endpoints
class TourDashboardDataClient: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = TourDashboardDataClient()
    
    // MARK: - Configuration
    
    private let baseURL: String = {
        #if DEBUG
        return "http://localhost:3000/api"
        #else
        return "https://phish-qs.vercel.app/api"
        #endif
    }()
    private let session = URLSession.shared
    
    // MARK: - Data Models
    
    struct TourDashboardData: Codable {
        let currentTour: CurrentTour
        let latestShow: LatestShow
        let futureTours: [FutureTour]
        let metadata: Metadata
        
        struct CurrentTour: Codable {
            let name: String
            let year: String
            let totalShows: Int
            let playedShows: Int
            let startDate: String
            let endDate: String
            let tourDates: [TourDate]
        }
        
        struct TourDate: Codable {
            let date: String
            let venue: String
            let city: String
            let state: String
            let played: Bool
            let showNumber: Int
            let showFile: String?
        }
        
        struct LatestShow: Codable {
            let date: String
            let venue: String
            let city: String
            let state: String
            let tourPosition: TourPosition
        }
        
        struct TourPosition: Codable {
            let showNumber: Int
            let totalShows: Int
            let tourName: String
        }
        
        struct FutureTour: Codable {
            let name: String
            let year: String
            let startDate: String
            let endDate: String
            let shows: Int
        }
        
        struct Metadata: Codable {
            let lastUpdated: String
            let dataVersion: String
            let updateReason: String
            let nextShow: NextShow?
        }
        
        struct NextShow: Codable {
            let date: String?
            let venue: String?
            let city: String?
            let state: String?
        }
    }
    
    struct ShowFileData: Codable {
        let showDate: String
        let venue: String
        let city: String
        let state: String
        let tourPosition: TourPositionData
        let venueRun: VenueRunData?
        let setlistItems: [SetlistItemData]
        let trackDurations: [TrackDurationData]
        let songGaps: [SongGapData]
        let metadata: ShowMetadata
        
        struct TourPositionData: Codable {
            let showNumber: Int
            let totalShows: Int
            let tourName: String
            let tourYear: String
        }
        
        struct VenueRunData: Codable {
            let venue: String
            let city: String
            let state: String
            let nightNumber: Int
            let totalNights: Int
            let showDates: [String]
        }
        
        struct SetlistItemData: Codable {
            let song: String
            let trans_mark: String?
            let set: String
            let position: Int
        }
        
        struct TrackDurationData: Codable {
            let id: String
            let songName: String
            let songId: Int?
            let durationSeconds: Int
            let showDate: String
            let setNumber: String
            let venue: String
            let city: String
            let state: String
            let tourPosition: TourPositionData
        }
        
        struct SongGapData: Codable {
            let songId: Int
            let songName: String
            let gap: Int
            let lastPlayed: String
            let timesPlayed: Int
            let tourVenue: String
            let tourVenueRun: VenueRunData?
            let tourDate: String
            let tourCity: String
            let tourState: String
            let tourPosition: TourPositionData
            let historicalVenue: String
            let historicalCity: String
            let historicalState: String
            let historicalLastPlayed: String
            let formattedHistoricalDate: String
        }
        
        struct ShowMetadata: Codable {
            let setlistSource: String
            let durationsSource: String?
            let lastUpdated: String
            let dataComplete: Bool
        }
    }
    
    // MARK: - URL Construction
    
    private var tourDashboardURL: URL {
        URL(string: "\(baseURL)/tour-dashboard")!
    }
    
    private func showURL(for date: String) -> URL {
        URL(string: "\(baseURL)/shows/\(date)")!
    }
    
    // MARK: - Public Methods
    
    /// Fetch current tour dashboard data from remote API
    func fetchCurrentTourData() async throws -> TourDashboardData {
        do {
            let (data, response) = try await session.data(from: tourDashboardURL)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TourDashboardError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw TourDashboardError.httpError(statusCode: httpResponse.statusCode)
            }
            
            let tourData = try JSONDecoder().decode(TourDashboardData.self, from: data)
            print("✅ [Remote] Successfully fetched tour dashboard data")
            return tourData
        } catch let error as TourDashboardError {
            print("❌ [Remote] Failed to load tour dashboard data: \(error)")
            throw error
        } catch {
            print("❌ [Remote] Network error loading tour dashboard: \(error)")
            throw TourDashboardError.networkError(error)
        }
    }
    
    /// Fetch individual show data for a specific date
    func fetchShowData(for date: String) async throws -> ShowFileData {
        do {
            let (data, response) = try await session.data(from: showURL(for: date))
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TourDashboardError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw TourDashboardError.showFileNotFound(date: date)
                }
                throw TourDashboardError.httpError(statusCode: httpResponse.statusCode)
            }
            
            let showData = try JSONDecoder().decode(ShowFileData.self, from: data)
            print("✅ [Remote] Successfully fetched show data for \(date)")
            return showData
        } catch let error as TourDashboardError {
            print("❌ [Remote] Failed to load show data for \(date): \(error)")
            throw error
        } catch {
            print("❌ [Remote] Network error loading show \(date): \(error)")
            throw TourDashboardError.networkError(error)
        }
    }
    
    /// Fetch latest show data
    func fetchLatestShowData() async throws -> ShowFileData {
        let tourData = try await fetchCurrentTourData()
        return try await fetchShowData(for: tourData.latestShow.date)
    }
    
    /// Convert show file data to EnhancedSetlist for compatibility with existing UI
    func convertToEnhancedSetlist(_ showData: ShowFileData) -> EnhancedSetlist {
        // Convert setlist items
        let setlistItems = showData.setlistItems.map { item in
            SetlistItem(
                set: item.set,
                song: item.song,
                songId: nil, // Not stored in show files, but not needed for display
                transMark: item.trans_mark,
                venue: showData.venue,
                city: showData.city,
                state: showData.state,
                showdate: showData.showDate
            )
        }
        
        // Convert track durations
        let trackDurations = showData.trackDurations.map { track in
            TrackDuration(
                id: track.id,
                songName: track.songName,
                songId: track.songId,
                durationSeconds: track.durationSeconds,
                showDate: track.showDate,
                setNumber: track.setNumber,
                venue: track.venue,
                venueRun: nil, // Not needed for basic functionality
                city: track.city,
                state: track.state,
                tourPosition: TourShowPosition(
                    tourName: track.tourPosition.tourName,
                    showNumber: track.tourPosition.showNumber,
                    totalShows: track.tourPosition.totalShows,
                    tourYear: track.tourPosition.tourYear
                )
            )
        }
        
        // Convert venue run
        let venueRun = showData.venueRun.map { run in
            VenueRun(
                venue: run.venue,
                city: run.city,
                state: run.state,
                nightNumber: run.nightNumber,
                totalNights: run.totalNights,
                showDates: run.showDates
            )
        }
        
        // Convert tour position
        let tourPosition = TourShowPosition(
            tourName: showData.tourPosition.tourName,
            showNumber: showData.tourPosition.showNumber,
            totalShows: showData.tourPosition.totalShows,
            tourYear: showData.tourPosition.tourYear
        )
        
        return EnhancedSetlist(
            showDate: showData.showDate,
            setlistItems: setlistItems,
            trackDurations: trackDurations,
            venueRun: venueRun,
            tourPosition: tourPosition,
            recordings: [], // Not needed for Component A functionality
            songGaps: [] // Not needed for Component A functionality
        )
    }
}

// MARK: - Error Types

enum TourDashboardError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case showFileNotFound(date: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server error: HTTP \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .showFileNotFound(let date):
            return "Show data not found for date: \(date)"
        }
    }
}