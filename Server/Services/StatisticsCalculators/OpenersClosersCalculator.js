/**
 * OpenersClosersCalculator.js
 *
 * Calculator for set openers, closers, and encore statistics.
 * Tracks which songs open and close each set, and all encore songs,
 * with play counts across the tour.
 *
 * Data Source: Phish.net setlist data
 * Algorithm: For each show, identify first/last song per set, all encore songs
 * Output: Keyed object with arrays of songs sorted by play count
 */

import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';

/**
 * Song with play count for a position (opener/closer/encore)
 */
export class PositionSong {
    constructor(songName, songId, count) {
        this.songName = songName;
        this.songId = songId;
        this.count = count;
    }
}

/**
 * Calculator for openers, closers, and encores statistics
 */
export class OpenersClosersCalculator extends BaseStatisticsCalculator {

    constructor(config = {}) {
        super(config);
        this.calculatorType = 'OpenersClosers';
    }

    /**
     * Initialize data container for tracking song counts by position
     */
    initializeDataContainer() {
        return {
            // Map of position key -> Map of songKey -> { songName, songId, count }
            // Position keys: "1_opener", "1_closer", "2_opener", "2_closer", "e_all", etc.
            positionCounts: new Map()
        };
    }

    /**
     * Add a song to a position's count
     */
    addSongToPosition(dataContainer, positionKey, item) {
        const { positionCounts } = dataContainer;

        if (!positionCounts.has(positionKey)) {
            positionCounts.set(positionKey, new Map());
        }

        const songMap = positionCounts.get(positionKey);
        const songKey = item.song.toLowerCase();

        if (songMap.has(songKey)) {
            const existing = songMap.get(songKey);
            songMap.set(songKey, {
                songName: item.song,
                songId: existing.songId || item.songid,
                count: existing.count + 1
            });
        } else {
            songMap.set(songKey, {
                songName: item.song,
                songId: item.songid,
                count: 1
            });
        }
    }

    /**
     * Process a single show and track openers, closers, and encores
     */
    processShow(show, dataContainer) {
        if (!show.setlistItems || !Array.isArray(show.setlistItems) || show.setlistItems.length === 0) {
            this.log(`⚠️  No setlist items for ${show.showDate}`);
            return;
        }

        // Group setlist items by set
        const setGroups = {};
        for (const item of show.setlistItems) {
            const setKey = (item.set || '1').toLowerCase();
            if (!setGroups[setKey]) {
                setGroups[setKey] = [];
            }
            setGroups[setKey].push(item);
        }

        // Process each set
        for (const [setKey, items] of Object.entries(setGroups)) {
            if (items.length === 0) continue;

            if (setKey.startsWith('e')) {
                // Encore: track ALL songs
                items.forEach(item => {
                    this.addSongToPosition(dataContainer, `${setKey}_all`, item);
                });
                this.log(`🎤 ${show.showDate} Encore ${setKey}: ${items.length} songs`);
            } else {
                // Regular set: track opener (first) and closer (last)
                const opener = items[0];
                const closer = items[items.length - 1];

                this.addSongToPosition(dataContainer, `${setKey}_opener`, opener);
                this.addSongToPosition(dataContainer, `${setKey}_closer`, closer);

                this.log(`🎵 ${show.showDate} Set ${setKey}: Opener "${opener.song}", Closer "${closer.song}"`);
            }
        }
    }

    /**
     * Generate final results with sorted song arrays per position
     */
    generateResults(dataContainer, tourName, context = {}) {
        const { positionCounts } = dataContainer;

        if (positionCounts.size === 0) {
            this.log(`⚠️  No position data collected`);
            return {};
        }

        const results = {};

        // Convert each position's Map to sorted array
        for (const [positionKey, songMap] of positionCounts) {
            const songsArray = Array.from(songMap.values())
                .map(info => new PositionSong(
                    BaseStatisticsCalculator.capitalizeWords(info.songName),
                    info.songId,
                    info.count
                ))
                .sort((a, b) => {
                    // Sort by count descending, then alphabetically
                    if (b.count !== a.count) {
                        return b.count - a.count;
                    }
                    return a.songName.localeCompare(b.songName);
                });

            results[positionKey] = songsArray;

            this.log(`🎯 ${positionKey}: ${songsArray.length} unique songs`);
            if (songsArray.length > 0) {
                this.log(`   Top: "${songsArray[0].songName}" (${songsArray[0].count}x)`);
            }
        }

        return results;
    }

    /**
     * Override calculate to return object instead of array
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

        this.log(`✅ ${this.calculatorType}: Generated stats for ${Object.keys(results).length} positions`);

        return results;
    }
}
