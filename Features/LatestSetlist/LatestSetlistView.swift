import SwiftUI

// View for displaying the latest Phish setlist with simple navigation
struct LatestSetlistView: View {
    @StateObject private var viewModel = LatestSetlistViewModel()
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Navigation buttons at top
            HStack {
                Button(action: {
                    viewModel.navigateToPreviousShow()
                }) {
                    Text("Previous")
                        .foregroundColor(viewModel.canNavigatePrevious ? .blue : .gray)
                }
                .disabled(!viewModel.canNavigatePrevious)
                
                Spacer()
                
                Button(action: {
                    viewModel.navigateToNextShow()
                }) {
                    Text("Next")
                        .foregroundColor(viewModel.canNavigateNext ? .blue : .gray)
                }
                .disabled(!viewModel.canNavigateNext)
            }
            .padding(.horizontal)
            
            // Show info
            if let show = viewModel.latestShow {
                VStack(alignment: .leading, spacing: 4) {
                    Text(show.showdate)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // Show venue info if available from setlist items
                    if let firstItem = viewModel.setlistItems.first {
                        HStack {
                            let stateText = firstItem.state != nil ? ", \(firstItem.state!)" : ""
                            Text("\(firstItem.venue) - \(firstItem.city)\(stateText)")
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            // Show venue run info if available
                            if let venueRun = viewModel.venueRunInfo {
                                Spacer()
                                Text(venueRun.runDisplayText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(3)
                            }
                        }
                        
                        // Show tour position info if available
                        if let tourPosition = viewModel.tourPositionInfo {
                            Text(tourPosition.shortDisplayText)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 1)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Full setlist display
                if !viewModel.setlistItems.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(StringFormatters.formatSetlist(viewModel.setlistItems).enumerated()), id: \.offset) { index, line in
                            if !line.isEmpty {
                                SetlistLineView(line, fontSize: .caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            } else {
                Text("No recent shows available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.fetchLatestSetlist()
        }
    }
}

#Preview {
    LatestSetlistView()
} 
