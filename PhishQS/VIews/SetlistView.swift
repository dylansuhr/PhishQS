import SwiftUI

struct SetlistView: View {
    let year: String
    let month: String
    let day: String

    @StateObject private var viewModel = SetlistViewModel()

    var body: some View {
        let paddedMonth = month.count == 1 ? "0\(month)" : month
        let paddedDay = day.count == 1 ? "0\(day)" : day
        let date = "\(year)-\(paddedMonth)-\(paddedDay)"

        ScrollView {
            if viewModel.setlist.isEmpty {
                ProgressView()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.setlist, id: \.self) { line in
                        Text(line)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            print("🗓️ Fetching setlist for date: \(date)")
            viewModel.fetchSetlist(for: date)
        }
        .navigationTitle(date)
    }
}
