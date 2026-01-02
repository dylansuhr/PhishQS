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
        let tourPosition: TourShowPosition?
        let venueRun: VenueRun?
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

        // First try to fetch from tour dashboard (has venueRun data for current tour shows)
        do {
            let showData = try await tourDashboardClient.fetchShowData(for: date)
            let enhanced = tourDashboardClient.convertToEnhancedSetlist(showData)
            enhancedSetlist = enhanced
            setlistItems = enhanced.setlistItems
            setlist = StringFormatters.formatSetlist(enhanced.setlistItems)

            // Update metadata from setlist (preserve tour/venue run from metadata)
            if let firstItem = enhanced.setlistItems.first {
                showMetadata = ShowMetadata(
                    date: date,
                    venue: firstItem.venue,
                    city: firstItem.city,
                    state: firstItem.state ?? "",
                    tourPosition: enhanced.tourPosition ?? showMetadata?.tourPosition,
                    venueRun: enhanced.venueRun ?? showMetadata?.venueRun
                )
            }
            setLoading(false)
            return
        } catch {
            // Show file not found - fall back to basic API for historical shows
        }

        // Fallback: Fetch basic setlist (for historical shows not in tour data)
        do {
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
                    state: firstItem.state ?? "",
                    tourPosition: enhanced.tourPosition ?? showMetadata?.tourPosition,
                    venueRun: enhanced.venueRun ?? showMetadata?.venueRun
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
                let tourDates = tourData.currentTour.tourDates
                let tourPosition = TourShowPosition(
                    tourName: tourData.currentTour.name,
                    showNumber: tourDate.showNumber,
                    totalShows: tourDates.count,
                    tourYear: String(date.prefix(4))
                )
                let venueRun = calculateVenueRun(for: date, venue: tourDate.venue, in: tourDates)

                showMetadata = ShowMetadata(
                    date: date,
                    venue: tourDate.venue,
                    city: tourDate.city,
                    state: tourDate.state,
                    tourPosition: tourPosition,
                    venueRun: venueRun
                )
                return
            }

            // Search in future tours
            for futureTour in tourData.futureTours {
                if let tourDate = futureTour.tourDates.first(where: { $0.date == date }) {
                    let tourDates = futureTour.tourDates
                    let tourPosition = TourShowPosition(
                        tourName: futureTour.name,
                        showNumber: tourDate.showNumber,
                        totalShows: tourDates.count,
                        tourYear: String(date.prefix(4))
                    )
                    let venueRun = calculateVenueRun(for: date, venue: tourDate.venue, in: tourDates)

                    showMetadata = ShowMetadata(
                        date: date,
                        venue: tourDate.venue,
                        city: tourDate.city,
                        state: tourDate.state,
                        tourPosition: tourPosition,
                        venueRun: venueRun
                    )
                    return
                }
            }
        } catch {
            // Silently fail - we'll try to get metadata from setlist
        }
    }

    /// Calculate venue run info (N1/N2/N3) for all shows at the same venue within a tour
    /// Residencies like Sphere or Baker's Dozen have gaps between nights but are still
    /// counted as a single run (e.g., "N1 of 9" through "N9 of 9")
    private func calculateVenueRun(for date: String, venue: String, in tourDates: [TourDashboardDataClient.TourDashboardData.TourDate]) -> VenueRun? {
        // Find ALL shows at this venue (not just consecutive)
        let sortedDates = tourDates.sorted { $0.date < $1.date }
        let venueShows = sortedDates.filter { $0.venue == venue }

        // Single night at venue - no run to display
        guard venueShows.count > 1 else { return nil }

        // Find this show's position in the venue run
        guard let position = venueShows.firstIndex(where: { $0.date == date }) else {
            return nil
        }

        let nightNumber = position + 1
        let showDates = venueShows.map { $0.date }
        let city = venueShows.first?.city ?? ""
        let state = venueShows.first?.state ?? ""

        return VenueRun(
            venue: venue,
            city: city,
            state: state,
            nightNumber: nightNumber,
            totalNights: venueShows.count,
            showDates: showDates
        )
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
        return enhancedSetlist?.venueRun ?? showMetadata?.venueRun
    }

    /// Get tour position information (Show X/Y), if available
    var tourPositionInfo: TourShowPosition? {
        return enhancedSetlist?.tourPosition ?? showMetadata?.tourPosition
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
