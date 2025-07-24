//
//  BaseViewModel.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//

import Foundation

/// Base ViewModel functionality for consistent error handling and loading states
@MainActor
class BaseViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var loadingStartTime: Date?
    private let minimumLoadingDuration: TimeInterval = 0.3 // 300ms
    
    /// Handle API errors consistently
    func handleError(_ error: Error) {
        Task {
            await endLoadingWithMinimumDuration()
            errorMessage = error.localizedDescription
        }
    }
    
    /// Clear error state
    func clearError() {
        errorMessage = nil
    }
    
    /// Set loading state with minimum duration support
    func setLoading(_ loading: Bool) {
        if loading {
            isLoading = true
            loadingStartTime = Date()
            clearError()
        } else {
            Task {
                await endLoadingWithMinimumDuration()
            }
        }
    }
    
    /// End loading state after ensuring minimum duration has passed
    private func endLoadingWithMinimumDuration() async {
        guard let startTime = loadingStartTime else {
            isLoading = false
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = minimumLoadingDuration - elapsed
        
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }
        
        isLoading = false
        loadingStartTime = nil
    }
}