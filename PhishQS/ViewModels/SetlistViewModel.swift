import Foundation

final class SetlistViewModel: ObservableObject {
    @Published var setlist: [String] = []

    func fetchSetlist(for date: String) {
        let urlString = "https://api.phish.net/v5/setlists/showdate/\(date).json?apikey=\(Secrets.value(for: "PhishNetAPIKey"))"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Network error: \(error)")
                return
            }

            guard let data = data else {
                print("❌ No data received")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([String: [SetlistItem]].self, from: data)
                let songs = decoded["data"] ?? []

                var formattedSetlist: [String] = []
                var currentSet = ""

                for song in songs {
                    if song.set != currentSet {
                        currentSet = song.set
                        formattedSetlist.append("Set \(currentSet.uppercased()):")
                    }

                    let title = song.song
                    let transition = song.transMark ?? ""
                    formattedSetlist.append("- \(title)\(transition)")
                }

                DispatchQueue.main.async {
                    self.setlist = formattedSetlist
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
