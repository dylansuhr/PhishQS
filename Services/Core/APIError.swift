//
//  APIError.swift
//  PhishQS
//
//  Created by Dylan Suhr on 7/24/25.
//

import Foundation

// MARK: - API Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(Int)
    case noData
    case decodingError(Error)
    case invalidResponse
    case apiKeyMissing
    case rateLimitExceeded
    case unauthorized
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiKeyMissing:
            return "API key not configured"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .unauthorized:
            return "Unauthorized access"
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        }
    }
}