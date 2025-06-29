//
//  SetlistView.swift
//  PhishQS
//
//  Created by Dylan Suhr on 5/29/25.
//


import SwiftUI

struct SetlistView: View {
    let date: String
    @StateObject private var viewModel = SetlistViewModel()

    var body: some View {
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
            print("📅 Fetching setlist for date: \(date)")
            viewModel.fetchSetlist(for: date)
        }
        .navigationTitle(date)
    }
}

