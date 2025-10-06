import Foundation

// ViewModel for listing available months in a given year
class MonthListViewModel: BaseViewModel {
    @Published var months: [String] = []
    @Published var shows: [Show] = [] // Store shows for passing to DayListView

    private let apiManager: APIManager

    // MARK: - Initialization

    init(apiManager: APIManager = APIManager.shared) {
        self.apiManager = apiManager
    }

    // fetch all months where Phish played in the given year with caching
    @MainActor
    func fetchMonths(for year: String) async {
        setLoading(true)

        do {
            // Use cached fetch to avoid duplicate API calls
            let fetchedShows = try await apiManager.fetchShowsWithCache(forYear: year)
            shows = fetchedShows
            months = DateUtilities.extractMonths(from: fetchedShows, forYear: year)
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
