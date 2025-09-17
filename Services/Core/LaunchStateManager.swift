//
//  LaunchStateManager.swift
//  PhishQS
//
//  Manages app launch state detection for consistent launch experience
//  Determines if app is cold starting, warm starting, or returning from background
//

import Foundation
import SwiftUI

class LaunchStateManager: ObservableObject {
    static let shared = LaunchStateManager()

    @Published var launchType: LaunchType = .coldStart
    @Published var hasCompletedInitialLoad = false

    private let processStartTime = Date()
    private var backgroundTime: Date?
    private let launchTimeThreshold: TimeInterval = 5.0 // seconds to determine cold vs warm
    private let backgroundReturnThreshold: TimeInterval = 30.0 // seconds to skip loading screen

    enum LaunchType {
        case coldStart      // First launch or app was killed
        case warmStart      // Recently launched, still in memory
        case backgroundReturn // Returning from background
    }

    private init() {}

    func determineLaunchType() -> LaunchType {
        // Check if returning from background
        if let bgTime = backgroundTime {
            let backgroundDuration = Date().timeIntervalSince(bgTime)
            backgroundTime = nil // Reset after checking

            if backgroundDuration < backgroundReturnThreshold {
                return .backgroundReturn // Quick return, skip loading
            } else {
                return .warmStart // Longer background, treat as warm start
            }
        }

        // Check process uptime for warm vs cold
        let timeSinceLaunch = Date().timeIntervalSince(processStartTime)
        if timeSinceLaunch < launchTimeThreshold {
            // If we're checking within 5 seconds of process start, it's a cold launch
            return .coldStart
        }

        // Check if initial load already completed
        if hasCompletedInitialLoad {
            return .warmStart
        }

        return .coldStart
    }

    func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch (oldPhase, newPhase) {
        case (.background, .active):
            // Returning from background
            launchType = determineLaunchType()

        case (.active, .background):
            // Going to background, record time
            backgroundTime = Date()

        case (.inactive, .active):
            // Becoming active from inactive (initial launch or returning)
            if !hasCompletedInitialLoad {
                launchType = determineLaunchType()
            }

        default:
            break
        }
    }

    func markInitialLoadComplete() {
        hasCompletedInitialLoad = true
    }

    func reset() {
        // Used for testing or forcing a specific state
        hasCompletedInitialLoad = false
        backgroundTime = nil
        launchType = .coldStart
    }
}