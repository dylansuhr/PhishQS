import Foundation

// ViewModel for listing available days for a selected year and month
class DayListViewModel: BaseViewModel {
    @Published var days: [String] = []

    private let shows: [Show]  // Cached shows from parent view

    // MARK: - Initialization

    init(shows: [Show]) {
        self.shows = shows
    }

    // extract all show days for a given year and month from cached data
    @MainActor
    func fetchDays(for year: String, month: String) async {
        setLoading(true)

        // No API call - use cached shows
        days = DateUtilities.extractDays(from: shows, forYear: year, month: month)
        setLoading(false)
    }
    
    // Non-async wrapper for SwiftUI compatibility
    func fetchDays(for year: String, month: String) {
        Task {
            await fetchDays(for: year, month: month)
        }
    }
}
