//
//  TourVideosSheet.swift
//  PhishQS
//
//  Sheet displaying YouTube videos from the Phish channel for the current tour
//

import SwiftUI

struct TourVideosSheet: View {
    let videos: [YouTubeVideo]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVideo: YouTubeVideo?
    @State private var showingSafari = false

    var body: some View {
        NavigationStack {
            Group {
                if videos.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No videos available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Check back after the tour starts for videos from the official Phish YouTube channel.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(videos) { video in
                                VideoCard(video: video)
                                    .onTapGesture {
                                        selectedVideo = video
                                        if let appURL = video.youtubeAppURL {
                                            UIApplication.shared.open(appURL) { success in
                                                if !success {
                                                    showingSafari = true
                                                }
                                            }
                                        } else {
                                            showingSafari = true
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("you_tube")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSafari) {
                if let video = selectedVideo {
                    SafariView(url: video.youtubeWebURL)
                        .ignoresSafeArea()
                }
            }
        }
    }
}

// MARK: - Video Card

private struct VideoCard: View {
    let video: YouTubeVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail with duration badge
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: video.thumbnailUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay {
                                Image(systemName: "play.rectangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(8)

                // Duration badge
                Text(video.formattedDuration)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(4)
                    .padding(8)
            }

            // Title
            Text(video.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Metadata
            HStack(spacing: 4) {
                Text(video.formattedDate)
                Text("•")
                Text("\(video.formattedViewCount) views")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    TourVideosSheet(videos: YouTubeVideo.mockVideos)
}
