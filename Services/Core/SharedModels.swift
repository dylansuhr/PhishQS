//
//  SharedModels.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//

import Foundation

// MARK: - Audio/Recording Models

struct TrackDuration: Codable, Identifiable {
    let id: String
    let songName: String
    let durationSeconds: Int
    let showDate: String
    let setNumber: String
    
    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
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

// MARK: - Tour Models

struct Tour: Codable, Identifiable {
    let id: String
    let name: String
    let year: String
    let startDate: String
    let endDate: String
    let showCount: Int
}

struct VenueRun: Codable {
    let venue: String
    let city: String
    let state: String?
    let nightNumber: Int
    let totalNights: Int
    let showDates: [String]
    
    var runDisplayText: String {
        if totalNights > 1 {
            return "N\(nightNumber)/\(totalNights)"
        }
        return ""
    }
}

// MARK: - User Models

struct UserSession: Codable {
    let userId: String
    let username: String
    let token: String
    let expiresAt: Date
}

struct Playlist: Codable, Identifiable {
    let id: String
    let name: String
    let showIds: [String]
    let createdAt: Date
    let updatedAt: Date
}