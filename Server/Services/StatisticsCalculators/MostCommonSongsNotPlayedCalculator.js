/**
 * MostCommonSongsNotPlayedCalculator.js
 *
 * Calculator for most common songs not played statistics.
 * Identifies popular songs from Phish history that haven't been played on the current tour.
 *
 * Data Strategy: Uses comprehensive song database passed from generation context
 * Business Logic: Higher historical play count = more notable absence from tour
 * Algorithm: Filter comprehensive songs → remove current tour songs → sort by play count
 */

import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';
import { MostCommonSongNotPlayed } from '../../Models/TourStatistics.js';

/**
 * Calculator for most common songs not played statistics
 *
 * Identifies songs with high historical play counts that are absent from
 * the current tour, highlighting notable omissions that fans might expect.
 */
export class MostCommonSongsNotPlayedCalculator extends BaseStatisticsCalculator {

    /**
     * Initialize most common songs not played calculator
     * @param {Object} config - Configuration options
     */
    constructor(config = {}) {
        super(config);
        this.calculatorType = 'MostCommonSongsNotPlayed';
    }

    /**
     * Initialize data container for tracking songs
     * @returns {Object} Data container with song tracking
     */
    initializeDataContainer() {
        return {
            /** @type {Set<string>} Songs played during current tour (lowercase for matching) */
            currentTourSongs: new Set(),

            /** @type {Array<Object>} All songs in comprehensive database */
            comprehensiveSongs: [],

            /** @type {string} Tour name for context */
            tourName: ''
        };
    }

    /**
     * Process a single show and track songs played
     *
     * Builds a set of all songs played during the current tour for exclusion
     * from the comprehensive song database.
     *
     * @param {Object} show - Enhanced setlist data for one show
     * @param {Object} dataContainer - Data collection container
     */
    processShow(show, dataContainer) {
        const { currentTourSongs } = dataContainer;

        // Track songs played during current tour
        if (show.setlistItems && Array.isArray(show.setlistItems)) {
            this.log(`🎵 Processing ${show.setlistItems.length} songs from ${show.showDate}`);

            show.setlistItems.forEach(item => {
                // Use lowercase for case-insensitive matching
                const songKey = item.song.toLowerCase();
                currentTourSongs.add(songKey);

                this.log(`➕ Added to tour songs: ${item.song}`);
            });
        } else {
            this.log(`⚠️  No setlist data available for ${show.showDate}`);
        }
    }

    /**
     * Generate final most common songs not played results
     *
     * Uses the comprehensive song database to find commonly played songs
     * that are absent from the current tour.
     *
     * @param {Object} dataContainer - Container with tour song data
     * @param {string} tourName - Tour name for context
     * @param {Array} comprehensiveSongs - Complete song database from generation
     * @returns {Array<MostCommonSongNotPlayed>} Most common songs not played
     */
    generateResults(dataContainer, tourName, context = {}) {
        // Extract comprehensive songs from context
        const comprehensiveSongs = context.comprehensiveSongs || [];
        const { currentTourSongs } = dataContainer;

        this.log(`📊 Analyzing ${currentTourSongs.size} tour songs vs ${comprehensiveSongs.length} comprehensive songs`);

        if (comprehensiveSongs.length === 0) {
            this.log(`⚠️  No comprehensive song database provided - cannot calculate most common songs not played`);
            return [];
        }

        if (currentTourSongs.size === 0) {
            this.log(`⚠️  No tour songs found - all songs would be "not played"`);
            return [];
        }

        // Filter comprehensive songs to commonly played songs (100+ times)
        const commonSongs = comprehensiveSongs.filter(song => song.times_played >= 100);
        this.log(`🎯 Found ${commonSongs.length} commonly played songs (100+ times)`);

        // Remove songs that were played during current tour
        const notPlayedButCommon = commonSongs.filter(song => {
            const songKey = song.song.toLowerCase();
            return !currentTourSongs.has(songKey);
        });

        this.log(`🚫 Found ${notPlayedButCommon.length} common songs not played on tour`);

        // Sort by historical play count (highest first) and take top results
        const results = notPlayedButCommon
            .sort((a, b) => b.times_played - a.times_played)
            .slice(0, this.resultLimit)
            .map(song => {
                return new MostCommonSongNotPlayed(
                    song.songid || BaseStatisticsCalculator.hashCode(song.song),
                    BaseStatisticsCalculator.capitalizeWords(song.song),
                    song.times_played,
                    song.artist
                );
            });

        // Debug logging for results
        this.log(`🏆 Top ${results.length} most common songs not played in ${tourName}:`);
        results.forEach((song, index) => {
            const songType = song.originalArtist === 'Phish' ? 'Original' : `Cover (${song.originalArtist})`;
            this.log(`   ${index + 1}. ${song.songName}: ${song.historicalPlayCount} times - ${songType}`);
        });

        // Additional debug: Show what was filtered out
        if (this.debugMode) {
            const playedCommonSongs = commonSongs.filter(song => {
                const songKey = song.song.toLowerCase();
                return currentTourSongs.has(songKey);
            });

            this.log(`📈 Common songs that WERE played on tour: ${playedCommonSongs.length}`);
            playedCommonSongs.slice(0, 5).forEach(song => {
                this.log(`   ✅ ${song.song}: ${song.times_played} times`);
            });
        }

        return results;
    }

    /**
     * Validate that we have the necessary data for calculation
     * @param {Array} tourShows - Tour shows array
     * @param {string} tourName - Tour name
     * @returns {boolean} True if valid and contains necessary data
     */
    validateInput(tourShows, tourName) {
        if (!super.validateInput(tourShows, tourName)) {
            return false;
        }

        // Check if at least some shows have setlist data
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