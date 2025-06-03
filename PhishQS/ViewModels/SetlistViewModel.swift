//
//  SetlistViewModel.swift
//  PhishQS
//
//  Created by Dylan Suhr on 6/2/25.
//


import Foundation

final class SetlistViewModel: ObservableObject {
    @Published var setlist: [String] = []

    func fetchSetlist(for date: String) {
        // TEMP: dummy data, will replace with API call
        self.setlist = [
            "Madison Square Garden",
            "New York, NY",
            "Set 1: Sample in a Jar > Wilson",
            "Set 2: Tweezer > Light",
            "Encore: Loving Cup"
        ]
    }
}

