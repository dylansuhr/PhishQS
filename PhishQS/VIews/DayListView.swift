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
            let formattedDay = String(format: "%02d", Int(day) ?? 1)
            let formattedDate = "\(year)-\(monthNumber(from: month))-\(formattedDay)"
            NavigationLink(destination: SetlistView(date: formattedDate)) {
                Text(day)
            }
        }
        .onAppear {
            viewModel.fetchDays(for: year, month: month)
        }
        .navigationTitle("\(month) \(year)")
    }

    private func monthNumber(from name: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        if let date = formatter.date(from: name) {
            formatter.dateFormat = "MM"
            return formatter.string(from: date)
        }
        return "01" // default fallback
    }
}

class DayListViewModel: ObservableObject {
    @Published var days: [String] = []

    func fetchDays(for year: String, month: String) {
        // TODO: Replace with actual API call to get shows in year+month and extract days
        self.days = ["30", "31"] // Dummy day values — no month names here
    }
}

