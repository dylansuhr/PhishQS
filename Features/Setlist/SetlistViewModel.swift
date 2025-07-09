import Foundation

// ViewModel that fetches and holds the setlist data for a specific show date
class SetlistViewModel: ObservableObject {
    // holds the lines of the setlist (e.g. ["Jam", "My Soul", "Ocelot →"])
    @Published var setlist: [String] = []
    @Published var errorMessage: String?

    private let apiClient: PhishAPIService
    
    // MARK: - Initialization
    
    init(apiClient: PhishAPIService = PhishAPIClient.shared) {
        self.apiClient = apiClient
    }

    // called when user selects a specific date (YYYY-MM-DD)
    @MainActor
    func fetchSetlist(for date: String) async {
        do {
            let setlistItems = try await apiClient.fetchSetlist(for: date)
            
            // build displayable lines from each song in the setlist
            let lines = setlistItems.map { item in
                var line = "\(item.song)" // start with just the song name
                if let mark = item.transMark, !mark.isEmpty {
                    line += " \(mark)" // add arrow, segue, etc if exists
                }
                return line
            }

            setlist = lines
            errorMessage = nil
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ API error: \(error)")
        }
    }
    
    // Non-async wrapper for SwiftUI compatibility
    func fetchSetlist(for date: String) {
        Task {
            await fetchSetlist(for: date)
        }
    }
}
