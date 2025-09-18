//
//  UserModels.swift
//  PhishQS
//
//  Split from SharedModels.swift for better organization
//  Contains user-related data models
//

import Foundation

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