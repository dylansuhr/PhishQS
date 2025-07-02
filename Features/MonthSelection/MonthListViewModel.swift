import Foundation

// ViewModel for listing available months in a given year
class MonthListViewModel: ObservableObject {
    // holds month strings like "01", "02", ..., "12"
    @Published var months: [String] = []

    // fetch all months where Phish played in the given year
    func fetchMonths(for year: String) {
        // pull API key from local Secrets.swift file
        let apiKey = Secrets.value(for: "PhishNetAPIKey")

        // build the request URL for all shows in the selected year
        guard let url = URL(string: "https://api.phish.net/v5/setlists/showyear/\(year).json?apikey=\(apiKey)&artist=phish") else {
            print("Invalid URL or missing API key")
            return
        }

        // perform the network request
        URLSession.shared.dataTask(with: url) { data, _, error in
            // if network call fails, print the error and exit
            if let error = error {
                print("Network error: \(error)")
                return
            }

            // no data returned
            guard let data = data else {
                print("No data received")
                return
            }

            do {
                // try to decode into ShowResponse (array of shows)
                let decoded = try JSONDecoder().decode(ShowResponse.self, from: data)

                // extract month integers from showdate strings
                let monthInts = Set(decoded.data
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

                // push result back to UI on main thread
                DispatchQueue.main.async {
                    self.months = sortedMonths
                }
            } catch {
                // decoding failed — helpful debug info
                print("JSON decoding error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("Raw JSON:\n\(raw)")
                }
            }
        }.resume() // start the network task
    }
}
