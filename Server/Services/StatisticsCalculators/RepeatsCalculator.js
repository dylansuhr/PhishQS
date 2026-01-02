/**
 * RepeatsCalculator.js
 *
 * Calculator for tracking song repeats and average gap across a tour.
 *
 * Repeats: A "repeat" is a song played in a show that was also played in any previous show
 * during the same tour. Playing a song twice within the same show does NOT count as a repeat.
 *
 * Average Gap: The average number of shows since each song was last played.
 * Higher average gap = "rarer" show overall. Excludes debuts (no prior performance).
 *
 * Data Source: Phish.net setlist data (includes gap field per song)
 * Output: Per-show data with repeats, repeat percentage, and average gap
 */

import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';

/**
 * Data for a single show in the repeats/gap graph
 */
export class RepeatShowData {
    constructor(date, venue, city, state, venueRun, totalSongs, repeats, repeatPercentage, averageGap, showNumber, totalTourShows) {
        this.date = date;
        this.venue = venue;
        this.city = city;
        this.state = state;
        this.venueRun = venueRun ? `N${venueRun.nightNumber}` : null;
        this.totalSongs = totalSongs;
        this.repeats = repeats;
        this.repeatPercentage = repeatPercentage;
        this.averageGap = averageGap;          // Average gap across all songs with gaps
        this.showNumber = showNumber;          // Show number in tour (e.g., 14)
        this.totalTourShows = totalTourShows;  // Total shows in tour (e.g., 23)
    }
}

/**
 * Calculator for song repeats statistics
 */
export class RepeatsCalculator extends BaseStatisticsCalculator {

    constructor(config = {}) {
        super(config);
        this.calculatorType = 'Repeats';
    }

    /**
     * Initialize data container for tracking songs played across shows
     */
    initializeDataContainer() {
        return {
            // Set of all unique songs played so far in the tour (lowercase song names)
            allSongsPlayedSoFar: new Set(),
            // Array of show data in chronological order
            showData: []
        };
    }

    /**
     * Process a single show and calculate repeats and average gap
     */
    processShow(show, dataContainer) {
        if (!show.setlistItems || !Array.isArray(show.setlistItems) || show.setlistItems.length === 0) {
            this.log(`⚠️  No setlist items for ${show.showDate}`);
            return;
        }

        // Get all songs from this show (all sets, all encores)
        // Note: Phish.net uses 'song' property, not 'songName'
        const songsThisShow = show.setlistItems.map(item => (item.song || item.songName)?.toLowerCase()).filter(Boolean);
        const totalSongs = songsThisShow.length;

        if (totalSongs === 0) {
            this.log(`⚠️  No valid songs for ${show.showDate}`);
            return;
        }

        // Count how many songs were played in previous shows (repeats)
        // Use a Set of unique song names from this show to avoid double-counting
        // if a song is played twice in the same show
        const uniqueSongsThisShow = new Set(songsThisShow);
        let repeats = 0;

        for (const song of uniqueSongsThisShow) {
            if (dataContainer.allSongsPlayedSoFar.has(song)) {
                repeats++;
            }
        }

        // Calculate repeat percentage based on total songs played (not unique)
        // If a song is played twice in the show, both count toward total
        const repeatPercentage = totalSongs > 0 ? (repeats / totalSongs) * 100 : 0;

        // Calculate average gap (excludes debuts which have no gap)
        // Gap = number of shows since song was last played
        const gaps = show.setlistItems
            .map(item => item.gap)
            .filter(gap => gap !== undefined && gap !== null && gap > 0);

        const songsWithGaps = gaps.length;
        const totalGap = gaps.reduce((sum, gap) => sum + gap, 0);
        const averageGap = songsWithGaps > 0 ? totalGap / songsWithGaps : 0;

        // Get venue info from Phish.net setlist (primary source)
        const firstItem = show.setlistItems[0];
        const venue = firstItem?.venue || show.venue;
        const city = firstItem?.city || show.venueRun?.city;
        const state = firstItem?.state || show.venueRun?.state;

        // Get tour position
        const showNumber = show.tourPosition?.showNumber || null;
        const totalTourShows = show.tourPosition?.totalShows || null;

        // Create show data object
        const showDataEntry = new RepeatShowData(
            show.showDate,
            venue,
            city,
            state,
            show.venueRun,
            totalSongs,
            repeats,
            Math.round(repeatPercentage * 10) / 10,  // Round to 1 decimal place
            Math.round(averageGap * 10) / 10,        // Round to 1 decimal place
            showNumber,
            totalTourShows
        );

        dataContainer.showData.push(showDataEntry);

        // Add all unique songs from this show to the running total
        for (const song of uniqueSongsThisShow) {
            dataContainer.allSongsPlayedSoFar.add(song);
        }

        this.log(`📊 ${show.showDate}: ${totalSongs} songs, ${repeats} repeats (${showDataEntry.repeatPercentage}%), avg gap: ${showDataEntry.averageGap}`);
    }

    /**
     * Generate final results - array of show data for the graph
     */
    generateResults(dataContainer, tourName, context = {}) {
        const { showData } = dataContainer;

        if (showData.length === 0) {
            this.log(`⚠️  No show data collected`);
            return {
                shows: [],
                hasRepeats: false,
                maxPercentage: 0,
                maxAverageGap: 0,
                totalShows: 0
            };
        }

        // Check if there were any repeats at all (for Baker's Dozen scenario)
        const hasRepeats = showData.some(show => show.repeats > 0);

        // Find max values for Y-axis scaling
        const maxPercentage = Math.max(...showData.map(show => show.repeatPercentage));
        const maxAverageGap = Math.max(...showData.map(show => show.averageGap));

        this.log(`🎯 Repeats: ${showData.length} shows, hasRepeats: ${hasRepeats}, maxPercentage: ${maxPercentage}%, maxAvgGap: ${maxAverageGap}`);

        return {
            shows: showData,
            hasRepeats,
            maxPercentage,
            maxAverageGap,
            totalShows: showData.length
        };
    }

    /**
     * Override calculate to return object instead of array
     */
    calculate(tourShows, tourName, context = {}) {
        this.log(`🧮 ${this.calculatorType}: Starting calculation for ${tourShows?.length || 0} shows`);

        if (!this.validateInput(tourShows, tourName)) {
            this.log(`⚠️  ${this.calculatorType}: Invalid input, returning empty results`);
            return {
                shows: [],
                hasRepeats: false,
                maxPercentage: 0,
                maxAverageGap: 0,
                totalShows: 0
            };
        }

        const dataContainer = this.initializeDataContainer();

        // Sort shows by date to ensure chronological processing
        const sortedShows = [...tourShows].sort((a, b) =>
            new Date(a.showDate) - new Date(b.showDate)
        );

        sortedShows.forEach((show, index) => {
            this.log(`📅 Processing show ${index + 1}/${sortedShows.length}: ${show.showDate}`);
            this.processShow(show, dataContainer);
        });

        const results = this.generateResults(dataContainer, tourName, context);

        this.log(`✅ ${this.calculatorType}: Generated data for ${results.totalShows} shows`);

        return results;
    }
}
