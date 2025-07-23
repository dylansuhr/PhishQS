import Foundation

// ViewModel for listing available days for a selected year and month
class DayListViewModel: BaseViewModel {
    @Published var days: [String] = []
    
    private let apiClient: PhishAPIService
    
    // MARK: - Initialization
    
    init(apiClient: PhishAPIService = PhishAPIClient.shared) {
        self.apiClient = apiClient
    }

    // fetch all show days for a given year and month
    @MainActor
    func fetchDays(for year: String, month: String) async {
        setLoading(true)
        
        do {
            let shows = try await apiClient.fetchShows(forYear: year)
            days = DateUtilities.extractDays(from: shows, forYear: year, month: month)
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
    
    // Non-async wrapper for SwiftUI compatibility
    func fetchDays(for year: String, month: String) {
        Task {
            await fetchDays(for: year, month: month)
        }
    }
}
