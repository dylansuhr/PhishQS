import Foundation
import SwiftUI

// ViewModel that fetches and holds the setlist data for a specific show date
class SetlistViewModel: BaseViewModel {
    @Published var setlist: [String] = []
    @Published var setlistItems: [SetlistItem] = []
    @Published var enhancedSetlist: EnhancedSetlist?
    @Published var showMetadata: ShowMetadata?

    private let apiManager: APIManager
    private let tourDashboardClient: TourDashboardDataClient

    // MARK: - Show Metadata

    struct ShowMetadata {
        let date: String
        let venue: String
        let city: String
        let state: String
    }

    // MARK: - Initialization

    init(apiManager: APIManager = APIManager(), tourDashboardClient: TourDashboardDataClient = .shared) {
        self.apiManager = apiManager
        self.tourDashboardClient = tourDashboardClient
    }

    // called when user selects a specific date (YYYY-MM-DD)
    @MainActor
    func fetchSetlist(for date: String) async {
        setLoading(true)

        // Fetch show metadata from tour dashboard (always available for tour dates)
        await fetchShowMetadata(for: date)

        do {
            // Fetch basic setlist (optimized - only setlist + durations)
            let enhanced = try await apiManager.fetchBasicSetlist(for: date)
            enhancedSetlist = enhanced
            setlistItems = enhanced.setlistItems
            setlist = StringFormatters.formatSetlist(enhanced.setlistItems)

            // Update metadata from setlist if we got better data
            if let firstItem = enhanced.setlistItems.first {
                showMetadata = ShowMetadata(
                    date: date,
                    venue: firstItem.venue,
                    city: firstItem.city,
                    state: firstItem.state ?? ""
                )
            }
            setLoading(false)
        } catch {
            // Even if setlist fails, we may have metadata - don't show error
            setLoading(false)
        }
    }

    @MainActor
    private func fetchShowMetadata(for date: String) async {
        do {
            let tourData = try await tourDashboardClient.fetchCurrentTourData()

            // Search in current tour dates
            if let tourDate = tourData.currentTour.tourDates.first(where: { $0.date == date }) {
                showMetadata = ShowMetadata(
                    date: date,
                    venue: tourDate.venue,
                    city: tourDate.city,
                    state: tourDate.state
                )
                return
            }

            // Search in future tours
            for futureTour in tourData.futureTours {
                if let tourDate = futureTour.tourDates.first(where: { $0.date == date }) {
                    showMetadata = ShowMetadata(
                        date: date,
                        venue: tourDate.venue,
                        city: tourDate.city,
                        state: tourDate.state
                    )
                    return
                }
            }
        } catch {
            // Silently fail - we'll try to get metadata from setlist
        }
    }
    
    // Non-async wrapper for SwiftUI compatibility
    func fetchSetlist(for date: String) {
        Task {
            await fetchSetlist(for: date)
        }
    }
    
    // MARK: - Enhanced Data Access
    
    /// Get song duration for a specific song, if available (in seconds)
    func songDuration(for song: String) -> Int? {
        return enhancedSetlist?.trackDurations.first { $0.songName.lowercased() == song.lowercased() }?.durationSeconds
    }
    
    
    /// Get venue run information (N1/N2/N3), if available
    var venueRunInfo: VenueRun? {
        return enhancedSetlist?.venueRun
    }
    
    /// Get tour position information (Show X/Y), if available
    var tourPositionInfo: TourShowPosition? {
        return enhancedSetlist?.tourPosition
    }
    
    /// Get available recordings, if any
    var recordings: [Recording] {
        return enhancedSetlist?.recordings ?? []
    }
    
    /// Check if enhanced data is available
    var hasEnhancedData: Bool {
        return enhancedSetlist != nil && !(enhancedSetlist?.trackDurations.isEmpty ?? true)
    }

    /// Check if valid duration data exists (excludes 0-second durations)
    var hasValidDurations: Bool {
        guard let trackDurations = enhancedSetlist?.trackDurations, !trackDurations.isEmpty else {
            return false
        }
        // Check if any duration is > 0 (filter out bad/incomplete data)
        return trackDurations.contains { $0.durationSeconds > 0 }
    }
    
    /// Debug: Get available track duration song names for troubleshooting
    var availableTrackNames: [String] {
        return enhancedSetlist?.trackDurations.map { $0.songName } ?? []
    }
    
    // MARK: - Color Calculation
    
    /// Get relative color for a song at a specific position (preferred method)
    /// Uses position-based matching for accurate color assignment with duplicate song names
    func colorForSong(at position: Int, expectedName: String? = nil) -> Color? {
        guard let trackDurations = enhancedSetlist?.trackDurations, !trackDurations.isEmpty else {
            return nil
        }
        
        let trackDuration: TrackDuration?
        if let expectedName = expectedName {
            trackDuration = enhancedSetlist?.getDuration(at: position, expectedName: expectedName)
        } else {
            trackDuration = enhancedSetlist?.getDuration(at: position)
        }
        
        guard let track = trackDuration else { return nil }
        
        let allDurations = trackDurations.map { $0.durationSeconds }
        return RelativeDurationColors.colorForDuration(track.durationSeconds, in: allDurations)
    }
    
    /// Get relative color for a song by name (fallback method)  
    /// Note: This may return incorrect results for duplicate song names like "Tweezer Reprise"
    func colorForSong(_ songName: String) -> Color? {
        guard let trackDurations = enhancedSetlist?.trackDurations, !trackDurations.isEmpty else {
            return nil
        }
        
        let track = enhancedSetlist?.getDuration(for: songName)
        guard let track = track else { return nil }
        
        let allDurations = trackDurations.map { $0.durationSeconds }
        return RelativeDurationColors.colorForDuration(track.durationSeconds, in: allDurations)
    }
    
    /// Get formatted duration for a song at a specific position (preferred method)
    func formattedDuration(at position: Int, expectedName: String? = nil) -> String? {
        guard let enhancedSetlist = enhancedSetlist else { return nil }
        
        if let expectedName = expectedName {
            return enhancedSetlist.getDuration(at: position, expectedName: expectedName)?.formattedDuration
        } else {
            return enhancedSetlist.getDuration(at: position)?.formattedDuration
        }
    }
    
    /// Get formatted duration for a song by name (fallback method)
    func formattedDuration(for song: String) -> String? {
        guard let enhancedSetlist = enhancedSetlist else { return nil }
        return enhancedSetlist.getDuration(for: song)?.formattedDuration
    }
    
}
