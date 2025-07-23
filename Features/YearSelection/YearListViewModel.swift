//
//  YearListViewModel.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/27/25.
//

import Foundation

// ViewModel for listing all valid Phish years
class YearListViewModel: ObservableObject {
    // holds years as strings like "2025", "2024", ..., "1983"
    @Published var years: [String] = []

    // called onAppear in YearListView to load valid years dynamically
    func fetchYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        self.years = (1983...currentYear) // full Phish history up to current year
            .filter { ![2005, 2006, 2007].contains($0) } // skip the hiatus years
            .map { String($0) } // convert to strings for display / navigation
            .reversed() // newest year first (current year → 1983)
    }
}
