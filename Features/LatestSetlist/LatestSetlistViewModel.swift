import Foundation

// ViewModel for fetching and managing the latest Phish setlist with navigation support
class LatestSetlistViewModel: BaseViewModel {
    @Published var latestShow: Show?
    @Published var setlistItems: [SetlistItem] = []
    @Published var enhancedSetlist: EnhancedSetlist?
    
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
} 
