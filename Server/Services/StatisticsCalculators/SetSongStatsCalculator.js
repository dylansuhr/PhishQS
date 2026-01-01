/**
 * SetSongStatsCalculator.js
 *
 * Calculator for songs per set statistics.
 * Identifies shows with the most and fewest songs per set type across a tour.
 * Handles varying set structures (1 set, 2 sets, 3 sets, multiple encores).
 *
 * Data Source: Phish.net setlist data
 * Algorithm: Count songs per set for each show, find min/max per set type
 * Output: Min/max shows for each set type with venue context
 */

import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';

/**
 * Show data for set song statistics
 */
export class SetSongShow {
    constructor(date, venue, city, state, venueRun = null) {
        this.date = date;
        this.venue = venue;
        this.city = city;
        this.state = state;
        this.venueRun = venueRun ? `N${venueRun.nightNumber}` : null;
    }
}

/**
 * Min or max extreme for a set type
 */
export class SetSongExtreme {
    constructor(count, shows) {
        this.count = count;
        this.shows = shows; // Array of SetSongShow for ties
    }
}

/**
 * Statistics for a single set type
 */
export class SetSongStats {
    constructor(min, max) {
        this.min = min; // SetSongExtreme
        this.max = max; // SetSongExtreme
    }
}

/**
 * Calculator for songs per set statistics
 */
export class SetSongStatsCalculator extends BaseStatisticsCalculator {

    constructor(config = {}) {
        super(config);
        this.calculatorType = 'SetSongStats';
    }

    /**
     * Initialize data container for collecting set counts per show
     */
    initializeDataContainer() {
        return {
            // Map of set type -> array of { count, showData }
            setCountsByType: new Map()
        };
    }

    /**
     * Process a single show and count songs in each set
     */
    processShow(show, dataContainer) {
        if (!show.setlistItems || !Array.isArray(show.setlistItems) || show.setlistItems.length === 0) {
            this.log(`⚠️  No setlist items for ${show.showDate}`);
            return;
        }

        // Count songs per set for this show
        const setCounts = {};
        for (const item of show.setlistItems) {
            // Normalize set key to lowercase ("E" -> "e")
            const setKey = (item.set || '1').toLowerCase();
            setCounts[setKey] = (setCounts[setKey] || 0) + 1;
        }

        // Get venue info from Phish.net setlist (primary source)
        const firstItem = show.setlistItems[0];
        const venue = firstItem?.venue || show.venue;
        const city = firstItem?.city || show.venueRun?.city;
        const state = firstItem?.state || show.venueRun?.state;

        // Create show data object
        const showData = new SetSongShow(
            show.showDate,
            venue,
            city,
            state,
            show.venueRun
        );

        // Add counts to the collection grouped by set type
        for (const [setKey, count] of Object.entries(setCounts)) {
            if (!dataContainer.setCountsByType.has(setKey)) {
                dataContainer.setCountsByType.set(setKey, []);
            }
            dataContainer.setCountsByType.get(setKey).push({
                count,
                showData
            });
        }

        this.log(`📊 ${show.showDate}: ${Object.entries(setCounts).map(([k, v]) => `Set ${k}: ${v}`).join(', ')}`);
    }

    /**
     * Generate final results with min/max per set type
     */
    generateResults(dataContainer, tourName, context = {}) {
        const { setCountsByType } = dataContainer;

        if (setCountsByType.size === 0) {
            this.log(`⚠️  No set data collected`);
            return {};
        }

        const results = {};

        // Process each set type
        for (const [setKey, showCounts] of setCountsByType) {
            // Find min and max counts
            const counts = showCounts.map(sc => sc.count);
            const minCount = Math.min(...counts);
            const maxCount = Math.max(...counts);

            // Find all shows with min count (handles ties)
            const minShows = showCounts
                .filter(sc => sc.count === minCount)
                .map(sc => sc.showData);

            // Find all shows with max count (handles ties)
            const maxShows = showCounts
                .filter(sc => sc.count === maxCount)
                .map(sc => sc.showData);

            results[setKey] = new SetSongStats(
                new SetSongExtreme(minCount, minShows),
                new SetSongExtreme(maxCount, maxShows)
            );

            this.log(`🎯 Set ${setKey}: Min ${minCount} songs (${minShows.length} shows), Max ${maxCount} songs (${maxShows.length} shows)`);
        }

        return results;
    }

    /**
     * Override calculate to return object instead of array
     * (This calculator returns a keyed object, not an array)
     */
    calculate(tourShows, tourName, context = {}) {
        this.log(`🧮 ${this.calculatorType}: Starting calculation for ${tourShows?.length || 0} shows`);

        if (!this.validateInput(tourShows, tourName)) {
            this.log(`⚠️  ${this.calculatorType}: Invalid input, returning empty results`);
            return {};
        }

        const dataContainer = this.initializeDataContainer();

        tourShows.forEach((show, index) => {
            this.log(`📅 Processing show ${index + 1}/${tourShows.length}: ${show.showDate}`);
            this.processShow(show, dataContainer);
        });

        const results = this.generateResults(dataContainer, tourName, context);

        this.log(`✅ ${this.calculatorType}: Generated stats for ${Object.keys(results).length} set types`);

        return results;
    }
}
