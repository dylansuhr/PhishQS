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
                        .foregroundColor(.secondary)
                    
                    // Show venue info if available from setlist items
                    if let firstItem = viewModel.setlistItems.first {
                        Text("\(firstItem.venue), \(firstItem.city)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Full setlist display
                if !viewModel.setlistItems.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(viewModel.formattedSetlist.enumerated()), id: \.offset) { index, line in
                            if !line.isEmpty {
                                Text(line)
                                    .font(.caption)
                                    .fontWeight(line.contains("Set ") || line.contains("Encore:") ? .semibold : .regular)
                                    .foregroundColor(line.contains("Set ") || line.contains("Encore:") ? .blue : .primary)
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
