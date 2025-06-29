//
//  MonthListViewModel.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/27/25.
//


import Foundation

class MonthListViewModel: ObservableObject {
    @Published var months: [String] = []

    func fetchMonths(for year: String) {
        let apiKey = Secrets.value(for: "PhishNetAPIKey")

        guard let url = URL(string: "https://api.phish.net/v5/setlists/showyear/\(year).json?apikey=\(apiKey)") else {
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

                let monthNumbers = Set(decoded.data.compactMap { show in
                    let components = show.showdate.split(separator: "-")
                    return components.count > 1 ? String(components[1]) : nil
                })

                let formatter = DateFormatter()
                formatter.dateFormat = "MM"
                let sortedMonths = monthNumbers.compactMap { num -> (String, Int)? in
                    guard let date = formatter.date(from: num) else { return nil }
                    formatter.dateFormat = "MMMM"
                    let name = formatter.string(from: date)
                    formatter.dateFormat = "MM"
                    let index = Int(num) ?? 0
                    return (name, index)
                }
                .sorted { $0.1 < $1.1 }
                .map { $0.0 }

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
