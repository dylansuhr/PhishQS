import Foundation

// ViewModel for listing available days for a selected year and month
class DayListViewModel: ObservableObject {
    // published list of days (as strings like "01", "02", etc.)
    @Published var days: [String] = []

    // fetch all show days for a given year and month
    func fetchDays(for year: String, month: String) {
        // get API key from Secrets.swift (stored locally, not checked in)
        let apiKey = Secrets.value(for: "PhishNetAPIKey")

        // construct request URL to hit the year-level endpoint
        guard let url = URL(string: "https://api.phish.net/v5/setlists/showyear/\(year).json?apikey=\(apiKey)&artist=phish") else {
            print("Invalid URL or missing API key")
            return
        }

        // perform the API request
        URLSession.shared.dataTask(with: url) { data, _, error in
            // network request failed
            if let error = error {
                print("Network error: \(error)")
                return
            }

            // no response data received
            guard let data = data else {
                print("No data received")
                return
            }

            do {
                // decode into our ShowResponse model (array of show metadata)
                let decoded = try JSONDecoder().decode(ShowResponse.self, from: data)

                // get unique show dates for Phish only (some entries might be other artists)
                let uniqueDates = Set(decoded.data
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

                // update the published days list on the main thread
                DispatchQueue.main.async {
                    self.days = sortedDays
                }
            } catch {
                // failed to decode JSON — print raw response for debugging
                print("JSON decoding error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("Raw JSON:\n\(raw)")
                }
            }
        }.resume() // actually starts the network task
    }
}
