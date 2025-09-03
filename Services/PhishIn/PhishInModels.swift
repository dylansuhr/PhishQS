//
//  PhishInModels.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/25/25.
//

import Foundation

// MARK: - Phish.in API Response Models

// MARK: - v2 API Response Wrappers

struct PhishInShowsResponse: Codable {
    let shows: [PhishInShow]
    let total_entries: Int
    let total_pages: Int
    let current_page: Int
}

struct PhishInToursResponse: Codable {
    let tours: [PhishInTour]
    let total_entries: Int
    let total_pages: Int
    let current_page: Int
}

struct PhishInVenuesResponse: Codable {
    let venues: [PhishInVenue]
    let total_entries: Int
    let total_pages: Int
    let current_page: Int
}

struct PhishInSongsResponse: Codable {
    let songs: [PhishInSong]
    let total_entries: Int
    let total_pages: Int
    let current_page: Int
}

struct PhishInErasResponse: Codable {
    let eras: [PhishInEra]
    let total_entries: Int
    let total_pages: Int
    let current_page: Int
}

// MARK: - Show Models

struct PhishInShow: Codable, Identifiable {
    let id: Int
    let date: String
    let duration: Int?
    let incomplete: Bool?
    let missing: Bool?
    let sbd: Bool?
    let remastered: Bool?
    let venue_id: Int?
    let likes_count: Int?
    let taper_notes: String?
    let updated_at: String?
    let venue: PhishInVenue?
    let tour_name: String?
    let venue_name: String?
    let tracks: [PhishInTrack]?
    
    /// Convert to our standard Show model for compatibility
    func toShow() -> Show {
        return Show(
            showyear: String(Calendar.current.component(.year, from: dateFromString(date) ?? Date())),
            showdate: date,
            artist_name: "Phish"
        )
    }
    
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

// MARK: - Track Models

struct PhishInTrack: Codable, Identifiable {
    let id: Int
    let title: String
    let position: Int
    let duration: Int?
    let set_name: String?
    let likes_count: Int?
    let slug: String?
    let mp3: String?
    let waveform_image: String?
    let song_id: Int?
    let song: PhishInSong?
    let show_id: Int?
    let jam_starts: [JamStart]?
    
    /// Convert duration to TrackDuration model
    func toTrackDuration(showDate: String, venue: String? = nil, venueRun: VenueRun? = nil) -> TrackDuration? {
        guard let duration = duration else { return nil }
        
        return TrackDuration(
            id: String(id),
            songName: title,
            songId: nil, // Phish.in doesn't provide songid mapping yet
            durationSeconds: duration / 1000, // Convert milliseconds to seconds
            showDate: showDate,
            setNumber: set_name ?? "1",
            venue: venue,
            venueRun: venueRun,
            city: venueRun?.city, // Extract city from venue run if available
            state: venueRun?.state, // Extract state from venue run if available
            tourPosition: nil // Tour position will be added by statistics service
        )
    }
}

struct JamStart: Codable {
    let starts_at_second: Int
    let ends_at_second: Int?
}

// MARK: - Song Models

struct PhishInSong: Codable, Identifiable {
    let id: Int
    let title: String
    let alias: String?
    let artist_id: Int?
    let tracks_count: Int?
    let slug: String?
    let updated_at: String?
}

// MARK: - Venue Models

struct PhishInVenue: Codable, Identifiable {
    let venue_id: Int?
    let name: String
    let other_names: [String]?
    let latitude: Double?
    let longitude: Double?
    let shows_count: Int?
    let location: String?
    let updated_at: String?
    let slug: String?
    
    // Identifiable protocol requirement - use slug as fallback identifier
    var id: String {
        return slug ?? name.lowercased().replacingOccurrences(of: " ", with: "-")
    }
    
    // Custom CodingKeys to handle missing 'id' field
    private enum CodingKeys: String, CodingKey {
        case venue_id = "id"
        case name, other_names, latitude, longitude, shows_count, location, updated_at, slug
    }
    
    /// Convert to our standard Venue model
    func toVenue() -> Venue {
        let locationParts = location?.components(separatedBy: ", ") ?? []
        let city = locationParts.first ?? ""
        let state = locationParts.count > 1 ? locationParts[1] : nil
        let country = locationParts.count > 2 ? locationParts[2] : "USA"
        
        return Venue(
            id: venue_id.map(String.init) ?? slug ?? name,
            name: name,
            city: city,
            state: state,
            country: country,
            latitude: latitude,
            longitude: longitude
        )
    }
}

// MARK: - Tour Models

struct PhishInTour: Codable, Identifiable {
    let id: Int
    let name: String
    let shows_count: Int?
    let starts_on: String?
    let ends_on: String?
    let slug: String?
    let updated_at: String?
    
    /// Convert to our standard Tour model
    func toTour() -> Tour {
        let year = starts_on?.prefix(4) ?? "Unknown"
        
        return Tour(
            id: String(id),
            name: name,
            year: String(year),
            startDate: starts_on ?? "",
            endDate: ends_on ?? "",
            showCount: shows_count ?? 0
        )
    }
}

// MARK: - Era Models

struct PhishInEra: Codable, Identifiable {
    let id: Int
    let name: String
    let order: Int?
    let updated_at: String?
}

// MARK: - Playlist Models

struct PhishInPlaylist: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String?
    let duration: Int?
    let tracks_count: Int?
    let likes_count: Int?
    let published: Bool?
    let user_id: Int?
    let updated_at: String?
    let bookmarked: Bool?
    let liked: Bool?
}

// MARK: - User Models

struct PhishInUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let created_at: String?
    let updated_at: String?
}

struct PhishInAuthResponse: Codable {
    let auth_token: String
    let user: PhishInUser
}