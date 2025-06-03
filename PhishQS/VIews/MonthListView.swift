//
//  MonthListView.swift
//  PhishQS
//
//  Created by Dylan Suhr on 5/29/25.
//


import SwiftUI

struct MonthListView: View {
    let year: String
    @StateObject private var viewModel = MonthListViewModel()

    var body: some View {
        List(viewModel.months, id: \.self) { month in
            NavigationLink(destination: DayListView(year: year, month: month)) {
                Text(month)
            }
        }
        .onAppear {
            viewModel.fetchMonths(for: year)
        }
        .navigationTitle("\(year)")
    }
}

class MonthListViewModel: ObservableObject {
    @Published var months: [String] = []

    func fetchMonths(for year: String) {
        // TODO: Replace with actual API call to get shows in year and extract months
        self.months = ["December", "November", "October"] // Dummy data
    }
}
