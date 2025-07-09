import SwiftUI

// View for displaying the latest Phish setlist in a compact format
struct LatestSetlistView: View {
    @StateObject private var viewModel = LatestSetlistViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Latest Show")
                    .font(.headline)
                    .foregroundColor(.primary)
                
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
                    
                    Text(show.artist_name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Setlist preview
                if !viewModel.setlistItems.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(viewModel.formattedSetlist.prefix(8).enumerated()), id: \.offset) { index, line in
                            if line.isEmpty {
                                // Skip empty lines in preview
                                continue
                            } else if line.hasPrefix("Set") {
                                Text(line)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            } else {
                                Text(line)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Show "..." if there are more songs
                        if viewModel.setlistItems.count > 8 {
                            Text("...")
                                .font(.caption)
                                .foregroundColor(.secondary)
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