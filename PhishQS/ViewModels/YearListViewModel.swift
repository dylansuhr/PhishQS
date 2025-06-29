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
        self.years = (1983...2025)
            .filter { ![2005, 2006, 2007].contains($0) }
            .map { String($0) }
            .reversed()
    }
}
