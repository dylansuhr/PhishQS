//
//  DayListView.swift
//  PhishQS
//
//  Created by Dylan Suhr on 5/29/25.
//


import SwiftUI

struct DayListView: View {
    let year: String
    let month: String
    @StateObject private var viewModel = DayListViewModel()

    var body: some View {
        List(viewModel.days, id: \.self) { day in
            NavigationLink(destination: SetlistView(date: day)) {
                Text(day)
            }
        }
        .onAppear {
            viewModel.fetchDays(for: year, month: month)
        }
        .navigationTitle("\(month) \(year)")
    }
}

class DayListViewModel: ObservableObject {
    @Published var days: [String] = []

    func fetchDays(for year: String, month: String) {
        // TODO: Replace with actual API call to get shows in year+month and extract days
        self.days = ["December 30", "December 31"] // Dummy data
    }
}
