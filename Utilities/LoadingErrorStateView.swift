//
//  LoadingErrorStateView.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/23/25.
//

import SwiftUI
import SwiftLogger

/// Reusable component for displaying loading and error states consistently across the app
struct LoadingErrorStateView<Content: View>: View {
    let isLoading: Bool
    let errorMessage: String?
    let loadingText: String
    let errorTitle: String
    let retryAction: () -> Void
    let content: () -> Content
    
    init(
        isLoading: Bool,
        errorMessage: String?,
        loadingText: String,
        errorTitle: String,
        retryAction: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.loadingText = loadingText
        self.errorTitle = errorTitle
        self.retryAction = retryAction
        self.content = content
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView(loadingText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Text(errorTitle)
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        retryAction()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content()
            }
        }
    }
}

#Preview {
    LoadingErrorStateView(
        isLoading: false,
        errorMessage: "Failed to load data",
        loadingText: "Loading...",
        errorTitle: "Error occurred",
        retryAction: { SwiftLogger.debug("Retry tapped", category: .ui) }
    ) {
        Text("Content loaded successfully")
    }
}