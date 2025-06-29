import Foundation

struct Show: Codable, Identifiable {
    let id: Int
    let showdate: String
    let venue: String?
    let city: String?
    let state: String?
    let country: String?
    let setlistdata: String?
}

class PhishAPIClient {
    static let shared = PhishAPIClient()

    private let baseURL = "https://api.phish.net/v5"
    private let apiKey = Secrets.value(for: "PhishNetAPIKey")

    func fetchShows(forYear year: String, completion: @escaping ([Show]) -> Void) {
        guard let url = URL(string: "\(baseURL)/setlists/showyear/\(year).json?apikey=\(apiKey)") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("API error:", error)
                return
            }

            guard let data = data else {
                print("No data received.")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([String: [Show]].self, from: data)
                let shows = decoded["data"] ?? []
                DispatchQueue.main.async {
                    completion(shows)
                }
            } catch {
                print("JSON decoding failed:", error)
            }
        }.resume()
    }
}
