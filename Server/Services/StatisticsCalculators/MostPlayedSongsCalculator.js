/**
 * MostPlayedSongsCalculator.js
 * 
 * Calculator for most played songs statistics using song frequency analysis
 * across all shows in a tour. Identifies which songs appear most often
 * to highlight tour favorites and recurring themes.
 * 
 * Data Source: Song names from track durations (Phish.in) or setlist items (Phish.net)
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
             * Maps song names (lowercase) to play count data
             * Value: { count: number, songId: string, songName: string }
             */
            songPlayCounts: new Map()
        };
    }
    
    /**
     * Process a single show and update song frequency counts
     * 
     * Counts each unique song played in the show. Uses track durations
     * as the primary source since they contain the most complete song data
     * with proper song identification.
     * 
     * @param {Object} show - Enhanced setlist data for one show
     * @param {Object} dataContainer - Data collection container
     */
    processShow(show, dataContainer) {
        const { songPlayCounts } = dataContainer;
        
        // Count song frequencies using track durations as primary source
        if (show.trackDurations && Array.isArray(show.trackDurations)) {
            
            this.log(`🎵 Processing ${show.trackDurations.length} tracks from ${show.showDate}`);
            
            show.trackDurations.forEach(track => {
                const songKey = track.songName.toLowerCase();
                
                if (songPlayCounts.has(songKey)) {
                    // Increment existing song count
                    const existing = songPlayCounts.get(songKey);
                    songPlayCounts.set(songKey, {
                        count: existing.count + 1,
                        songId: existing.songId || track.songId,
                        songName: track.songName // Keep original case formatting
                    });
                    
                    this.log(`📈 ${track.songName}: ${existing.count} → ${existing.count + 1} plays`);
                } else {
                    // First occurrence of this song
                    songPlayCounts.set(songKey, {
                        count: 1,
                        songId: track.songId,
                        songName: track.songName
                    });
                    
                    this.log(`➕ ${track.songName}: First play tracked`);
                }
            });
        } else {
            this.log(`⚠️  No track duration data available for ${show.showDate}`);
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
    generateResults(dataContainer, tourName) {
        const { songPlayCounts } = dataContainer;
        
        const allSongCounts = Array.from(songPlayCounts.values());
        this.log(`📊 Analyzing play counts for ${allSongCounts.length} unique songs`);
        
        if (allSongCounts.length === 0) {
            this.log(`⚠️  No song play data found - cannot calculate most played songs`);
            return [];
        }
        
        // Convert counts to MostPlayedSong objects and sort by play count
        const mostPlayedSongs = allSongCounts
            .map(info => new MostPlayedSong(
                info.songId || BaseStatisticsCalculator.hashCode(info.songName),
                BaseStatisticsCalculator.capitalizeWords(info.songName),
                info.count
            ))
            .sort((a, b) => b.playCount - a.playCount)
            .slice(0, this.resultLimit);
        
        // Debug logging for top results
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
        
        // Check if at least some shows have track duration data for song counting
        const showsWithTracks = tourShows.filter(show => 
            show.trackDurations && show.trackDurations.length > 0
        );
        
        if (showsWithTracks.length === 0) {
            this.log(`⚠️  No track data found in ${tourShows.length} shows`);
            return false;
        }
        
        this.log(`✅ Found track data in ${showsWithTracks.length}/${tourShows.length} shows`);
        return true;
    }
}