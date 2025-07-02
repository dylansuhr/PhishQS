import Foundation

// ViewModel that fetches and holds the setlist data for a specific show date
class SetlistViewModel: ObservableObject {
    // holds the lines of the setlist (e.g. ["Jam", "My Soul", "Ocelot →"])
    @Published var setlist: [String] = []

    // called when user selects a specific date (YYYY-MM-DD)
    func fetchSetlist(for date: String) {
        let apiKey = Secrets.value(for: "PhishNetAPIKey") // pull from Secrets.swift

        // build the URL using date and API key
        guard let url = URL(string: "https://api.phish.net/v5/setlists/showdate/\(date).json?apikey=\(apiKey)&artist=phish") else {
            print("Invalid URL")
            return
        }

        // async fetch from Phish.net
        URLSession.shared.dataTask(with: url) { data, _, error in
            // network-level error
            if let error = error {
                print("❌ Network error: \(error)")
                return
            }

            // no data returned
            guard let data = data else {
                print("❌ No data")
                return
            }

            do {
                // decode JSON into our custom SetlistResponse model
                let decoded = try JSONDecoder().decode(SetlistResponse.self, from: data)

                // build displayable lines from each song in the setlist
                let lines = decoded.data.map { item in
                    var line = "\(item.song)" // start with just the song name
                    if let mark = item.transMark, !mark.isEmpty {
                        line += " \(mark)" // add arrow, segue, etc if exists
                    }
                    return line
                }

                // update on main thread to refresh UI
                DispatchQueue.main.async {
                    self.setlist = lines
                }

            } catch {
                // decoding error — print full raw JSON for debugging
                print("❌ JSON decoding error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("📦 Raw JSON:\n\(raw)")
                }
            }
        }.resume() // start the network call
    }
}
