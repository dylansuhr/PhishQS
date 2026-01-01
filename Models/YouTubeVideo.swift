//
//  YouTubeVideo.swift
//  PhishQS
//
//  Model for YouTube video data from the Phish channel
//

import Foundation

struct YouTubeVideo: Codable, Identifiable {
    let videoId: String
    let title: String
    let thumbnailUrl: String
    let publishedAt: String
    let duration: String        // ISO 8601 format: "PT4M32S"
    let viewCount: Int

    var id: String { videoId }

    /// URL to open video in YouTube app
    var youtubeAppURL: URL? {
        URL(string: "youtube://www.youtube.com/watch?v=\(videoId)")
    }

    /// URL to open video in browser
    var youtubeWebURL: URL {
        URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
    }

    /// Formatted duration string (e.g., "4:32")
    var formattedDuration: String {
        parseDuration(duration)
    }

    /// Formatted view count (e.g., "45K", "1.2M")
    var formattedViewCount: String {
        formatViewCount(viewCount)
    }

    /// Formatted publish date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        if let date = formatter.date(from: publishedAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
        return publishedAt
    }

    // MARK: - Private Helpers

    /// Parse ISO 8601 duration to readable format
    private func parseDuration(_ iso8601: String) -> String {
        // Format: PT#H#M#S or PT#M#S
        var duration = iso8601.replacingOccurrences(of: "PT", with: "")

        var hours = 0
        var minutes = 0
        var seconds = 0

        if let hRange = duration.range(of: "H") {
            hours = Int(duration[..<hRange.lowerBound]) ?? 0
            duration = String(duration[hRange.upperBound...])
        }

        if let mRange = duration.range(of: "M") {
            minutes = Int(duration[..<mRange.lowerBound]) ?? 0
            duration = String(duration[mRange.upperBound...])
        }

        if let sRange = duration.range(of: "S") {
            seconds = Int(duration[..<sRange.lowerBound]) ?? 0
        }

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Format view count with K/M suffixes
    private func formatViewCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            let millions = Double(count) / 1_000_000
            return String(format: "%.1fM", millions).replacingOccurrences(of: ".0M", with: "M")
        } else if count >= 1_000 {
            let thousands = Double(count) / 1_000
            return String(format: "%.1fK", thousands).replacingOccurrences(of: ".0K", with: "K")
        }
        return "\(count)"
    }
}

// MARK: - Mock Data

extension YouTubeVideo {
    static let mockVideos: [YouTubeVideo] = [
        YouTubeVideo(
            videoId: "dQw4w9WgXcQ",
            title: "Phish - Tweezer - 12/31/25 MSG NYE",
            thumbnailUrl: "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
            publishedAt: "2025-12-31T23:00:00Z",
            duration: "PT23M45S",
            viewCount: 125000
        ),
        YouTubeVideo(
            videoId: "abc123xyz",
            title: "Phish - You Enjoy Myself - 12/30/25 MSG N3",
            thumbnailUrl: "https://img.youtube.com/vi/abc123xyz/maxresdefault.jpg",
            publishedAt: "2025-12-30T22:00:00Z",
            duration: "PT18M32S",
            viewCount: 89000
        ),
        YouTubeVideo(
            videoId: "def456uvw",
            title: "Phish - Down with Disease > What's the Use? - 12/29/25",
            thumbnailUrl: "https://img.youtube.com/vi/def456uvw/maxresdefault.jpg",
            publishedAt: "2025-12-29T21:00:00Z",
            duration: "PT31M15S",
            viewCount: 156000
        ),
        YouTubeVideo(
            videoId: "ghi789rst",
            title: "Phish - Fluffhead - 12/28/25 MSG N1",
            thumbnailUrl: "https://img.youtube.com/vi/ghi789rst/maxresdefault.jpg",
            publishedAt: "2025-12-28T20:00:00Z",
            duration: "PT16M08S",
            viewCount: 72000
        ),
        YouTubeVideo(
            videoId: "jkl012mno",
            title: "Phish - Simple > Catapult > Simple - Dick's N3",
            thumbnailUrl: "https://img.youtube.com/vi/jkl012mno/maxresdefault.jpg",
            publishedAt: "2025-09-01T19:00:00Z",
            duration: "PT28M55S",
            viewCount: 203000
        )
    ]
}
