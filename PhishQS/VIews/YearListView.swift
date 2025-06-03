//
//  YearListView.swift
//  PhishQS
//
//  Created by Dylan Suhr on 5/29/25.
//

import SwiftUI

struct YearListView: View {
    @StateObject private var viewModel = YearListViewModel()

    var body: some View {
        List(viewModel.years, id: \.self) { year in
            NavigationLink(destination: MonthListView(year: year)) {
                Text(year)
            }
        }
        .onAppear {
            viewModel.fetchYears()
        }
        .navigationTitle("Select Year")
    }
}

class YearListViewModel: ObservableObject {
    @Published var years: [String] = []

    func fetchYears() {
        // TODO: Replace with actual Phish.net API call
        self.years = ["2024", "2023", "2022", "2021"] // Dummy data
    }
}

