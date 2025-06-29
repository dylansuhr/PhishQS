import Foundation

class SetlistViewModel: ObservableObject {
    @Published var setlist: [String] = []

    func fetchSetlist(for date: String) {
        let apiKey = Secrets.value(for: "PhishNetAPIKey")

        guard let url = URL(string: "https://api.phish.net/v5/setlists/showdate/\(date).json?apikey=\(apiKey)&artist=phish") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Network error: \(error)")
                return
            }

            guard let data = data else {
                print("❌ No data")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SetlistResponse.self, from: data)
                let lines = decoded.data.map { item in
                    var line = "\(item.song)"
                    if let mark = item.transMark, !mark.isEmpty {
                        line += " \(mark)"
                    }
                    return line
                }

                DispatchQueue.main.async {
                    self.setlist = lines
                }
            } catch {
                print("❌ JSON decoding error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("📦 Raw JSON:\n\(raw)")
                }
            }
        }.resume()
    }
}
