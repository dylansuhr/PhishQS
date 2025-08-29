//
//  JavaScriptTourCalculator.swift
//  PhishQS
//
//  Created by Claude on 8/29/25.
//

import Foundation
import JavaScriptCore

/// JavaScript bridge for tour statistics calculations
/// 
/// This class provides a bridge between Swift and the shared JavaScript calculation engine,
/// ensuring perfect consistency with server-side calculations while maintaining iOS fallback capability.
///
/// Key Benefits:
/// - Guaranteed calculation consistency with server
/// - Single source of truth for calculation logic
/// - Reduced maintenance burden
/// - Reliable fallback when server unavailable
class JavaScriptTourCalculator {
    
    // MARK: - Properties
    
    private let jsContext: JSContext
    private var tourCalculations: JSValue?
    private let performanceMonitor = JSPerformanceMonitor()
    
    // MARK: - Initialization
    
    /// Initialize the JavaScript calculation engine
    /// Loads the shared tourCalculations.js from app bundle
    init() throws {
        jsContext = JSContext()
        
        // Configure error handling
        setupJavaScriptErrorHandling()
        
        // Load and initialize the shared calculation engine
        try loadTourCalculationsEngine()
        
        print("✅ JavaScriptTourCalculator initialized successfully")
    }
    
    // MARK: - Public API
    
    /// Calculate tour statistics using shared JavaScript engine
    /// 
    /// This method converts Swift data to JavaScript format, executes the shared
    /// calculation engine, and converts results back to Swift objects.
    ///
    /// - Parameters:
    ///   - tourShows: Enhanced setlists from the tour (chronological order)
    ///   - tourTrackDurations: All track durations from the tour
    ///   - tourName: Name of the tour for context
    /// - Returns: TourSongStatistics with calculated results, or nil if calculation fails
    func calculateTourStatistics(
        tourShows: [EnhancedSetlist],
        tourTrackDurations: [TrackDuration],
        tourName: String?
    ) -> TourSongStatistics? {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        print("🔄 Starting JavaScript tour statistics calculation...")
        
        guard let tourCalculations = tourCalculations else {
            print("❌ JavaScript engine not available")
            return nil
        }
        
        do {
            // Convert Swift data to JavaScript format
            let jsShows = try convertTourShowsToJS(tourShows)
            let jsTrackDurations = try convertTrackDurationsToJS(tourTrackDurations)
            
            // Execute longest songs calculation
            guard let calculateLongestSongs = tourCalculations.objectForKeyedSubscript("calculateLongestSongs"),
                  let longestSongsResult = calculateLongestSongs.call(withArguments: [jsTrackDurations]) else {
                print("❌ Failed to execute calculateLongestSongs")
                return nil
            }
            
            // Execute rarest songs calculation
            guard let calculateRarestSongs = tourCalculations.objectForKeyedSubscript("calculateTourProgressiveRarestSongs"),
                  let rarestSongsResult = calculateRarestSongs.call(withArguments: [jsShows, tourName ?? ""]) else {
                print("❌ Failed to execute calculateTourProgressiveRarestSongs")
                return nil
            }
            
            // Convert JavaScript results back to Swift
            let longestSongs = try convertJSToTrackDurations(longestSongsResult)
            let rarestSongs = try convertJSToSongGapInfo(rarestSongsResult)
            
            let calculationTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordCalculation(time: calculationTime, songsProcessed: tourShows.count)
            
            print("✅ JavaScript calculation completed in \(String(format: "%.2f", calculationTime))s")
            print("📊 Results: \(longestSongs.count) longest songs, \(rarestSongs.count) rarest songs")
            
            return TourSongStatistics(
                longestSongs: longestSongs,
                rarestSongs: rarestSongs,
                tourName: tourName
            )
            
        } catch {
            print("❌ JavaScript calculation failed: \(error.localizedDescription)")
            performanceMonitor.recordError(error)
            return nil
        }
    }
    
    /// Validate that the JavaScript engine is working correctly
    /// 
    /// Runs a simple test calculation to ensure the engine is functional.
    /// This can be called during app startup or debugging.
    ///
    /// - Returns: True if engine is working, false otherwise
    func validateEngine() -> Bool {
        guard let tourCalculations = tourCalculations else {
            print("❌ JavaScript engine not loaded")
            return false
        }
        
        // Test with minimal data
        do {
            let testTracks = [
                ["songName": "Test Song 1", "durationSeconds": 600, "showDate": "2025-07-01"],
                ["songName": "Test Song 2", "durationSeconds": 300, "showDate": "2025-07-02"]
            ]
            
            let testShows = [
                [
                    "showDate": "2025-07-01",
                    "venue": "Test Venue", 
                    "songGaps": [
                        ["songName": "Test Song", "gap": 100, "tourDate": "2025-07-01"]
                    ]
                ]
            ]
            
            // Test longest songs calculation
            guard let calculateLongestSongs = tourCalculations.objectForKeyedSubscript("calculateLongestSongs"),
                  let longestResult = calculateLongestSongs.call(withArguments: [testTracks]),
                  longestResult.toArray().count > 0 else {
                print("❌ Longest songs validation failed")
                return false
            }
            
            // Test rarest songs calculation
            guard let calculateRarestSongs = tourCalculations.objectForKeyedSubscript("calculateTourProgressiveRarestSongs"),
                  let rarestResult = calculateRarestSongs.call(withArguments: [testShows, "Test Tour"]),
                  rarestResult.toArray().count > 0 else {
                print("❌ Rarest songs validation failed") 
                return false
            }
            
            print("✅ JavaScript engine validation passed")
            return true
            
        } catch {
            print("❌ Engine validation error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Get performance metrics for monitoring
    var performanceMetrics: JSPerformanceMetrics {
        return performanceMonitor.getMetrics()
    }
    
    // MARK: - Private Methods
    
    /// Load the shared JavaScript calculation engine from app bundle
    private func loadTourCalculationsEngine() throws {
        guard let jsPath = Bundle.main.path(forResource: "tourCalculations", ofType: "js"),
              let jsSource = try? String(contentsOfFile: jsPath, encoding: .utf8) else {
            throw JSBridgeError.engineNotFound
        }
        
        // Execute the JavaScript source to load functions
        jsContext.evaluateScript(jsSource)
        
        // Get the tourCalculations object from global scope
        tourCalculations = jsContext.objectForKeyedSubscript("tourCalculations")
        
        guard let tourCalculations = tourCalculations, !tourCalculations.isUndefined else {
            throw JSBridgeError.engineInitializationFailed
        }
        
        print("✅ Loaded shared JavaScript calculation engine (\(jsSource.count) characters)")
    }
    
    /// Configure JavaScript error handling and logging
    private func setupJavaScriptErrorHandling() {
        jsContext.exceptionHandler = { context, exception in
            if let error = exception {
                print("💥 JavaScript execution error: \(error)")
                print("   Context: \(context?.description ?? "unknown")")
            }
        }
        
        // Add console.log support for debugging
        let consoleLog: @convention(block) (String) -> Void = { message in
            print("🔧 JS: \(message)")
        }
        jsContext.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
        
        // Override console.log in JavaScript
        jsContext.evaluateScript("var console = { log: consoleLog };")
    }
    
    // MARK: - Data Conversion Methods
    
    /// Convert Swift EnhancedSetlist array to JavaScript format
    private func convertTourShowsToJS(_ tourShows: [EnhancedSetlist]) throws -> JSValue {
        var jsShows: [[String: Any]] = []
        
        for show in tourShows {
            // Extract venue from setlist items or venue run
            let venue = show.setlistItems.first?.venue ?? 
                       show.venueRun?.venue ?? 
                       "Unknown Venue"
            
            var jsShow: [String: Any] = [
                "showDate": show.showDate,
                "venue": venue
            ]
            
            // Convert song gaps
            var jsSongGaps: [[String: Any]] = []
            for gapInfo in show.songGaps {
                let jsGap: [String: Any] = [
                    "songName": gapInfo.songName,
                    "gap": gapInfo.gap,
                    "lastPlayed": gapInfo.lastPlayed ?? "",
                    "tourDate": gapInfo.tourDate ?? show.showDate,
                    "tourVenue": gapInfo.tourVenue ?? venue,
                    "timesPlayed": gapInfo.timesPlayed,
                    // Include historical data if available
                    "historicalVenue": gapInfo.historicalVenue ?? "",
                    "historicalCity": gapInfo.historicalCity ?? "",
                    "historicalState": gapInfo.historicalState ?? "",
                    "historicalLastPlayed": gapInfo.historicalLastPlayed ?? gapInfo.lastPlayed ?? ""
                ]
                jsSongGaps.append(jsGap)
            }
            jsShow["songGaps"] = jsSongGaps
            
            jsShows.append(jsShow)
        }
        
        guard let jsValue = JSValue(object: jsShows, in: jsContext) else {
            throw JSBridgeError.dataConversionFailed("Failed to convert tour shows to JavaScript")
        }
        
        return jsValue
    }
    
    /// Convert Swift TrackDuration array to JavaScript format
    private func convertTrackDurationsToJS(_ trackDurations: [TrackDuration]) throws -> JSValue {
        var jsTracks: [[String: Any]] = []
        
        for track in trackDurations {
            let jsTrack: [String: Any] = [
                "songName": track.songName,
                "durationSeconds": track.durationSeconds,
                "showDate": track.showDate,
                "venue": track.venue ?? "Unknown Venue",
                "setNumber": track.setNumber
            ]
            jsTracks.append(jsTrack)
        }
        
        guard let jsValue = JSValue(object: jsTracks, in: jsContext) else {
            throw JSBridgeError.dataConversionFailed("Failed to convert track durations to JavaScript")
        }
        
        return jsValue
    }
    
    /// Convert JavaScript result to Swift TrackDuration array
    private func convertJSToTrackDurations(_ jsValue: JSValue) throws -> [TrackDuration] {
        guard let jsArray = jsValue.toArray() as? [[String: Any]] else {
            throw JSBridgeError.dataConversionFailed("Failed to convert JavaScript result to track durations")
        }
        
        var trackDurations: [TrackDuration] = []
        
        for jsTrack in jsArray {
            guard let songName = jsTrack["songName"] as? String,
                  let durationSeconds = jsTrack["durationSeconds"] as? Int,
                  let showDate = jsTrack["showDate"] as? String else {
                continue
            }
            
            let track = TrackDuration(
                id: "\(showDate)-\(songName)",
                songName: songName,
                songId: nil,
                durationSeconds: durationSeconds,
                showDate: showDate,
                setNumber: jsTrack["setNumber"] as? String ?? "Unknown",
                venue: jsTrack["venue"] as? String,
                venueRun: nil // Could be enhanced later
            )
            
            trackDurations.append(track)
        }
        
        return trackDurations
    }
    
    /// Convert JavaScript result to Swift SongGapInfo array
    private func convertJSToSongGapInfo(_ jsValue: JSValue) throws -> [SongGapInfo] {
        guard let jsArray = jsValue.toArray() as? [[String: Any]] else {
            throw JSBridgeError.dataConversionFailed("Failed to convert JavaScript result to song gap info")
        }
        
        var songGaps: [SongGapInfo] = []
        
        for jsGap in jsArray {
            guard let songName = jsGap["songName"] as? String,
                  let gap = jsGap["gap"] as? Int else {
                continue
            }
            
            let gapInfo = SongGapInfo(
                songId: 0, // JavaScript engine doesn't provide songId
                songName: songName,
                gap: gap,
                lastPlayed: jsGap["lastPlayed"] as? String ?? "",
                timesPlayed: jsGap["timesPlayed"] as? Int ?? 100,
                tourVenue: jsGap["tourVenue"] as? String,
                tourVenueRun: nil,
                tourDate: jsGap["tourDate"] as? String,
                historicalVenue: jsGap["historicalVenue"] as? String,
                historicalCity: jsGap["historicalCity"] as? String,
                historicalState: jsGap["historicalState"] as? String,
                historicalLastPlayed: jsGap["historicalLastPlayed"] as? String
            )
            
            songGaps.append(gapInfo)
        }
        
        return songGaps
    }
}

// MARK: - Error Types

/// Errors that can occur during JavaScript bridge operations
enum JSBridgeError: LocalizedError {
    case engineNotFound
    case engineInitializationFailed
    case dataConversionFailed(String)
    case calculationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .engineNotFound:
            return "JavaScript calculation engine not found in app bundle"
        case .engineInitializationFailed:
            return "Failed to initialize JavaScript calculation engine"
        case .dataConversionFailed(let details):
            return "Data conversion failed: \(details)"
        case .calculationFailed(let details):
            return "JavaScript calculation failed: \(details)"
        }
    }
}

// MARK: - Performance Monitoring

/// Performance monitoring for JavaScript calculations
class JSPerformanceMonitor {
    private var calculationTimes: [Double] = []
    private var errorCount = 0
    private var totalSongsProcessed = 0
    
    func recordCalculation(time: Double, songsProcessed: Int) {
        calculationTimes.append(time)
        totalSongsProcessed += songsProcessed
        
        // Keep only recent measurements (last 10)
        if calculationTimes.count > 10 {
            calculationTimes.removeFirst()
        }
    }
    
    func recordError(_ error: Error) {
        errorCount += 1
        print("📊 JS Performance: Error recorded - \(error.localizedDescription)")
    }
    
    func getMetrics() -> JSPerformanceMetrics {
        let avgTime = calculationTimes.isEmpty ? 0 : calculationTimes.reduce(0, +) / Double(calculationTimes.count)
        let maxTime = calculationTimes.max() ?? 0
        
        return JSPerformanceMetrics(
            averageCalculationTime: avgTime,
            maxCalculationTime: maxTime,
            totalCalculations: calculationTimes.count,
            errorCount: errorCount,
            totalSongsProcessed: totalSongsProcessed
        )
    }
}

/// Performance metrics for JavaScript calculations
struct JSPerformanceMetrics {
    let averageCalculationTime: Double
    let maxCalculationTime: Double
    let totalCalculations: Int
    let errorCount: Int
    let totalSongsProcessed: Int
    
    var successRate: Double {
        guard totalCalculations > 0 else { return 0 }
        return Double(totalCalculations - errorCount) / Double(totalCalculations)
    }
    
    var isPerformanceAcceptable: Bool {
        return averageCalculationTime < 2.0 && successRate > 0.95
    }
}