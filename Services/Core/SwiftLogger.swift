//
//  SwiftLogger.swift
//  PhishQS
//
//  Created by Claude on 9/18/25.
//

import Foundation
import os.log

/// Centralized logging service for iOS with structured, environment-aware logging
/// Mirrors the server-side LoggingService.js for consistent logging patterns
class SwiftLogger {

    // MARK: - Log Levels

    enum LogLevel: Int, CaseIterable {
        case trace = 0
        case debug = 1
        case info = 2
        case warn = 3
        case error = 4

        var emoji: String {
            switch self {
            case .trace: return "🔍"
            case .debug: return "🐛"
            case .info: return "ℹ️"
            case .warn: return "⚠️"
            case .error: return "❌"
            }
        }

        var osLogType: OSLogType {
            switch self {
            case .trace: return .debug
            case .debug: return .debug
            case .info: return .info
            case .warn: return .default
            case .error: return .error
            }
        }
    }

    // MARK: - Configuration

    /// Current log level threshold - only logs at this level or higher will be output
    private static var currentLogLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }()

    /// OSLog categories for different subsystems
    private static let generalLog = OSLog(subsystem: "com.phishqs.app", category: "General")
    private static let apiLog = OSLog(subsystem: "com.phishqs.app", category: "API")
    private static let cacheLog = OSLog(subsystem: "com.phishqs.app", category: "Cache")
    private static let uiLog = OSLog(subsystem: "com.phishqs.app", category: "UI")
    private static let performanceLog = OSLog(subsystem: "com.phishqs.app", category: "Performance")

    // MARK: - Core Logging Methods

    /// Log a trace message (most verbose)
    static func trace(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .trace, message: message, category: category, file: file, function: function, line: line)
    }

    /// Log a debug message
    static func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }

    /// Log an info message
    static func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }

    /// Log a warning message
    static func warn(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warn, message: message, category: category, file: file, function: function, line: line)
    }

    /// Log an error message
    static func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, category: category, file: file, function: function, line: line)
    }

    // MARK: - Specialized Logging Methods

    /// Log API-related messages
    static func api(_ message: String, level: LogLevel = .info) {
        log(level: level, message: message, category: .api)
    }

    /// Log cache-related messages
    static func cache(_ message: String, level: LogLevel = .info) {
        log(level: level, message: message, category: .cache)
    }

    /// Log UI-related messages
    static func ui(_ message: String, level: LogLevel = .info) {
        log(level: level, message: message, category: .ui)
    }

    /// Log performance-related messages
    static func performance(_ message: String, level: LogLevel = .info) {
        log(level: level, message: message, category: .performance)
    }

    /// Log start of an operation
    static func start(_ message: String, category: LogCategory = .general) {
        log(level: .info, message: "🚀 \(message)", category: category)
    }

    /// Log successful completion of an operation
    static func success(_ message: String, category: LogCategory = .general) {
        log(level: .info, message: "✅ \(message)", category: category)
    }

    /// Log failure of an operation
    static func failure(_ message: String, category: LogCategory = .general) {
        log(level: .error, message: "❌ \(message)", category: category)
    }

    // MARK: - Core Implementation

    private static func log(level: LogLevel, message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) {
        // Check if we should log at this level
        guard level.rawValue >= currentLogLevel.rawValue else { return }

        // Format the message
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let formattedMessage = formatMessage(level: level, message: message, fileName: fileName, function: function, line: line)

        // Choose appropriate OSLog
        let osLog = category.osLog

        // Log using os_log for better performance and integration with Xcode console
        os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)

        // Also print to console for immediate debugging (only in debug builds)
        #if DEBUG
        print(formattedMessage)
        #endif
    }

    private static func formatMessage(level: LogLevel, message: String, fileName: String, function: String, line: Int) -> String {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())

        #if DEBUG
        // Detailed format for debugging
        return "\(level.emoji) [\(timestamp)] [\(fileName):\(line)] \(function) - \(message)"
        #else
        // Simplified format for production
        return "\(level.emoji) [\(timestamp)] \(message)"
        #endif
    }

    // MARK: - Configuration

    /// Set the minimum log level
    static func setLogLevel(_ level: LogLevel) {
        currentLogLevel = level
        SwiftLogger.info("Log level set to \(level)")
    }

    /// Get current log level
    static func getLogLevel() -> LogLevel {
        return currentLogLevel
    }
}

// MARK: - Log Categories

enum LogCategory {
    case general
    case api
    case cache
    case ui
    case performance

    var osLog: OSLog {
        switch self {
        case .general: return SwiftLogger.generalLog
        case .api: return SwiftLogger.apiLog
        case .cache: return SwiftLogger.cacheLog
        case .ui: return SwiftLogger.uiLog
        case .performance: return SwiftLogger.performanceLog
        }
    }
}

// MARK: - Utilities

private extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}