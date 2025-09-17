/**
 * LongestSongsCalculator.js
 * 
 * Calculator for longest songs statistics using track duration data from Phish.in API.
 * Identifies and ranks songs by performance duration to find the most extended
 * versions played during a tour.
 * 
 * Data Source: Phish.in API track duration data (only available source for durations)
 * Algorithm: Collect all durations, sort by length, return top N
 * Business Logic: Longer = better for jam analysis and performance highlights
 */

import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';
import { TrackDuration } from '../../Models/TourStatistics.js';

/**
 * Calculator for longest songs statistics
 * 
 * Processes track duration data from enhanced setlists to identify
 * the longest song performances during a tour.
 */
export class LongestSongsCalculator extends BaseStatisticsCalculator {
    
    /**
     * Initialize longest songs calculator
     * @param {Object} config - Configuration options
     */
    constructor(config = {}) {
        super(config);
        this.calculatorType = 'LongestSongs';
    }
    
    /**
     * Initialize data container for collecting track durations
     * @returns {Object} Data container with duration collection array
     */
    initializeDataContainer() {
        return {
            /** @type {Array<TrackDuration>} All track durations from tour shows */
            allTrackDurations: []
        };
    }
    
    /**
     * Process a single show and collect track duration data
     * 
     * Extracts all track durations from the show and adds them to the collection.
     * Each track duration includes venue context and performance metadata.
     * 
     * @param {Object} show - Enhanced setlist data for one show
     * @param {Object} dataContainer - Data collection container
     */
    processShow(show, dataContainer) {
        // Collect track durations for longest songs calculation
        if (show.trackDurations && Array.isArray(show.trackDurations)) {
            // Enhance each track duration with tour context from the show
            const enhancedTracks = show.trackDurations.map(track => {
                return this.enhanceTrackWithTourContext(track, show);
            });
            
            // Add enhanced track durations to the master collection
            dataContainer.allTrackDurations.push(...enhancedTracks);
            
            this.log(`🎵 Collected ${show.trackDurations.length} enhanced track durations from ${show.showDate}`);
        } else {
            this.log(`⚠️  No track durations available for ${show.showDate}`);
        }
    }
    
    /**
     * Generate final longest songs results
     * 
     * Sorts all collected track durations by length (longest first)
     * and returns the top performers with venue context.
     * 
     * @param {Object} dataContainer - Container with all collected durations
     * @param {string} tourName - Tour name for context
     * @returns {Array<TrackDuration>} Top longest songs with performance details
     */
    generateResults(dataContainer, tourName, context = {}) {
        const { allTrackDurations } = dataContainer;
        
        this.log(`📊 Analyzing ${allTrackDurations.length} total track durations for longest songs`);
        
        if (allTrackDurations.length === 0) {
            this.log(`⚠️  No track durations found - cannot calculate longest songs`);
            return [];
        }
        
        // Sort by duration (longest first), then alphabetically for ties
        const longestSongs = allTrackDurations
            .sort((a, b) => {
                // Primary sort: by duration (descending) - longest first
                if (b.durationSeconds !== a.durationSeconds) {
                    return b.durationSeconds - a.durationSeconds;
                }
                // Secondary sort: by song name (ascending/alphabetical) when durations are tied
                return a.songName.localeCompare(b.songName);
            })
            .slice(0, this.resultLimit);
        
        // Debug logging for top results
        this.log(`🏆 Top ${longestSongs.length} longest songs in ${tourName}:`);
        longestSongs.forEach((song, index) => {
            const minutes = Math.floor(song.durationSeconds / 60);
            const seconds = song.durationSeconds % 60;
            this.log(`   ${index + 1}. ${song.songName}: ${minutes}m ${seconds}s at ${song.venue} (${song.showDate})`);
        });
        
        return longestSongs;
    }
    
    /**
     * Validate that tour shows contain duration data
     * @param {Array} tourShows - Tour shows array
     * @param {string} tourName - Tour name
     * @returns {boolean} True if valid and contains duration data
     */
    validateInput(tourShows, tourName) {
        if (!super.validateInput(tourShows, tourName)) {
            return false;
        }
        
        // Check if at least some shows have track durations
        const showsWithDurations = tourShows.filter(show => 
            show.trackDurations && show.trackDurations.length > 0
        );
        
        if (showsWithDurations.length === 0) {
            this.log(`⚠️  No track duration data found in ${tourShows.length} shows`);
            return false;
        }
        
        this.log(`✅ Found duration data in ${showsWithDurations.length}/${tourShows.length} shows`);
        return true;
    }
    
    /**
     * Enhance track duration with tour context information from show data
     * @param {Object} track - Original track duration object
     * @param {Object} show - Show data containing venue run and tour position
     * @returns {TrackDuration} Enhanced track with tour context
     */
    enhanceTrackWithTourContext(track, show) {
        // Extract city and state from Phish.net show data first, fallback to venue run
        let city = null;
        let state = null;
        
        // First try to get city/state from Phish.net show data (more accurate for all venues)
        if (show.showVenueInfo) {
            city = show.showVenueInfo.city;
            state = show.showVenueInfo.state;
        }
        
        // Fallback to venue run if not available from show data
        if (!city && show.venueRun) {
            city = show.venueRun.city;
            state = show.venueRun.state;
        }
        
        // Create enhanced TrackDuration with tour context
        return new TrackDuration(
            track.id,
            track.songName,
            track.songId,
            track.durationSeconds,
            track.showDate,
            track.setNumber,
            track.venue || show.setlistItems?.[0]?.venue,
            track.venueRun || show.venueRun,
            {
                city: city,
                state: state,
                tourPosition: show.tourPosition
            }
        );
    }
}