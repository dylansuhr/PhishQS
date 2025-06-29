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

