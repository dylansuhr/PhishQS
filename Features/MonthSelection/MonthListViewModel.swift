import Foundation

// ViewModel for listing available months in a given year
class MonthListViewModel: BaseViewModel {
    @Published var months: [String] = []
    
    private let apiClient: any PhishAPIService
    
    // MARK: - Initialization
    
    init(apiClient: any PhishAPIService = PhishAPIClient.shared) {
        self.apiClient = apiClient
    }

    // fetch all months where Phish played in the given year
    @MainActor
    func fetchMonths(for year: String) async {
        setLoading(true)
        
        do {
            let shows = try await apiClient.fetchShows(forYear: year)
            months = DateUtilities.extractMonths(from: shows, forYear: year)
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
    
    // Non-async wrapper for SwiftUI compatibility
    func fetchMonths(for year: String) {
        Task {
            await fetchMonths(for: year)
        }
    }
}
