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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            // Use smart launch view for state-aware loading
            SmartLaunchView()
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    LaunchStateManager.shared.handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
        }
    }
}
