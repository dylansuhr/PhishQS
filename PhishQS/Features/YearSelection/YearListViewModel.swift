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

    // called onAppear in YearListView to load hardcoded valid years
    func fetchYears() {
        self.years = (1983...2025) // full Phish history
            .filter { ![2005, 2006, 2007].contains($0) } // skip the hiatus years
            .map { String($0) } // convert to strings for display / navigation
            .reversed() // newest year first (2025 → 1983)
    }
}
