/**
 * TourStatisticsService.js
 * Server-side tour statistics calculation service
 * Ports Swift TourStatisticsService logic to JavaScript
 */

import { TourSongStatistics, MostPlayedSong, TrackDuration, SongGapInfo } from '../Models/TourStatistics.js';

/**
 * Service for calculating tour-specific song statistics
 * Mirrors Swift TourStatisticsService class
 */
export class TourStatisticsService {
    
    /**
     * Calculate ALL tour statistics in a single pass for optimal performance
     * Ports Swift calculateAllTourStatistics method
     * @param {Array} tourShows - All enhanced setlists for the tour
     * @param {string} tourName - Name of the tour
     * @returns {TourSongStatistics} Complete tour statistics
     */
    static calculateAllTourStatistics(tourShows, tourName) {
        console.log(`🚀 calculateAllTourStatistics: Processing ${tourShows.length} shows in single pass`);
        
        if (!tourShows || tourShows.length === 0) {
            console.log('⚠️  No tour shows provided, returning empty statistics');
            return new TourSongStatistics([], [], [], tourName);
        }
        
        // Data collection containers for all three statistics
        const songPlayCounts = new Map(); // For most played
        const allTrackDurations = []; // For longest
        const tourSongGaps = new Map(); // For rarest
        
        // SINGLE PASS through all tour shows
        tourShows.forEach((show, showIndex) => {
            
            // Collect track durations for longest songs calculation
            if (show.trackDurations) {
                allTrackDurations.push(...show.trackDurations);
            }
            
            // Count song frequencies for most played calculation
            if (show.trackDurations) {
                show.trackDurations.forEach(track => {
                    const songKey = track.songName.toLowerCase();
                    
                    if (songPlayCounts.has(songKey)) {
                        const existing = songPlayCounts.get(songKey);
                        songPlayCounts.set(songKey, {
                            count: existing.count + 1,
                            songId: existing.songId || track.songId,
                            songName: track.songName
                        });
                    } else {
                        songPlayCounts.set(songKey, {
                            count: 1,
                            songId: track.songId,
                            songName: track.songName
                        });
                    }
                });
            }
            
            // Collect gap information for rarest songs calculation
            if (show.songGaps) {
                show.songGaps.forEach(gapInfo => {
                    const songKey = gapInfo.songName.toLowerCase();
                    
                    // Create enhanced gap info with venue run data from show context
                    const enhancedGapInfo = new SongGapInfo(
                        gapInfo.songId,
                        gapInfo.songName,
                        gapInfo.gap,
                        gapInfo.lastPlayed,
                        gapInfo.timesPlayed,
                        {
                            tourVenue: show.setlistItems?.[0]?.venue, // Venue from Phish.net setlist
                            tourVenueRun: show.venueRun, // Venue run from Phish.in
                            tourDate: show.showDate,
                            historicalVenue: gapInfo.historicalVenue,
                            historicalCity: gapInfo.historicalCity,
                            historicalState: gapInfo.historicalState,
                            historicalLastPlayed: gapInfo.historicalLastPlayed
                        }
                    );
                    
                    // For each song, keep the occurrence with the HIGHEST gap (progressive tracking with validation)
                    if (tourSongGaps.has(songKey)) {
                        const existingGap = tourSongGaps.get(songKey);
                        // Only replace if this occurrence has a higher gap
                        if (gapInfo.gap > existingGap.gap) {
                            console.log(`      🔄 Updating ${gapInfo.songName}: ${existingGap.gap} → ${gapInfo.gap}`);
                            tourSongGaps.set(songKey, enhancedGapInfo);
                        } else {
                            console.log(`      ✓ Keeping ${gapInfo.songName}: ${existingGap.gap} > ${gapInfo.gap}`);
                        }
                    } else {
                        // First time seeing this song - add it
                        console.log(`      ➕ Adding ${gapInfo.songName}: Gap ${gapInfo.gap}`);
                        tourSongGaps.set(songKey, enhancedGapInfo);
                    }
                });
            }
        });
        
        // Calculate final results from collected data
        
        // 1. Longest songs - sort all track durations by length
        const longestSongs = allTrackDurations
            .sort((a, b) => b.durationSeconds - a.durationSeconds)
            .slice(0, 3);
        
        // 2. Most played songs - convert counts to MostPlayedSong objects
        const mostPlayedSongs = Array.from(songPlayCounts.values())
            .map(info => new MostPlayedSong(
                info.songId || this.hashCode(info.songName),
                this.capitalizeWords(info.songName),
                info.count
            ))
            .sort((a, b) => b.playCount - a.playCount)
            .slice(0, 3);
        
        // 3. Rarest songs - sort gaps by highest gap value
        const allGapSongs = Array.from(tourSongGaps.values());
        console.log(`🔍 DEBUG: Total unique songs with gaps: ${allGapSongs.length}`);
        
        // Log top 10 gaps for debugging
        const top10Gaps = allGapSongs
            .sort((a, b) => b.gap - a.gap)
            .slice(0, 10);
        console.log(`🔍 DEBUG: Top 10 gaps across entire tour:`);
        top10Gaps.forEach((song, index) => {
            console.log(`   ${index + 1}. ${song.songName}: Gap ${song.gap}`);
        });
        
        const rarestSongs = top10Gaps.slice(0, 3);
        
        // Summary output
        console.log(`✅ Statistics calculated: ${longestSongs.length} longest, ${rarestSongs.length} rarest, ${mostPlayedSongs.length} most played`);
        
        return new TourSongStatistics(
            longestSongs,
            rarestSongs,
            mostPlayedSongs,
            tourName
        );
    }
    
    /**
     * Capitalize words in a string (mirrors Swift behavior)
     * @param {string} str - String to capitalize
     * @returns {string} Capitalized string
     */
    static capitalizeWords(str) {
        return str.replace(/\w\S*/g, txt => 
            txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
        );
    }
    
    /**
     * Generate hash code for string (mirrors Swift hashCode)
     * @param {string} str - String to hash
     * @returns {number} Hash code
     */
    static hashCode(str) {
        let hash = 0;
        if (str.length === 0) return hash;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32bit integer
        }
        return Math.abs(hash);
    }
}