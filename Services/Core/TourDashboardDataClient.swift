//
//  TourDashboardDataClient.swift
//  PhishQS
//
//  Created by Claude on 9/7/25.
//

import Foundation

/// Client for reading tour dashboard data from single source of truth files
/// Provides Component A with access to pre-generated tour data without API calls
class TourDashboardDataClient: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = TourDashboardDataClient()
    
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
            let songName: String
            let transition: String?
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
    
    // MARK: - File Paths
    
    private var controlFilePath: String {
        // During development, read from project directory
        let projectPath = "/Users/dylansuhr/Developer/dylan_suhr/ios_apps/PhishQS"
        let devPath = projectPath + "/api/Data/tour-dashboard-data.json"
        
        if FileManager.default.fileExists(atPath: devPath) {
            return devPath
        }
        
        // Fallback to bundle path for production
        guard let bundlePath = Bundle.main.resourcePath else {
            fatalError("Could not find bundle resource path")
        }
        return bundlePath + "/api/Data/tour-dashboard-data.json"
    }
    
    private func showFilePath(for showFile: String) -> String {
        // During development, read from project directory
        let projectPath = "/Users/dylansuhr/Developer/dylan_suhr/ios_apps/PhishQS"
        let devPath = projectPath + "/api/Data/" + showFile
        
        if FileManager.default.fileExists(atPath: devPath) {
            return devPath
        }
        
        // Fallback to bundle path for production
        guard let bundlePath = Bundle.main.resourcePath else {
            fatalError("Could not find bundle resource path")
        }
        return bundlePath + "/api/Data/" + showFile
    }
    
    // MARK: - Public Methods
    
    /// Fetch current tour dashboard data from control file
    func fetchCurrentTourData() async throws -> TourDashboardData {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: self.controlFilePath))
                    let tourData = try JSONDecoder().decode(TourDashboardData.self, from: data)
                    continuation.resume(returning: tourData)
                } catch {
                    print("❌ Failed to load control file: \(error)")
                    continuation.resume(throwing: TourDashboardError.controlFileNotFound)
                }
            }
        }
    }
    
    /// Fetch individual show data for a specific date
    func fetchShowData(for date: String) async throws -> ShowFileData {
        let tourData = try await fetchCurrentTourData()
        
        // Find the tour date entry for this show
        guard let tourDate = tourData.currentTour.tourDates.first(where: { $0.date == date }),
              let showFile = tourDate.showFile else {
            throw TourDashboardError.showFileNotFound(date: date)
        }
        
        return try await loadShowFile(showFile)
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
                song: item.songName,
                songId: nil, // Not stored in show files, but not needed for display
                transMark: item.transition,
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
    
    // MARK: - Private Methods
    
    private func loadShowFile(_ showFile: String) async throws -> ShowFileData {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let filePath = self.showFilePath(for: showFile)
                    let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                    let showData = try JSONDecoder().decode(ShowFileData.self, from: data)
                    continuation.resume(returning: showData)
                } catch {
                    print("❌ Failed to load show file \(showFile): \(error)")
                    continuation.resume(throwing: TourDashboardError.showFileLoadFailed(file: showFile, error: error))
                }
            }
        }
    }
}

// MARK: - Error Types

enum TourDashboardError: Error, LocalizedError {
    case controlFileNotFound
    case showFileNotFound(date: String)
    case showFileLoadFailed(file: String, error: Error)
    
    var errorDescription: String? {
        switch self {
        case .controlFileNotFound:
            return "Could not find tour dashboard control file"
        case .showFileNotFound(let date):
            return "Could not find show file for date: \(date)"
        case .showFileLoadFailed(let file, let error):
            return "Failed to load show file \(file): \(error.localizedDescription)"
        }
    }
}