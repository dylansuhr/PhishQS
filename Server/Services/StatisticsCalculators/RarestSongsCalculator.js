/**
 * RarestSongsCalculator.js
 * 
 * Calculator for rarest songs statistics using live gap data from Phish.net setlist responses.
 * Identifies songs with the highest gaps (shows since last played) to highlight
 * rare performances and unexpected song choices during a tour.
 * 
 * CRITICAL: Uses live gap data from setlist responses, NOT stale database data
 * 
 * Data Source: Phish.net setlist responses with embedded gap data
 * Algorithm: Progressive gap tracking (keep highest gap per song) + sort by gap value
 * Business Logic: Gap = shows since last played (anywhere, not necessarily pre-tour)
 */

import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';
import { SongGapInfo } from '../../Models/TourStatistics.js';

/**
 * Calculator for rarest songs statistics
 * 
 * Processes gap data from enhanced setlists to identify the rarest song
 * performances during a tour based on how long since each song was last played.
 */
export class RarestSongsCalculator extends BaseStatisticsCalculator {
    
    /**
     * Initialize rarest songs calculator
     * @param {Object} config - Configuration options
     */
    constructor(config = {}) {
        super(config);
        this.calculatorType = 'RarestSongs';
    }
    
    /**
     * Initialize data container for gap tracking
     * @returns {Object} Data container with gap tracking map
     */
    initializeDataContainer() {
        return {
            /** 
             * @type {Map<string, SongGapInfo>} 
             * Maps song names (lowercase) to gap info, keeping highest gap per song
             */
            tourSongGaps: new Map()
        };
    }
    
    /**
     * Process a single show and update gap tracking data
     * 
     * CRITICAL GAP TRACKING LOGIC:
     * - Extracts live gap data from setlist response (not stale database)
     * - For songs played multiple times: keeps occurrence with HIGHEST gap
     * - Progressive tracking ensures we capture rarest occurrences
     * 
     * @param {Object} show - Enhanced setlist data for one show
     * @param {Object} dataContainer - Data collection container
     */
    processShow(show, dataContainer) {
        const { tourSongGaps } = dataContainer;
        
        // Extract gap information from this show
        if (show.songGaps && Array.isArray(show.songGaps)) {
            
            this.log(`📊 Processing ${show.songGaps.length} songs with gap data from ${show.showDate}`);
            
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
                        // Extract city and state from Phish.net show data first, fallback to venue run
                        tourCity: show.showVenueInfo?.city || show.venueRun?.city,
                        tourState: show.showVenueInfo?.state || show.venueRun?.state,
                        tourPosition: show.tourPosition, // Tour position information
                        historicalVenue: gapInfo.historicalVenue,
                        historicalCity: gapInfo.historicalCity,
                        historicalState: gapInfo.historicalState,
                        historicalLastPlayed: gapInfo.historicalLastPlayed
                    }
                );
                
                // CRITICAL GAP TRACKING LOGIC:
                // For each song, keep the occurrence with the HIGHEST gap (progressive tracking)
                // 
                // Why highest gap matters:
                // - Same song played multiple times in tour with different gaps
                // - We want the "rarest" occurrence (highest gap) for statistics
                // - Example: Song X played with gap 50 on show 1, gap 300 on show 10
                // - Result: Keep gap 300 as it represents rarest occurrence
                if (tourSongGaps.has(songKey)) {
                    const existingGap = tourSongGaps.get(songKey);
                    
                    // Only replace if this occurrence has a higher gap
                    if (gapInfo.gap > existingGap.gap) {
                        this.log(`🔄 Updating ${gapInfo.songName}: ${existingGap.gap} → ${gapInfo.gap}`);
                        tourSongGaps.set(songKey, enhancedGapInfo);
                    } else {
                        this.log(`✓ Keeping ${gapInfo.songName}: ${existingGap.gap} > ${gapInfo.gap}`);
                    }
                } else {
                    // First time seeing this song in tour - add it
                    this.log(`➕ Adding ${gapInfo.songName}: Gap ${gapInfo.gap}`);
                    tourSongGaps.set(songKey, enhancedGapInfo);
                }
                
                // Debug: Highlight exceptionally rare songs (gap > 200)
                if (gapInfo.gap > 200) {
                    this.log(`🔥 Rare song detected: ${gapInfo.songName} (Gap ${gapInfo.gap}) on ${show.showDate}`);
                }
            });
        } else {
            this.log(`⚠️  No gap data available for ${show.showDate}`);
        }
    }
    
    /**
     * Generate final rarest songs results
     * 
     * Sorts all tracked gaps by value (highest first) and returns
     * the top rarest songs with venue and tour context.
     * 
     * @param {Object} dataContainer - Container with all gap tracking data
     * @param {string} tourName - Tour name for context
     * @returns {Array<SongGapInfo>} Top rarest songs with gap details
     */
    generateResults(dataContainer, tourName) {
        const { tourSongGaps } = dataContainer;
        
        const allGapSongs = Array.from(tourSongGaps.values());
        this.log(`📊 Analyzing ${allGapSongs.length} unique songs with gap data`);
        
        if (allGapSongs.length === 0) {
            this.log(`⚠️  No gap data found - cannot calculate rarest songs`);
            return [];
        }
        
        // Sort gaps by highest gap value (rarest first), then alphabetically for ties
        const rarestSongs = allGapSongs
            .sort((a, b) => {
                // Primary sort: by gap (descending) - highest gaps first
                if (b.gap !== a.gap) {
                    return b.gap - a.gap;
                }
                // Secondary sort: by song name (ascending/alphabetical) when gaps are tied
                return a.songName.localeCompare(b.songName);
            })
            .slice(0, this.resultLimit);
        
        // Debug logging for top results
        this.log(`🏆 Top ${rarestSongs.length} rarest songs in ${tourName}:`);
        rarestSongs.forEach((song, index) => {
            this.log(`   ${index + 1}. ${song.songName}: Gap ${song.gap} at ${song.tourVenue} (${song.tourDate})`);
        });
        
        // Additional debug: Show top 10 for analysis
        if (this.debugMode && allGapSongs.length > this.resultLimit) {
            const top10 = allGapSongs.slice(0, 10);
            this.log(`🔍 DEBUG: Top 10 gaps across entire tour:`);
            top10.forEach((song, index) => {
                this.log(`   ${index + 1}. ${song.songName}: Gap ${song.gap}`);
            });
        }
        
        return rarestSongs;
    }
    
    /**
     * Validate that tour shows contain gap data
     * @param {Array} tourShows - Tour shows array  
     * @param {string} tourName - Tour name
     * @returns {boolean} True if valid and contains gap data
     */
    validateInput(tourShows, tourName) {
        if (!super.validateInput(tourShows, tourName)) {
            return false;
        }
        
        // Check if at least some shows have gap data
        const showsWithGaps = tourShows.filter(show => 
            show.songGaps && show.songGaps.length > 0
        );
        
        if (showsWithGaps.length === 0) {
            this.log(`⚠️  No gap data found in ${tourShows.length} shows`);
            return false;
        }
        
        this.log(`✅ Found gap data in ${showsWithGaps.length}/${tourShows.length} shows`);
        return true;
    }
}