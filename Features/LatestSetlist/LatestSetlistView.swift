import SwiftUI

// View for displaying the latest Phish setlist in a compact format
struct LatestSetlistView: View {
    @StateObject private var viewModel = LatestSetlistViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Loading indicator only (no duplicate header)
            HStack {
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Show info
            if let show = viewModel.latestShow {
                VStack(alignment: .leading, spacing: 4) {
                    Text(show.showdate)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // Show venue info if available from setlist items
                    if let firstItem = viewModel.setlistItems.first {
                        let stateText = firstItem.state != nil ? ", \(firstItem.state!)" : ""
                        Text("\(firstItem.venue), \(firstItem.city)\(stateText)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                // Full setlist display
                if !viewModel.setlistItems.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(viewModel.formattedSetlist.enumerated()), id: \.offset) { index, line in
                            if !line.isEmpty {
                                SetlistLineView(line, fontSize: .caption)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("No recent shows available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            viewModel.fetchLatestSetlist()
        }
    }
}

#Preview {
    LatestSetlistView()
} 
