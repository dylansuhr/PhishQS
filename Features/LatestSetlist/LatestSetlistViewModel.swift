import Foundation
import SwiftUI

// ViewModel for fetching and managing the latest Phish setlist with navigation support
class LatestSetlistViewModel: BaseViewModel {
    @Published var latestShow: Show?
    @Published var setlistItems: [SetlistItem] = []
    @Published var enhancedSetlist: EnhancedSetlist?
    @Published var tourStatistics: TourSongStatistics?
    @Published var isTourStatisticsLoading: Bool = false
    
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
                
                // Cache shows for navigation
                await loadShowsForYear(show.showyear)
                updateNavigationState()
                
                // Set loading false first to show main content
                setLoading(false)
                
                // Fetch tour statistics in background (non-blocking)
                Task {
                    await fetchTourStatistics()
                }
            } else {
                errorMessage = "Still waiting..."
                setLoading(false)
            }
        } catch {
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
            
            currentShowIndex = index
            updateNavigationState()
            
            // Update tour statistics for new show in background (non-blocking)
            Task {
                await fetchTourStatistics()
            }
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
    
    // MARK: - Gap Chart API Testing (Temporary)
    
    /// Test potential gap chart API endpoints - temporary method for research
    @MainActor
    func testGapChartAPI() async {
        guard let show = latestShow else {
            print("❌ No show available for testing")
            return
        }
        
        await testGapChartEndpoints(for: show.showdate)
    }
    
    /// Test potential gap chart API endpoints to see if any exist
    private func testGapChartEndpoints(for showDate: String) async {
        let baseURL = "https://api.phish.net/v5"
        let apiKey = Secrets.value(for: "PhishNetAPIKey")
        
        let potentialEndpoints = [
            "/setlists/gap-chart/\(showDate).json",
            "/shows/\(showDate)/gaps.json",
            "/setlists/\(showDate)/gaps.json",
            "/gap-chart/\(showDate).json",
            "/setlists/get/\(showDate).json?include_gaps=true",
            "/setlists/show/\(showDate).json?gaps=true"
        ]
        
        print("🔍 Testing Gap Chart API Endpoints for \(showDate)")
        print("==================================================")
        
        for endpoint in potentialEndpoints {
            await testEndpoint(baseURL + endpoint + "?apikey=\(apiKey)")
        }
        
        print("==================================================")
        print("✅ Gap Chart API endpoint testing complete")
    }
    
    /// Test a specific endpoint and report results
    private func testEndpoint(_ urlString: String) async {
        let endpointPath = urlString.components(separatedBy: "api.phish.net/v5").last?.components(separatedBy: "?").first ?? "unknown"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(endpointPath)")
            return
        }
        
        do {
            let request = URLRequest(url: url)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ \(endpointPath) - Invalid response")
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                print("✅ \(endpointPath) - SUCCESS! (Response size: \(data.count) bytes)")
                
                // Try to parse as JSON to see structure
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                    if let dict = jsonObject as? [String: Any] {
                        print("   📋 Response keys: \(Array(dict.keys).joined(separator: ", "))")
                        
                        // Look for gap-related fields
                        let gapKeys = dict.keys.filter { key in
                            key.lowercased().contains("gap") || 
                            key.lowercased().contains("last") ||
                            key.lowercased().contains("previous")
                        }
                        
                        if !gapKeys.isEmpty {
                            print("   🎯 Gap-related keys found: \(gapKeys.joined(separator: ", "))")
                        }
                    }
                }
                
            case 403:
                print("🚫 \(endpointPath) - 403 Forbidden (may need different permissions)")
                
            case 404:
                print("📭 \(endpointPath) - 404 Not Found (endpoint doesn't exist)")
                
            default:
                print("⚠️  \(endpointPath) - HTTP \(httpResponse.statusCode)")
            }
            
        } catch {
            print("💥 \(endpointPath) - Error: \(error.localizedDescription)")
        }
    }
    
    /// Optimized tour enhanced setlists fetching with comprehensive caching
    private func fetchTourEnhancedSetlistsOptimized(
        tourName: String, 
        currentShow: EnhancedSetlist
    ) async -> [EnhancedSetlist] {
        
        let cacheKey = CacheManager.CacheKeys.tourEnhancedSetlists(tourName)
        let currentDate = currentShow.showDate
        
        // Check if we have cached tour setlists
        if let cachedTourShows = CacheManager.shared.get([EnhancedSetlist].self, forKey: cacheKey) {
            print("📦 Found cached tour setlists for \(tourName)")
            
            // Filter to current date and check if we need to add new show
            let upToDateShows = cachedTourShows.filter { $0.showDate <= currentDate }
            let hasCurrentShow = upToDateShows.contains { $0.showDate == currentDate }
            
            if hasCurrentShow {
                print("✅ Current show already in cache, using cached data (\(upToDateShows.count) shows)")
                return upToDateShows
            } else {
                print("🔄 Adding current show to cached tour data")
                let updatedShows = (upToDateShows + [currentShow]).sorted { $0.showDate < $1.showDate }
                
                // Update cache with new show added
                CacheManager.shared.set(updatedShows, forKey: cacheKey, ttl: CacheManager.TTL.tourEnhancedSetlists)
                return updatedShows
            }
        }
        
        // No cache - fetch full tour data
        print("🔄 Fetching fresh tour setlists for \(tourName)")
        
        do {
            // Extract year from current show date
            let year = String(currentDate.prefix(4))
            
            // Get all tour shows
            let allTourShows = try await apiManager.fetchTourShows(tourName: tourName, year: year)
            let showsUpToCurrent = allTourShows.filter { $0.showdate <= currentDate }
            
            print("📊 Processing \(showsUpToCurrent.count) shows from \(tourName)")
            
            // Fetch enhanced setlists with individual caching
            var enhancedTourShows: [EnhancedSetlist] = []
            for show in showsUpToCurrent {
                do {
                    let enhancedShow = try await apiManager.fetchEnhancedSetlist(for: show.showdate)
                    enhancedTourShows.append(enhancedShow)
                } catch {
                    print("Warning: Could not fetch enhanced setlist for \(show.showdate): \(error)")
                }
            }
            
            let sortedShows = enhancedTourShows.sorted { $0.showDate < $1.showDate }
            
            // Cache the full tour collection
            CacheManager.shared.set(sortedShows, forKey: cacheKey, ttl: CacheManager.TTL.tourEnhancedSetlists)
            
            print("✅ Successfully loaded and cached \(sortedShows.count) enhanced setlists from \(tourName)")
            return sortedShows
            
        } catch {
            print("Warning: Could not fetch tour shows for \(tourName): \(error)")
            print("🔄 Falling back to single-show gap calculation")
            return [currentShow]
        }
    }
    
} 
