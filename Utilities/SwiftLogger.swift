//
//  SwiftLogger.swift
//  PhishQS
//
//  Centralized logging utility for Swift components
//  Provides debug-only logging that's automatically removed in release builds
//

import Foundation
import os.log

/// Centralized logging service for Swift components
/// Uses os.log for proper system integration and performance
struct SwiftLogger {

    /// Logger categories for different components
    enum Category: String {
        case api = "API"
        case cache = "Cache"
        case statistics = "Statistics"
        case calendar = "Calendar"
        case setlist = "Setlist"
        case ui = "UI"
        case general = "General"
    }

    /// Log levels for consistent messaging
    enum Level {
        case debug
        case info
        case warn
        case error
        case fault
    }

    private static let subsystem = "com.phishqs.app"

    /// Log a debug message (only in debug builds)
    static func debug(_ message: String, category: Category = .general) {
        #if DEBUG
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.debug("🐛 \(message)")
        #endif
    }

    /// Log an info message
    static func info(_ message: String, category: Category = .general) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.info("ℹ️ \(message)")
    }

    /// Log a warning message
    static func warn(_ message: String, category: Category = .general) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.warning("⚠️ \(message)")
    }

    /// Log an error message
    static func error(_ message: String, category: Category = .general) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.error("❌ \(message)")
    }

    /// Log a success message
    static func success(_ message: String, category: Category = .general) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.info("✅ \(message)")
    }

    /// Log a fault (critical error)
    static func fault(_ message: String, category: Category = .general) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.fault("💥 \(message)")
    }

    /// Log an API request
    static func apiRequest(_ method: String, url: String) {
        debug("API Request: \(method) \(url)", category: .api)
    }

    /// Log an API response
    static func apiResponse(_ method: String, url: String, status: Int? = nil) {
        if let status = status {
            debug("API Response: \(method) \(url) - Status: \(status)", category: .api)
        } else {
            debug("API Response: \(method) \(url)", category: .api)
        }
    }

    /// Log an API error
    static func apiError(_ method: String, url: String, error: Error) {
        self.error("API Error: \(method) \(url) - \(error.localizedDescription)", category: .api)
    }

    /// Log cache operations
    static func cache(_ operation: String, key: String? = nil) {
        if let key = key {
            debug("Cache \(operation): \(key)", category: .cache)
        } else {
            debug("Cache \(operation)", category: .cache)
        }
    }

    /// Log statistics operations
    static func statistics(_ message: String) {
        debug("Statistics: \(message)", category: .statistics)
    }

    /// Log calendar operations
    static func calendar(_ message: String) {
        debug("Calendar: \(message)", category: .calendar)
    }

    /// Log setlist operations
    static func setlist(_ message: String) {
        debug("Setlist: \(message)", category: .setlist)
    }
}