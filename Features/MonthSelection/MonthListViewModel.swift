import Foundation

// ViewModel for listing available months in a given year
class MonthListViewModel: ObservableObject {
    // holds month strings like "01", "02", ..., "12"
    @Published var months: [String] = []
    @Published var errorMessage: String?

    private let apiClient: PhishAPIService
    
    // MARK: - Initialization
    
    init(apiClient: PhishAPIService = PhishAPIClient.shared) {
        self.apiClient = apiClient
    }

    // fetch all months where Phish played in the given year
    @MainActor
    func fetchMonths(for year: String) async {
        do {
            let shows = try await apiClient.fetchShows(forYear: year)
            
            // extract month integers from showdate strings
            let monthInts = Set(shows
                // only include Phish shows (just in case others sneak in)
                .filter { $0.artist_name.lowercased() == "phish" }
                .compactMap { show in
                    // split "YYYY-MM-DD" and grab MM as Int
                    let components = show.showdate.split(separator: "-")
                    return components.count > 1 ? Int(components[1]) : nil
                })

            // sort month numbers and pad them as "01", "02", ..., "12"
            let sortedMonths = monthInts.sorted().map {
                String(format: "%02d", $0)
            }

            months = sortedMonths
            errorMessage = nil
            
        } catch {
            errorMessage = error.localizedDescription
            print("API error: \(error)")
        }
    }
    
    // Non-async wrapper for SwiftUI compatibility
    func fetchMonths(for year: String) {
        Task {
            await fetchMonths(for: year)
        }
    }
}
