//
//  CacheManager.swift
//  PhishQS
//
//  Created by Claude on 8/27/25.
//

import Foundation

/// Thread-safe cache manager for API data with TTL (Time To Live) support
class CacheManager {
    static let shared = CacheManager()
    
    private struct CacheItem<T> {
        let value: T
        let expirationDate: Date
        
        var isExpired: Bool {
            return Date() > expirationDate
        }
    }
    
    private var cache: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.phishqs.cache", attributes: .concurrent)
    
    private init() {}
    
    /// Store value in cache with TTL
    func set<T>(_ value: T, forKey key: String, ttl: TimeInterval) {
        let expirationDate = Date().addingTimeInterval(ttl)
        let item = CacheItem(value: value, expirationDate: expirationDate)
        
        queue.async(flags: .barrier) {
            self.cache[key] = item
        }
    }
    
    /// Retrieve value from cache if not expired
    func get<T>(_ type: T.Type, forKey key: String) -> T? {
        return queue.sync {
            guard let item = cache[key] as? CacheItem<T> else {
                return nil
            }
            
            if item.isExpired {
                cache.removeValue(forKey: key)
                return nil
            }
            
            return item.value
        }
    }
    
    /// Clear all expired items
    func clearExpired() {
        queue.async(flags: .barrier) {
            self.cache = self.cache.compactMapValues { item in
                if let cacheItem = item as? CacheItem<Any> {
                    return cacheItem.isExpired ? nil : item
                }
                return item
            }
        }
    }
    
    /// Clear all cache
    func clearAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    /// Remove specific key
    func remove(forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }
}

// MARK: - Cache Keys
extension CacheManager {
    enum CacheKeys {
        static let songGaps = "song_gaps_all"
        static let tourTrackDurations = "tour_track_durations_"
        static let enhancedSetlist = "enhanced_setlist_"
        static let tourShows = "tour_shows_"
        static let venueRuns = "venue_runs_"
        static let tourStatistics = "tour_statistics_"
        
        static func tourTrackDurations(_ tourName: String) -> String {
            return tourTrackDurations + tourName
        }
        
        static func tourShows(_ tourName: String) -> String {
            return tourShows + tourName
        }
        
        static func tourStatistics(_ tourName: String, showDate: String) -> String {
            return tourStatistics + tourName + "_" + showDate
        }
        
        static func enhancedSetlist(_ date: String) -> String {
            return enhancedSetlist + date
        }
        
        static func venueRuns(_ date: String) -> String {
            return venueRuns + date
        }
    }
}

// MARK: - Cache TTL Constants
extension CacheManager {
    enum TTL {
        static let songGaps: TimeInterval = 6 * 60 * 60 // 6 hours (rarely changes)
        static let tourTrackDurations: TimeInterval = 2 * 60 * 60 // 2 hours (tour-level data)
        static let enhancedSetlist: TimeInterval = 30 * 60 // 30 minutes (show data)
        static let tourShows: TimeInterval = 1 * 60 * 60 // 1 hour (tour show lists)
        static let venueRuns: TimeInterval = 4 * 60 * 60 // 4 hours (venue run data)
    }
}