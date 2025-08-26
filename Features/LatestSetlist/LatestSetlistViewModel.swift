import Foundation
import SwiftUI

// ViewModel for fetching and managing the latest Phish setlist with navigation support
class LatestSetlistViewModel: BaseViewModel {
    @Published var latestShow: Show?
    @Published var setlistItems: [SetlistItem] = []
    @Published var enhancedSetlist: EnhancedSetlist?
    @Published var tourStatistics: TourSongStatistics?
    
    // Navigation state
    @Published var currentShowIndex: Int = 0
    @Published var canNavigateNext: Bool = false
    @Published var canNavigatePrevious: Bool = false
    
    // Cached data for efficient navigation
    private var cachedShows: [Show] = []
    private var cachedYear: String?
    private var showsCache: [String: [Show]] = [:]
    
    private let apiClient: any PhishAPIService
    private let apiManager: APIManager
    
    // MARK: - Initialization
    
    init(apiClient: any PhishAPIService = PhishAPIClient.shared, apiManager: APIManager = APIManager()) {
        self.apiClient = apiClient
        self.apiManager = apiManager
    }
    
    // Fetch the latest show and its setlist, and cache shows for navigation
    @MainActor
    func fetchLatestSetlist() async {
        setLoading(true)
        
        do {
            if let show = try await apiClient.fetchLatestShow() {
                latestShow = show
                
                // Fetch enhanced setlist data with venue run info
                let enhanced = try await apiManager.fetchEnhancedSetlist(for: show.showdate)
                enhancedSetlist = enhanced
                setlistItems = enhanced.setlistItems
                
                // Fetch tour statistics in background
                await fetchTourStatistics()
                
                // Cache shows for navigation
                await loadShowsForYear(show.showyear)
                updateNavigationState()
            } else {
                errorMessage = "Still waiting..."
            }
        } catch {
            handleError(error)
            return
        }
        
        setLoading(false)
    }
    
    // Non-async wrapper for SwiftUI compatibility
    func fetchLatestSetlist() {
        Task {
            await fetchLatestSetlist()
        }
    }
    
    
    /// Get venue run information (N1/N2/N3), if available
    var venueRunInfo: VenueRun? {
        return enhancedSetlist?.venueRun
    }
    
    /// Get tour position information (Show X/Y), if available
    var tourPositionInfo: TourShowPosition? {
        return enhancedSetlist?.tourPosition
    }
    
    // MARK: - Navigation Methods
    
    // Load and cache shows for a specific year
    @MainActor
    private func loadShowsForYear(_ year: String) async {
        // Check if already cached
        if let cached = showsCache[year] {
            cachedShows = cached
            cachedYear = year
            return
        }
        
        do {
            let shows = try await apiClient.fetchShows(forYear: year)
            let phishShows = APIUtilities.filterPhishShows(shows)
            
            // Filter to unique show dates only (remove duplicates)
            var uniqueShows: [Show] = []
            var seenDates: Set<String> = []
            
            for show in phishShows.sorted(by: { $0.showdate > $1.showdate }) {
                if !seenDates.contains(show.showdate) {
                    uniqueShows.append(show)
                    seenDates.insert(show.showdate)
                }
            }
            
            cachedShows = uniqueShows
            cachedYear = year
            showsCache[year] = uniqueShows
        } catch {
            // Handle error silently to not disrupt main flow
            print("Failed to load shows for year \(year): \(error)")
        }
    }
    
    // Update navigation availability based on current show position
    @MainActor
    private func updateNavigationState() {
        guard let currentShow = latestShow else {
            canNavigateNext = false
            canNavigatePrevious = false
            return
        }
        
        // Find current show index in cached shows
        if let index = cachedShows.firstIndex(where: { $0.showdate == currentShow.showdate }) {
            currentShowIndex = index
            // Since shows are sorted most recent first (index 0):
            // - canNavigatePrevious means go to chronologically earlier show (higher index)
            // - canNavigateNext means go to chronologically later show (lower index)
            canNavigatePrevious = index < cachedShows.count - 1
            canNavigateNext = index > 0
        }
    }
    
    // Navigate to the next show (chronologically later)
    @MainActor
    func navigateToNextShow() async {
        guard canNavigateNext, currentShowIndex > 0 else { return }
        
        setLoading(true)
        let nextIndex = currentShowIndex - 1  // Go to lower index (more recent)
        let nextShow = cachedShows[nextIndex]
        
        await loadShow(nextShow, at: nextIndex)
        setLoading(false)
    }
    
    // Navigate to the previous show (chronologically earlier)
    @MainActor
    func navigateToPreviousShow() async {
        guard canNavigatePrevious, currentShowIndex < cachedShows.count - 1 else {
            // Try to load previous year if at end of current year
            await navigateToPreviousYear()
            return
        }
        
        setLoading(true)
        let prevIndex = currentShowIndex + 1  // Go to higher index (older)
        let prevShow = cachedShows[prevIndex]
        
        await loadShow(prevShow, at: prevIndex)
        setLoading(false)
    }
    
    // Load a specific show and its setlist
    @MainActor
    private func loadShow(_ show: Show, at index: Int) async {
        do {
            latestShow = show
            
            // Fetch enhanced setlist data with venue run info and tour positions
            let enhanced = try await apiManager.fetchEnhancedSetlist(for: show.showdate)
            enhancedSetlist = enhanced
            setlistItems = enhanced.setlistItems
            
            // Update tour statistics for new show
            await fetchTourStatistics()
            
            currentShowIndex = index
            updateNavigationState()
        } catch {
            handleError(error)
        }
    }
    
    // Navigate to previous year's latest show
    @MainActor
    private func navigateToPreviousYear() async {
        guard let currentYear = cachedYear,
              let yearInt = Int(currentYear) else { return }
        
        setLoading(true)
        let previousYear = String(yearInt - 1)
        
        await loadShowsForYear(previousYear)
        if let latestShowOfYear = cachedShows.first {
            await loadShow(latestShowOfYear, at: 0)
        }
        
        setLoading(false)
    }
    
    // Non-async wrapper for navigation methods
    func navigateToNextShow() {
        Task { await navigateToNextShow() }
    }
    
    func navigateToPreviousShow() {
        Task { await navigateToPreviousShow() }
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
    
    /// Get formatted duration string for a song at a specific position (preferred method)
    func formattedDuration(at position: Int, expectedName: String? = nil) -> String? {
        guard let enhancedSetlist = enhancedSetlist else { return nil }
        
        if let expectedName = expectedName {
            return enhancedSetlist.getDuration(at: position, expectedName: expectedName)?.formattedDuration
        } else {
            return enhancedSetlist.getDuration(at: position)?.formattedDuration
        }
    }
    
    /// Get formatted duration string for a specific song by name (fallback method)
    /// Note: This may return incorrect results for duplicate song names like "Tweezer Reprise"
    func formattedDuration(for song: String) -> String? {
        guard let enhancedSetlist = enhancedSetlist else { return nil }
        return enhancedSetlist.getDuration(for: song)?.formattedDuration
    }
    
    /// Check if enhanced data is available
    var hasEnhancedData: Bool {
        return enhancedSetlist != nil && !(enhancedSetlist?.trackDurations.isEmpty ?? true)
    }
    
    // MARK: - Tour Statistics Methods
    
    /// Fetch tour statistics based on current show
    @MainActor
    private func fetchTourStatistics() async {
        // Only fetch if we have enhanced setlist data
        guard let enhanced = enhancedSetlist else { return }
        
        do {
            // Fetch gap data from Phish.net API
            let allSongGaps = try await apiClient.fetchAllSongsWithGaps()
            
            // Fetch tour-wide track durations if we have tour information
            var tourTrackDurations: [TrackDuration]? = nil
            if let tourName = enhanced.tourPosition?.tourName {
                do {
                    print("Attempting to fetch tour data for: '\(tourName)'")
                    
                    // First, let's see what tours are actually available in 2025
                    let availableTours = try await apiManager.fetchTours(forYear: "2025")
                    print("Available 2025 tours: \(availableTours.map { $0.name })")
                    
                    tourTrackDurations = try await apiManager.fetchTourTrackDurations(tourName: tourName)
                    print("Fetched \(tourTrackDurations?.count ?? 0) track durations for tour: \(tourName)")
                } catch {
                    print("Warning: Could not fetch tour track durations for \(tourName): \(error)")
                }
            } else {
                print("No tour name available from enhanced setlist")
            }
            
            // Calculate tour statistics using the service
            let tourName = enhanced.tourPosition?.tourName
            let statistics = TourStatisticsService.calculateTourStatistics(
                enhancedSetlist: enhanced,
                tourTrackDurations: tourTrackDurations,
                allSongGaps: allSongGaps,
                tourName: tourName
            )
            
            // Update published property on main actor
            tourStatistics = statistics
            
        } catch {
            // Log error but don't block main functionality
            print("Failed to fetch tour statistics: \(error)")
            tourStatistics = nil
        }
    }
    
} 
