/**
 * DebutsCalculator.js
 *
 * Calculator for identifying song debuts during a tour.
 * A "debut" is a song played for the very first time by Phish.
 *
 * Detection: Uses footnote field from Phish.net setlist data.
 * Pattern: footnote.toLowerCase().startsWith('debut') or startsWith('phish debut')
 *
 * Note: Side project debuts (TAB, Mike Gordon) are already filtered out
 * because they have different artist_name values in the setlist data.
 *
 * Data Source: Phish.net setlist footnotes
 * Output: Array of debut songs with venue/date context
 */

import { BaseStatisticsCalculator } from './BaseStatisticsCalculator.js';

/**
 * Debut song information
 */
export class DebutInfo {
    constructor(songId, songName, footnote, showDate, options = {}) {
        this.id = songId;
        this.songId = songId;
        this.songName = songName;
        this.footnote = footnote;
        this.showDate = showDate;
        this.venue = options.venue || null;
        this.venueRun = options.venueRun || null;
        this.city = options.city || null;
        this.state = options.state || null;
        this.tourPosition = options.tourPosition || null;
        this.originalArtist = options.originalArtist || null;  // Original artist for covers
    }
}

/**
 * Calculator for tour debuts statistics
 */
export class DebutsCalculator extends BaseStatisticsCalculator {

    constructor(config = {}) {
        super(config);
        this.calculatorType = 'Debuts';
    }

    /**
     * Initialize data container for tracking debuts
     */
    initializeDataContainer(context = {}) {
        // Build songId -> artist lookup map from comprehensive songs
        const artistLookup = new Map();
        if (context.comprehensiveSongs && Array.isArray(context.comprehensiveSongs)) {
            context.comprehensiveSongs.forEach(song => {
                if (song.songid && song.artist) {
                    artistLookup.set(song.songid, song.artist);
                }
            });
            this.log(`📚 Built artist lookup with ${artistLookup.size} songs`);
        }

        return {
            debuts: [],
            latestShowDate: null,
            artistLookup: artistLookup
        };
    }

    /**
     * Process a single show and check for debut songs
     */
    processShow(show, dataContainer) {
        // Track latest show date for empty state display
        if (!dataContainer.latestShowDate || show.showDate > dataContainer.latestShowDate) {
            dataContainer.latestShowDate = show.showDate;
        }

        if (!show.setlistItems || !Array.isArray(show.setlistItems)) {
            this.log(`⚠️  No setlist items for ${show.showDate}`);
            return;
        }

        // Get venue info from first setlist item (Phish.net source)
        const firstItem = show.setlistItems[0];
        const venue = firstItem?.venue || show.venue;
        const city = firstItem?.city || show.showVenueInfo?.city || show.venueRun?.city;
        const state = firstItem?.state || show.showVenueInfo?.state || show.venueRun?.state;

        // Check each song's footnote for debut indicator
        show.setlistItems.forEach(item => {
            const footnote = (item.footnote || '').toLowerCase().trim();

            // Check for debut patterns
            // "Phish debut." or "Debut." or "Phish debut; with..."
            if (footnote.startsWith('debut') || footnote.startsWith('phish debut')) {
                // Look up original artist from comprehensive songs database
                const originalArtist = dataContainer.artistLookup.get(item.songid) || null;

                const debutInfo = new DebutInfo(
                    item.songid,
                    item.song,
                    item.footnote,  // Keep original footnote for display
                    show.showDate,
                    {
                        venue: venue,
                        venueRun: show.venueRun,
                        city: city,
                        state: state,
                        tourPosition: show.tourPosition,
                        originalArtist: originalArtist
                    }
                );

                dataContainer.debuts.push(debutInfo);
                const artistText = originalArtist && originalArtist !== 'Phish' ? ` (${originalArtist})` : '';
                this.log(`🎉 Debut found: "${item.song}"${artistText} on ${show.showDate} - ${item.footnote}`);
            }
        });
    }

    /**
     * Generate final results - object with songs array and latest show date
     */
    generateResults(dataContainer, tourName, context = {}) {
        const { debuts, latestShowDate } = dataContainer;

        if (debuts.length === 0) {
            this.log(`📊 No debuts found in ${tourName}`);
            return {
                songs: [],
                latestShowDate: latestShowDate
            };
        }

        // Sort by date (most recent first), then by song name for ties
        const sortedDebuts = debuts.sort((a, b) => {
            if (a.showDate !== b.showDate) {
                return b.showDate.localeCompare(a.showDate);
            }
            return a.songName.localeCompare(b.songName);
        });

        this.log(`🎯 Debuts: Found ${sortedDebuts.length} debut(s) in ${tourName}`);
        sortedDebuts.forEach((debut, index) => {
            this.log(`   ${index + 1}. ${debut.songName} (${debut.showDate})`);
        });

        return {
            songs: sortedDebuts,
            latestShowDate: latestShowDate
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
                songs: [],
                latestShowDate: null
            };
        }

        const dataContainer = this.initializeDataContainer(context);

        // Sort shows by date to ensure chronological processing
        const sortedShows = [...tourShows].sort((a, b) =>
            new Date(a.showDate) - new Date(b.showDate)
        );

        sortedShows.forEach((show, index) => {
            this.log(`📅 Processing show ${index + 1}/${sortedShows.length}: ${show.showDate}`);
            this.processShow(show, dataContainer);
        });

        const results = this.generateResults(dataContainer, tourName, context);

        this.log(`✅ ${this.calculatorType}: Found ${results.songs.length} debut(s)`);

        return results;
    }
}
