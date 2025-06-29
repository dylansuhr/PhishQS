//
//  YearListViewModel.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/27/25.
//

import Foundation

class YearListViewModel: ObservableObject {
    @Published var years: [String] = []

    func fetchYears() {
        guard let url = URL(string: "https://api.phish.net/v5/setlists.json?apikey=\(Secrets.value(for: "PhishNetAPIKey"))") else {
            print("Invalid URL")
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
                let years = Set(decoded.data.map { $0.showyear })
                let sortedYears = years.sorted(by: >)

                DispatchQueue.main.async {
                    self.years = sortedYears
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
