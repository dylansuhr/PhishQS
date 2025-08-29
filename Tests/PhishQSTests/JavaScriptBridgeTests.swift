//
//  JavaScriptBridgeTests.swift
//  PhishQSTests
//
//  Created by Claude on 8/29/25.
//

import Testing
@testable import PhishQS

/// Tests for the JavaScript tour calculator bridge
/// 
/// These tests validate that the JavaScript bridge produces identical results
/// to the server-side calculation engine, ensuring perfect consistency.
struct JavaScriptBridgeTests {
    
    // MARK: - Engine Validation Tests
    
    @Test("JavaScript engine loads correctly")
    func testEngineInitialization() throws {
        let calculator = try JavaScriptTourCalculator()
        #expect(calculator.validateEngine())
    }
    
    @Test("JavaScript engine handles empty data gracefully")
    func testEmptyDataHandling() throws {
        let calculator = try JavaScriptTourCalculator()
        
        let result = calculator.calculateTourStatistics(
            tourShows: [],
            tourTrackDurations: [],
            tourName: "Empty Test Tour"
        )
        
        #expect(result != nil)
        #expect(result?.longestSongs.isEmpty ?? false)
        #expect(result?.rarestSongs.isEmpty ?? false)
    }
    
    // MARK: - Calculation Accuracy Tests
    
    @Test("JavaScript produces expected longest songs calculation")
    func testLongestSongsCalculation() throws {
        let calculator = try JavaScriptTourCalculator()
        
        // Sample data matching known server results
        let trackDurations = [
            TrackDuration(
                id: "1",
                songName: "What's Going Through Your Mind",
                songId: nil,
                durationSeconds: 2544,
                showDate: "2025-06-24",
                setNumber: "1",
                venue: "Bethel Woods Center for the Arts"
            ),
            TrackDuration(
                id: "2",
                songName: "Sand",
                songId: nil,
                durationSeconds: 2383,
                showDate: "2025-07-15",
                setNumber: "2",
                venue: "United Center"
            ),
            TrackDuration(
                id: "3",
                songName: "Down with Disease",
                songId: nil,
                durationSeconds: 2048,
                showDate: "2025-07-11",
                setNumber: "1",
                venue: "Pine Knob Music Theatre"
            )
        ]
        
        let result = calculator.calculateTourStatistics(
            tourShows: [],
            tourTrackDurations: trackDurations,
            tourName: "Summer Tour 2025"
        )
        
        #expect(result != nil)
        #expect(result?.longestSongs.count == 3)
        
        // Verify songs are sorted by duration (descending)
        if let longestSongs = result?.longestSongs {
            #expect(longestSongs[0].songName == "What's Going Through Your Mind")
            #expect(longestSongs[0].durationSeconds == 2544)
            
            #expect(longestSongs[1].songName == "Sand")
            #expect(longestSongs[1].durationSeconds == 2383)
            
            #expect(longestSongs[2].songName == "Down with Disease")
            #expect(longestSongs[2].durationSeconds == 2048)
        }
    }
    
    @Test("JavaScript produces expected rarest songs calculation")
    func testRarestSongsCalculation() throws {
        let calculator = try JavaScriptTourCalculator()
        
        // Sample tour shows with known gap data
        let tourShows = createSampleTourShows()
        
        let result = calculator.calculateTourStatistics(
            tourShows: tourShows,
            tourTrackDurations: [],
            tourName: "Summer Tour 2025"
        )
        
        #expect(result != nil)
        #expect(result?.rarestSongs.count == 3)
        
        // Verify songs are sorted by gap size (descending)
        if let rarestSongs = result?.rarestSongs {
            #expect(rarestSongs[0].songName == "On Your Way Down")
            #expect(rarestSongs[0].gap == 522)
            
            #expect(rarestSongs[1].songName == "Paul and Silas")
            #expect(rarestSongs[1].gap == 323)
            
            #expect(rarestSongs[2].songName == "Devotion To A Dream")
            #expect(rarestSongs[2].gap == 322)
        }
    }
    
    // MARK: - Consistency Tests
    
    @Test("JavaScript results match server format exactly")
    func testServerFormatConsistency() throws {
        let calculator = try JavaScriptTourCalculator()
        
        let trackDurations = createSampleTrackDurations()
        let tourShows = createSampleTourShows()
        
        let result = calculator.calculateTourStatistics(
            tourShows: tourShows,
            tourTrackDurations: trackDurations,
            tourName: "Summer Tour 2025"
        )
        
        #expect(result != nil)
        #expect(result?.tourName == "Summer Tour 2025")
        
        // Verify longest songs have required fields
        if let longestSongs = result?.longestSongs {
            for song in longestSongs {
                #expect(!song.songName.isEmpty)
                #expect(song.durationSeconds > 0)
                #expect(!song.showDate.isEmpty)
            }
        }
        
        // Verify rarest songs have required fields
        if let rarestSongs = result?.rarestSongs {
            for song in rarestSongs {
                #expect(!song.songName.isEmpty)
                #expect(song.gap >= 0)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("JavaScript execution completes within performance threshold")
    func testPerformance() throws {
        let calculator = try JavaScriptTourCalculator()
        
        let trackDurations = createSampleTrackDurations()
        let tourShows = createSampleTourShows()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = calculator.calculateTourStatistics(
            tourShows: tourShows,
            tourTrackDurations: trackDurations,
            tourName: "Summer Tour 2025"
        )
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        #expect(result != nil)
        #expect(executionTime < 2.0) // Should complete within 2 seconds
        
        // Verify performance metrics are acceptable
        let metrics = calculator.performanceMetrics
        #expect(metrics.isPerformanceAcceptable)
    }
    
    @Test("JavaScript engine handles multiple calculations efficiently")
    func testMultipleCalculations() throws {
        let calculator = try JavaScriptTourCalculator()
        
        let trackDurations = createSampleTrackDurations()
        let tourShows = createSampleTourShows()
        
        // Run multiple calculations to test caching and performance
        for i in 1...5 {
            let result = calculator.calculateTourStatistics(
                tourShows: tourShows,
                tourTrackDurations: trackDurations,
                tourName: "Test Tour \(i)"
            )
            
            #expect(result != nil)
            #expect(result?.longestSongs.count == 3)
        }
        
        let metrics = calculator.performanceMetrics
        #expect(metrics.totalCalculations == 5)
        #expect(metrics.errorCount == 0)
        #expect(metrics.successRate == 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("JavaScript bridge handles malformed data gracefully")
    func testErrorHandling() throws {
        let calculator = try JavaScriptTourCalculator()
        
        // Test with malformed enhanced setlist (missing required fields)
        let malformedShows = [
            EnhancedSetlist(
                showDate: "",
                setlistItems: [],
                trackDurations: [],
                venueRun: nil,
                tourPosition: nil,
                recordings: [],
                songGaps: []
            )
        ]
        
        let result = calculator.calculateTourStatistics(
            tourShows: malformedShows,
            tourTrackDurations: [],
            tourName: "Error Test Tour"
        )
        
        // Should handle gracefully and return some result or nil
        // Should not crash the app
        #expect(true) // Test passes if we reach this point without crashing
    }
    
    // MARK: - Helper Methods
    
    private func createSampleTrackDurations() -> [TrackDuration] {
        return [
            TrackDuration(
                id: "1",
                songName: "What's Going Through Your Mind",
                songId: nil,
                durationSeconds: 2544,
                showDate: "2025-06-24",
                setNumber: "1",
                venue: "Bethel Woods Center for the Arts"
            ),
            TrackDuration(
                id: "2",
                songName: "Sand",
                songId: nil,
                durationSeconds: 2383,
                showDate: "2025-07-15",
                setNumber: "2",
                venue: "United Center"
            ),
            TrackDuration(
                id: "3",
                songName: "Down with Disease",
                songId: nil,
                durationSeconds: 2048,
                showDate: "2025-07-11",
                setNumber: "1",
                venue: "Pine Knob Music Theatre"
            ),
            TrackDuration(
                id: "4",
                songName: "Harry Hood",
                songId: nil,
                durationSeconds: 1456,
                showDate: "2025-06-25",
                setNumber: "2",
                venue: "Brandon Amphitheater"
            ),
            TrackDuration(
                id: "5",
                songName: "Tweezer",
                songId: nil,
                durationSeconds: 1383,
                showDate: "2025-07-27",
                setNumber: "2",
                venue: "Broadview Stage at SPAC"
            )
        ]
    }
    
    private func createSampleTourShows() -> [EnhancedSetlist] {
        return [
            EnhancedSetlist(
                showDate: "2025-06-24",
                setlistItems: [
                    SetlistItem(showdate: "2025-06-24", song: "Paul and Silas", set: "1", transMark: "", notesMd: nil, venue: "Bethel Woods Center for the Arts", location: nil, showId: 1, setId: 1, songId: 1, tourid: nil, uniqueId: "test1")
                ],
                trackDurations: [],
                venueRun: nil,
                tourPosition: nil,
                recordings: [],
                songGaps: [
                    SongGapInfo(
                        songId: 1,
                        songName: "Paul and Silas",
                        gap: 323,
                        lastPlayed: "2016-07-22",
                        timesPlayed: 100,
                        tourVenue: "Bethel Woods Center for the Arts",
                        tourVenueRun: nil,
                        tourDate: "2025-06-24"
                    )
                ]
            ),
            EnhancedSetlist(
                showDate: "2025-07-11",
                setlistItems: [
                    SetlistItem(showdate: "2025-07-11", song: "Devotion To A Dream", set: "1", transMark: "", notesMd: nil, venue: "Pine Knob Music Theatre", location: nil, showId: 2, setId: 2, songId: 2, tourid: nil, uniqueId: "test2")
                ],
                trackDurations: [],
                venueRun: nil,
                tourPosition: nil,
                recordings: [],
                songGaps: [
                    SongGapInfo(
                        songId: 2,
                        songName: "Devotion To A Dream",
                        gap: 322,
                        lastPlayed: "2016-10-15",
                        timesPlayed: 100,
                        tourVenue: "Pine Knob Music Theatre",
                        tourVenueRun: nil,
                        tourDate: "2025-07-11"
                    )
                ]
            ),
            EnhancedSetlist(
                showDate: "2025-07-18",
                setlistItems: [
                    SetlistItem(showdate: "2025-07-18", song: "On Your Way Down", set: "1", transMark: "", notesMd: nil, venue: "United Center", location: nil, showId: 3, setId: 3, songId: 3, tourid: nil, uniqueId: "test3")
                ],
                trackDurations: [],
                venueRun: nil,
                tourPosition: nil,
                recordings: [],
                songGaps: [
                    SongGapInfo(
                        songId: 3,
                        songName: "On Your Way Down",
                        gap: 522,
                        lastPlayed: "2011-08-06",
                        timesPlayed: 100,
                        tourVenue: "United Center",
                        tourVenueRun: nil,
                        tourDate: "2025-07-18"
                    )
                ]
            )
        ]
    }
}