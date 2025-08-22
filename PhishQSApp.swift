//
//  PhishQSApp.swift
//  PhishQS
//
//  Created by Dylan Suhr on 5/28/25.
//

import SwiftUI

// entry point for the app
@main
struct PhishQSApp: App {
    var body: some Scene {
        WindowGroup {
            // embed the entire app in a NavigationStack for easy push-style navigation
            NavigationStack {
                TourDashboardView() // start at the tour dashboard home screen
            }
        }
    }
}
