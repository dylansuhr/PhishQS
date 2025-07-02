import Foundation

// represents a single Phish show returned from the showyear endpoint
struct Show: Codable, Identifiable {
    let id: Int                    // unique show ID
    let showdate: String           // "YYYY-MM-DD"
    let venue: String?             // venue name (optional)
    let city: String?              // city name (optional)
    let state: String?             // state abbreviation (optional)
    let country: String?           // country name (optional)
    let setlistdata: String?       // full setlist as string (optional)
}

// handles making API requests to phish.net
class PhishAPIClient {
    static let shared = PhishAPIClient()  // singleton instance

    private let baseURL = "https://api.phish.net/v5"
    private let apiKey = Secrets.value(for: "PhishNetAPIKey")

    // fetch all shows for a given year
    func fetchShows(forYear year: String, completion: @escaping ([Show]) -> Void) {
        guard let url = URL(string: "\(baseURL)/setlists/showyear/\(year).json?apikey=\(apiKey)") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            // handle networking errors
            if let error = error {
                print("API error:", error)
                return
            }

            // make sure we got a response
            guard let data = data else {
                print("No data received.")
                return
            }

            do {
                // parse response into [String: [Show]], then grab the 'data' array
                let decoded = try JSONDecoder().decode([String: [Show]].self, from: data)
                let shows = decoded["data"] ?? []

                // send shows back on main thread
                DispatchQueue.main.async {
                    completion(shows)
                }
            } catch {
                print("JSON decoding failed:", error)
            }
        }.resume()
    }
}
