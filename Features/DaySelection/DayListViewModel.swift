import Foundation

// ViewModel for listing available days for a selected year and month
class DayListViewModel: ObservableObject {
    // published list of days (as strings like "01", "02", etc.)
    @Published var days: [String] = []
    @Published var errorMessage: String?

    private let apiClient: PhishAPIService
    
    // MARK: - Initialization
    
    init(apiClient: PhishAPIService = PhishAPIClient.shared) {
        self.apiClient = apiClient
    }

    // fetch all show days for a given year and month
    @MainActor
    func fetchDays(for year: String, month: String) async {
        do {
            let shows = try await apiClient.fetchShows(forYear: year)
            
            // get unique show dates for Phish only (some entries might be other artists)
            let uniqueDates = Set(shows
                .filter { $0.artist_name.lowercased() == "phish" }
                .map { $0.showdate })

            // extract the day portion of dates that match the selected year and month
            let dayStrings = uniqueDates.compactMap { date -> String? in
                let components = date.split(separator: "-")  // e.g. ["2025", "06", "28"]
                guard components.count == 3 else { return nil }
                let showYear = String(components[0])
                let showMonth = String(components[1])
                let showDay = String(components[2])

                // debug print to verify what's being parsed
                print("🧪 showdate: \(date) → year: \(showYear), month: \(showMonth), day: \(showDay)")

                // only return day if it matches the selected year + month
                return (showYear == year && showMonth == month) ? showDay : nil
            }

            // sort days numerically, then pad each with leading zero (i.e. "1" → "01")
            let sortedDays = dayStrings
                .compactMap { Int($0) }        // convert to Int for sorting
                .sorted()                      // sort numeric ascending
                .map { String(format: "%02d", $0) } // back to string w/ leading 0

            days = sortedDays
            errorMessage = nil
            
        } catch {
            errorMessage = error.localizedDescription
            print("API error: \(error)")
        }
    }
    
    // Non-async wrapper for SwiftUI compatibility
    func fetchDays(for year: String, month: String) {
        Task {
            await fetchDays(for: year, month: month)
        }
    }
}
