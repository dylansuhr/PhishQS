import Foundation

// ViewModel for fetching and managing the latest Phish setlist
class LatestSetlistViewModel: BaseViewModel {
    @Published var latestShow: Show?
    @Published var setlistItems: [SetlistItem] = []
    
    private let apiClient: PhishAPIService
    
    // MARK: - Initialization
    
    init(apiClient: PhishAPIService = PhishAPIClient.shared) {
        self.apiClient = apiClient
    }
    
    // Fetch the latest show and its setlist
    @MainActor
    func fetchLatestSetlist() async {
        setLoading(true)
        
        do {
            if let show = try await apiClient.fetchLatestShow() {
                latestShow = show
                setlistItems = try await apiClient.fetchSetlist(for: show.showdate)
            } else {
                errorMessage = "No recent shows found"
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
    
    // Format the setlist for display
    var formattedSetlist: [String] {
        return StringFormatters.formatSetlist(setlistItems)
    }
} 
