/**
 * HistoricalDataEnhancer.js
 * 
 * Modular service for enhancing tour statistics with historical data from APIs.
 * Optimized to only make API calls for the top N results that will actually be displayed.
 * 
 * Features:
 * - Configuration-driven (easy to change from top 3 to top 10)
 * - Minimal API calls (only for results that will be displayed)
 * - Extensible to multiple statistics categories
 * - Rate limiting and error handling
 */

import StatisticsConfig from '../Config/StatisticsConfig.js';

/**
 * Service for enhancing tour statistics with historical data
 */
export class HistoricalDataEnhancer {
    /**
     * Initialize with API clients for historical data fetching
     * @param {Object} phishNetClient - PhishNetClient instance for historical API calls
     */
    constructor(phishNetClient) {
        this.phishNetClient = phishNetClient;
    }

    /**
     * Enhance complete tour statistics with historical data for top N results
     * 
     * @param {Object} tourStatistics - Complete tour statistics object
     * @returns {Object} Enhanced tour statistics with historical data
     */
    async enhanceStatistics(tourStatistics) {
        console.log('🔍 Enhancing tour statistics with historical data...');

        if (!StatisticsConfig.isHistoricalEnhancementEnabled()) {
            console.log('   ⚠️  Historical data enhancement is disabled in configuration');
            return tourStatistics;
        }

        // Create enhanced copy to avoid mutating original
        const enhancedStats = { ...tourStatistics };

        // Enhance each category that has historical enhancement enabled
        if (enhancedStats.rarestSongs) {
            enhancedStats.rarestSongs = await this.enhanceRarestSongs(enhancedStats.rarestSongs);
        }

        if (enhancedStats.longestSongs) {
            enhancedStats.longestSongs = await this.enhanceLongestSongs(enhancedStats.longestSongs);
        }

        if (enhancedStats.mostPlayedSongs) {
            enhancedStats.mostPlayedSongs = await this.enhanceMostPlayedSongs(enhancedStats.mostPlayedSongs);
        }

        console.log('✅ Historical data enhancement complete');
        return enhancedStats;
    }

    /**
     * Enhance rarest songs with historical last-played dates and venues
     * 
     * @param {Array} rarestSongs - Array of rarest song objects
     * @returns {Array} Enhanced rarest songs with historical data
     */
    async enhanceRarestSongs(rarestSongs) {
        const config = StatisticsConfig.getHistoricalEnhancementConfig('rarestSongs');
        
        if (!config.enabled || !rarestSongs.length) {
            console.log('   📊 Rarest songs: Enhancement disabled or no songs to enhance');
            return rarestSongs;
        }

        console.log(`   📊 Enhancing top ${config.enhanceTopN} rarest songs with historical data...`);

        // Only enhance the top N that will be displayed
        const topSongs = rarestSongs.slice(0, config.enhanceTopN);
        const remainingSongs = rarestSongs.slice(config.enhanceTopN);

        const enhancedTopSongs = await this.enhanceSongsWithHistoricalData(
            topSongs, 
            'rarestSongs',
            config
        );

        // Return top N enhanced + remaining unenhanced
        return [...enhancedTopSongs, ...remainingSongs];
    }

    /**
     * Enhance longest songs (placeholder for future feature)
     * 
     * @param {Array} longestSongs - Array of longest song objects
     * @returns {Array} Enhanced longest songs
     */
    async enhanceLongestSongs(longestSongs) {
        const config = StatisticsConfig.getHistoricalEnhancementConfig('longestSongs');
        
        if (!config.enabled) {
            console.log('   📊 Longest songs: Historical enhancement disabled');
            return longestSongs;
        }

        // TODO: Could add venue history, first performance dates, etc.
        console.log('   📊 Longest songs: Historical enhancement not yet implemented');
        return longestSongs;
    }

    /**
     * Enhance most played songs (placeholder for future feature)
     * 
     * @param {Array} mostPlayedSongs - Array of most played song objects
     * @returns {Array} Enhanced most played songs
     */
    async enhanceMostPlayedSongs(mostPlayedSongs) {
        const config = StatisticsConfig.getHistoricalEnhancementConfig('mostPlayedSongs');
        
        if (!config.enabled) {
            console.log('   📊 Most played songs: Historical enhancement disabled');
            return mostPlayedSongs;
        }

        // TODO: Could add debut dates, evolution history, etc.
        console.log('   📊 Most played songs: Historical enhancement not yet implemented');
        return mostPlayedSongs;
    }

    /**
     * Generic method to enhance an array of songs with historical data
     * 
     * @param {Array} songs - Array of song objects to enhance
     * @param {string} categoryName - Category name for logging
     * @param {Object} config - Enhancement configuration
     * @returns {Array} Enhanced songs with historical data
     */
    async enhanceSongsWithHistoricalData(songs, categoryName, config) {
        const enhancedSongs = [];

        for (let i = 0; i < songs.length; i++) {
            const song = songs[i];
            
            try {
                console.log(`     📡 [${i + 1}/${songs.length}] Fetching historical data for "${song.songName}" (gap: ${song.gap})...`);

                // Use the fetchSongGap method to get real historical data
                const historicalData = await this.phishNetClient.fetchSongGap(song.songName, song.tourDate);

                if (historicalData && historicalData.historicalLastPlayed) {
                    // Create enhanced song with historical data
                    const enhancedSong = {
                        ...song,
                        lastPlayed: historicalData.lastPlayed,
                        timesPlayed: historicalData.timesPlayed,
                        historicalLastPlayed: historicalData.historicalLastPlayed,
                        historicalVenue: historicalData.historicalVenue,
                        historicalCity: historicalData.historicalCity,
                        historicalState: historicalData.historicalState
                    };

                    enhancedSongs.push(enhancedSong);
                    console.log(`     ✅ Enhanced "${song.songName}": last played ${historicalData.historicalLastPlayed} at ${historicalData.historicalVenue || 'Unknown Venue'}`);
                } else {
                    // Keep original song if no historical data found
                    enhancedSongs.push(song);
                    console.log(`     ⚠️  No historical data found for "${song.songName}"`);
                }

            } catch (error) {
                // Keep original song if API call fails
                enhancedSongs.push(song);
                console.log(`     ❌ Failed to fetch historical data for "${song.songName}": ${error.message}`);
            }

            // Rate limiting delay between API calls
            if (i < songs.length - 1 && config.apiCallDelay > 0) {
                await new Promise(resolve => setTimeout(resolve, config.apiCallDelay));
            }
        }

        console.log(`     📊 Enhanced ${enhancedSongs.length} ${categoryName} with historical data`);
        return enhancedSongs;
    }
}

export default HistoricalDataEnhancer;