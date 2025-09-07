import Foundation
import SwiftUI

// ViewModel for fetching and managing the latest Phish setlist with navigation support
class LatestSetlistViewModel: BaseViewModel {
    @Published var latestShow: Show?
    @Published var setlistItems: [SetlistItem] = []
    @Published var enhancedSetlist: EnhancedSetlist?
    @Published var tourStatistics: TourSongStatistics?
    @Published var isTourStatisticsLoading: Bool = false
    
    private let tourDashboardClient: TourDashboardDataClient
    
    // MARK: - Initialization
    
    init(tourDashboardClient: TourDashboardDataClient = TourDashboardDataClient.shared) {
        self.tourDashboardClient = tourDashboardClient
    }
    
    // Fetch the latest show and its setlist from single source
    @MainActor
    func fetchLatestSetlist() async {
        setLoading(true)
        
        do {
            print("📋 [Component A] Fetching latest show from single source...")
            
            // Get tour dashboard data to identify latest show
            let tourData = try await tourDashboardClient.fetchCurrentTourData()
            
            // Create Show object from latest show data
            latestShow = Show(
                showyear: String(tourData.latestShow.date.prefix(4)),
                showdate: tourData.latestShow.date,
                artist_name: "Phish",
                tour_name: tourData.latestShow.tourPosition.tourName
            )
            
            // Fetch enhanced setlist data from individual show file
            let showData = try await tourDashboardClient.fetchLatestShowData()
            let enhanced = tourDashboardClient.convertToEnhancedSetlist(showData)
            
            enhancedSetlist = enhanced
            setlistItems = enhanced.setlistItems
            
            print("✅ [Component A] Latest show loaded from single source: \(tourData.latestShow.date)")
            print("🎵 [Component A] Setlist items: \(setlistItems.count), Durations: \(enhanced.trackDurations.count)")
            
            // Set loading false first to show main content
            setLoading(false)
            
            // Fetch tour statistics in background (non-blocking)
            Task {
                await fetchTourStatistics()
            }
            
        } catch {
            print("❌ [Component A] Failed to load from single source: \(error)")
            handleError(error)
            setLoading(false)
            return
        }
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
        
        // Set loading state for tour statistics
        isTourStatisticsLoading = true
        
        // Handle tour change detection for current tour optimization
        if let tourName = enhanced.tourPosition?.tourName {
            CacheManager.shared.handleTourChange(newTourName: tourName)
        }
        
        // Check for current tour stats cache first (Dashboard optimization)
        if let cachedStats = CacheManager.shared.get(TourSongStatistics.self, forKey: CacheManager.CacheKeys.currentTourStats) {
            print("⚡ Using cached current tour statistics (dashboard optimization)")
            await MainActor.run {
                tourStatistics = cachedStats
                isTourStatisticsLoading = false
            }
            return
        }
        
        do {
            // Fetch tour statistics from Vercel server (replaces local calculations)
            print("🌐 Fetching tour statistics from server...")
            let statistics = try await TourStatisticsAPIClient.shared.fetchTourStatistics()
            
            // Cache current tour statistics for dashboard optimization (1 hour TTL)
            CacheManager.shared.set(statistics, forKey: CacheManager.CacheKeys.currentTourStats, ttl: CacheManager.TTL.currentTourStats)
            print("💾 Cached current tour statistics for fast dashboard loading")
            
            // Update published property on main actor
            tourStatistics = statistics
            
        } catch {
            // Log error but don't block main functionality
            print("Failed to fetch tour statistics: \(error)")
            tourStatistics = nil
        }
        
        // Clear loading state
        isTourStatisticsLoading = false
    }
    
    
} 
