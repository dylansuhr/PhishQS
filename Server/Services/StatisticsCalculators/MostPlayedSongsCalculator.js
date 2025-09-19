/**
 * MostPlayedSongsCalculator.js
 * 
 * Calculator for most played songs statistics using song frequency analysis
 * across all shows in a tour. Identifies which songs appear most often
 * to highlight tour favorites and recurring themes.
 * 
 * Data Source: Song names from setlist items (Phish.net)
 * Algorithm: Count frequency of each unique song, sort by play count
 * Business Logic: More plays = tour staples, fan favorites, or thematic elements
 */

import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';
import { MostPlayedSong } from '../../Models/TourStatistics.js';

/**
 * Calculator for most played songs statistics
 * 
 * Analyzes song frequency across all tour shows to identify
 * which songs were played most often during the tour.
 */
export class MostPlayedSongsCalculator extends BaseStatisticsCalculator {
    
    /**
     * Initialize most played songs calculator
     * @param {Object} config - Configuration options
     */
    constructor(config = {}) {
        super(config);
        this.calculatorType = 'MostPlayedSongs';
    }
    
    /**
     * Initialize data container for song frequency tracking
     * @returns {Object} Data container with song count map
     */
    initializeDataContainer() {
        return {
            /** 
             * @type {Map<string, Object>} 
             * Maps song names (lowercase) to play count data with tour context
             * Value: { count: number, songId: string, songName: string, mostRecentShow: Object }
             */
            songPlayCounts: new Map(),
            
            /**
             * @type {Array<Object>}
             * All tour shows for finding most recent performances
             */
            allTourShows: []
        };
    }
    
    /**
     * Process a single show and update song frequency counts
     *
     * Counts each unique song played in the show. Uses setlist items
     * from Phish.net as the primary source since they contain complete
     * song data with proper song identification.
     *
     * @param {Object} show - Enhanced setlist data for one show
     * @param {Object} dataContainer - Data collection container
     */
    processShow(show, dataContainer) {
        const { songPlayCounts, allTourShows } = dataContainer;

        // Add this show to the collection for finding most recent performances
        allTourShows.push(show);

        // Count song frequencies using setlist items from Phish.net
        if (show.setlistItems && Array.isArray(show.setlistItems)) {

            this.log(`🎵 Processing ${show.setlistItems.length} songs from ${show.showDate}`);

            show.setlistItems.forEach(item => {
                const songKey = item.song.toLowerCase();

                if (songPlayCounts.has(songKey)) {
                    // Increment existing song count and update most recent show if this is newer
                    const existing = songPlayCounts.get(songKey);
                    const isMoreRecent = new Date(show.showDate) >= new Date(existing.mostRecentShow?.showDate || '1970-01-01');

                    songPlayCounts.set(songKey, {
                        count: existing.count + 1,
                        songId: existing.songId || item.songid,
                        songName: item.song, // Keep original case formatting
                        mostRecentShow: isMoreRecent ? show : existing.mostRecentShow
                    });

                    this.log(`📈 ${item.song}: ${existing.count} → ${existing.count + 1} plays`);
                } else {
                    // First occurrence of this song
                    songPlayCounts.set(songKey, {
                        count: 1,
                        songId: item.songid,
                        songName: item.song,
                        mostRecentShow: show
                    });

                    this.log(`➕ ${item.song}: First play tracked`);
                }
            });
        } else {
            this.log(`⚠️  No setlist data available for ${show.showDate}`);
        }
    }
    
    /**
     * Generate final most played songs results
     * 
     * Converts song counts to MostPlayedSong objects, sorts by play count
     * (highest first), and returns the top performers.
     * 
     * @param {Object} dataContainer - Container with all song count data
     * @param {string} tourName - Tour name for context
     * @returns {Array<MostPlayedSong>} Top most played songs with play counts
     */
    generateResults(dataContainer, tourName, context = {}) {
        const { songPlayCounts } = dataContainer;
        
        const allSongCounts = Array.from(songPlayCounts.values());
        this.log(`📊 Analyzing play counts for ${allSongCounts.length} unique songs`);
        
        if (allSongCounts.length === 0) {
            this.log(`⚠️  No song play data found - cannot calculate most played songs`);
            return [];
        }
        
        // Convert counts to MostPlayedSong objects (simple: only name and count)
        const mostPlayedSongs = allSongCounts
            .map(info => {
                return new MostPlayedSong(
                    info.songId || BaseStatisticsCalculator.hashCode(info.songName),
                    BaseStatisticsCalculator.capitalizeWords(info.songName),
                    info.count
                    // No venue or tour context - keep it simple per user request
                );
            })
            .sort((a, b) => {
                // Primary sort: by play count (descending)
                if (b.playCount !== a.playCount) {
                    return b.playCount - a.playCount;
                }
                // Secondary sort: by song name (ascending/alphabetical) when play counts are tied
                return a.songName.localeCompare(b.songName);
            })
            .slice(0, this.resultLimit);
        
        // Debug logging for top results (simplified - only name and count)
        this.log(`🏆 Top ${mostPlayedSongs.length} most played songs in ${tourName}:`);
        mostPlayedSongs.forEach((song, index) => {
            const plural = song.playCount === 1 ? 'time' : 'times';
            this.log(`   ${index + 1}. ${song.songName}: ${song.playCount} ${plural}`);
        });
        
        // Additional debug: Show play count distribution
        if (this.debugMode) {
            const totalPlays = allSongCounts.reduce((sum, info) => sum + info.count, 0);
            const averagePlays = (totalPlays / allSongCounts.length).toFixed(1);
            this.log(`📈 Play count distribution: ${totalPlays} total plays, ${averagePlays} average per song`);
            
            // Show songs played only once (tour debuts/rarities)
            const singlePlays = allSongCounts.filter(info => info.count === 1);
            this.log(`🎭 ${singlePlays.length} songs played only once during tour`);
        }
        
        return mostPlayedSongs;
    }
    
    /**
     * Validate that tour shows contain trackable song data
     * @param {Array} tourShows - Tour shows array
     * @param {string} tourName - Tour name
     * @returns {boolean} True if valid and contains song data
     */
    validateInput(tourShows, tourName) {
        if (!super.validateInput(tourShows, tourName)) {
            return false;
        }

        // Check if at least some shows have setlist data for song counting
        const showsWithSongs = tourShows.filter(show =>
            show.setlistItems && show.setlistItems.length > 0
        );

        if (showsWithSongs.length === 0) {
            this.log(`⚠️  No setlist data found in ${tourShows.length} shows`);
            return false;
        }

        this.log(`✅ Found setlist data in ${showsWithSongs.length}/${tourShows.length} shows`);
        return true;
    }
}