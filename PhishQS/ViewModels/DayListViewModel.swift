//
//  DayListViewModel.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/27/25.
//

import Foundation

class DayListViewModel: ObservableObject {
    @Published var days: [String] = []

    func fetchDays(for year: String, month: String) {
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

                let uniqueDates = Set(decoded.data
                    .filter { $0.artist_name.lowercased() == "phish" }
                    .map { $0.showdate })

                let dayStrings = uniqueDates.compactMap { date -> String? in
                    let components = date.split(separator: "-")
                    guard components.count == 3 else { return nil }
                    let showYear = String(components[0])
                    let showMonth = String(components[1])
                    let showDay = String(components[2])
                    print("🧪 showdate: \(date) → year: \(showYear), month: \(showMonth), day: \(showDay)")
                    return (showYear == year && showMonth == month) ? showDay : nil
                }

                let sortedDays = dayStrings.compactMap { Int($0) }.sorted().map {
                    let padded = String(format: "%02d", $0)
                    return padded
                }

                DispatchQueue.main.async {
                    self.days = sortedDays
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
