import Foundation

// ViewModel that fetches and holds the setlist data for a specific show date
class SetlistViewModel: BaseViewModel {
    @Published var setlist: [String] = []
    @Published var setlistItems: [SetlistItem] = []
    @Published var enhancedSetlist: EnhancedSetlist?
    
    private let apiManager: APIManager
    
    // MARK: - Initialization
    
    init(apiManager: APIManager = APIManager()) {
        self.apiManager = apiManager
    }

    // called when user selects a specific date (YYYY-MM-DD)
    @MainActor
    func fetchSetlist(for date: String) async {
        setLoading(true)
        
        do {
            // Fetch enhanced setlist with song durations and venue run info
            let enhanced = try await apiManager.fetchEnhancedSetlist(for: date)
            enhancedSetlist = enhanced
            setlistItems = enhanced.setlistItems
            setlist = StringFormatters.formatSetlist(enhanced.setlistItems)
            setLoading(false)
        } catch {
            handleError(error)
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
        return enhancedSetlist?.trackDurations.first { $0.songName == song }?.durationSeconds
    }
    
    /// Get formatted duration string for a specific song, if available
    func formattedDuration(for song: String) -> String? {
        return enhancedSetlist?.trackDurations.first { $0.songName == song }?.formattedDuration
    }
    
    /// Get venue run information (N1/N2/N3), if available
    var venueRunInfo: VenueRun? {
        return enhancedSetlist?.venueRun
    }
    
    /// Get available recordings, if any
    var recordings: [Recording] {
        return enhancedSetlist?.recordings ?? []
    }
    
    /// Check if enhanced data is available
    var hasEnhancedData: Bool {
        return enhancedSetlist != nil
    }
}
