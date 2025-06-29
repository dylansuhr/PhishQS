import Foundation

class MonthListViewModel: ObservableObject {
    @Published var months: [String] = []

    func fetchMonths(for year: String) {
        let apiKey = Secrets.value(for: "PhishNetAPIKey")

        guard let url = URL(string: "https://api.phish.net/v5/setlists/showyear/\(year).json?apikey=\(apiKey)&artist=phish") else {
            print("Invalid URL or missing API key")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Network error: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ShowResponse.self, from: data)

                let monthInts = Set(decoded.data
                    .filter { $0.artist_name.lowercased() == "phish" }
                    .compactMap { show in
                        let components = show.showdate.split(separator: "-")
                        return components.count > 1 ? Int(components[1]) : nil
                    })

                let sortedMonths = monthInts.sorted().map { String(format: "%02d", $0) }

                DispatchQueue.main.async {
                    self.months = sortedMonths
                }
            } catch {
                print("JSON decoding error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("Raw JSON:\n\(raw)")
                }
            }
        }.resume()
    }
}
