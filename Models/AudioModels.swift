//
//  AudioModels.swift
//  PhishQS
//
//  Split from SharedModels.swift for better organization
//  Contains audio and recording-related data models
//

import Foundation

// MARK: - Audio/Recording Models

struct TrackDuration: Codable, Identifiable {
    let id: String
    let songName: String
    let songId: Int?          // optional songid for reliable cross-API matching
    let durationSeconds: Int
    let showDate: String
    let setNumber: String
    let venue: String?        // venue name for display
    let venueRun: VenueRun?   // venue run info if multi-night run

    // Tour context fields
    let city: String?         // city where song was performed
    let state: String?        // state where song was performed
    let tourPosition: TourShowPosition? // position within tour (e.g., show 4 of 23)

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var venueDisplayText: String? {
        guard let venue = venue else { return nil }

        // If multi-night run, include night indicator
        if let venueRun = venueRun, venueRun.totalNights > 1 {
            return "\(venue), N\(venueRun.nightNumber)"
        }

        // Single night, just venue name
        return venue
    }
}

// MARK: - TrackDuration TourContextProvider Conformance

extension TrackDuration: TourContextProvider {
    // Already has required properties: city, state, tourPosition, showDate, venue
}

struct Recording: Codable, Identifiable {
    let id: String
    let showDate: String
    let venue: String
    let recordingType: RecordingType
    let url: String?
    let isAvailable: Bool
}

enum RecordingType: String, Codable {
    case audience = "aud"
    case soundboard = "sbd"
    case matrix = "matrix"
}