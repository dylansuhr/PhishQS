/**
 * PhishNetClient.js
 * 
 * JavaScript port of iOS PhishNetAPIClient.swift
 * Provides access to the Phish.net API v5 for setlist data and gap calculations.
 * 
 * Phish.net is the authoritative source for:
 * - Complete setlist data with song order and transitions
 * - Gap calculations (shows since song was last played)
 * - Official venue names that match setlist context
 * - Comprehensive Phish show database
 * 
 * Business Rules:
 * - Gap data embedded in setlist responses is live and current
 * - Venue names from Phish.net must be paired with show dates from same source
 * - This API provides no duration data (use Phish.in for durations)
 * 
 * @see https://api.phish.net/v5/docs for API documentation
 */

import fetch from 'node-fetch';

/**
 * Client for interacting with Phish.net API v5
 * Handles authentication and provides methods for fetching setlist and show data
 */
export class PhishNetClient {
    /**
     * Initialize PhishNetClient with API key
     * @param {string} apiKey - Valid Phish.net API key for authentication
     */
    constructor(apiKey) {
        /** @type {string} Base URL for Phish.net API v5 */
        this.baseURL = 'https://api.phish.net/v5';
        /** @type {string} API key for authentication */
        this.apiKey = apiKey;
    }

    /**
     * Fetch the latest show (most recent chronologically)
     * 
     * Business Logic:
     * - Tries current year first for performance
     * - Falls back to previous year if no shows found
     * - Filters to Phish shows only (excludes side projects)
     * - Returns most recent by show date
     * 
     * @returns {Promise<Object|null>} Latest show object or null if none found
     * @throws {Error} If API request fails
     * 
     * Port of iOS PhishNetAPIClient.fetchLatestShow() lines 58-78
     */
    async fetchLatestShow() {
        const currentYear = new Date().getFullYear();
        
        try {
            // Try current year first (same as iOS)
            const shows = await this.fetchShows(String(currentYear));
            const phishShows = this.filterPhishShows(shows);
            const sortedShows = phishShows.sort((a, b) => b.showdate.localeCompare(a.showdate));
            
            if (sortedShows.length > 0) {
                return sortedShows[0];
            }
        } catch (error) {
            // Continue to try previous year (same as iOS line 70)
        }
        
        // Try previous year if no Phish shows this year (same as iOS lines 73-78)
        const previousYear = currentYear - 1;
        const previousShows = await this.fetchShows(String(previousYear));
        const phishShows = this.filterPhishShows(previousShows);
        const sortedShows = phishShows.sort((a, b) => b.showdate.localeCompare(a.showdate));
        
        return sortedShows.length > 0 ? sortedShows[0] : null;
    }

    /**
     * Fetch all shows for a given year
     * 
     * @param {string} year - Year to fetch shows for (e.g., '2025')
     * @returns {Promise<Array>} Array of show objects for the specified year
     * @throws {Error} If API request fails
     * 
     * Port of iOS PhishNetAPIClient.fetchShows() lines 31-55
     */
    async fetchShows(year) {
        // Try different endpoint formats based on Phish.net documentation
        const possibleUrls = [
            `${this.baseURL}/shows/showyear/${year}.json?apikey=${this.apiKey}&order_by=showdate&limit=1000`,
            `${this.baseURL}/v5/shows/year/${year}.json?apikey=${this.apiKey}&order_by=showdate&limit=1000`,
            `${this.baseURL}/shows/year/${year}.json?apikey=${this.apiKey}&order_by=showdate&limit=1000`
        ];
        
        let lastError;
        
        for (const url of possibleUrls) {
            try {
                console.log(`   🔍 Trying endpoint: ${url.replace(/apikey=[^&]*/, 'apikey=***')}`);
                const response = await fetch(url);
                
                if (response.ok) {
                    const showResponse = await response.json();
                    console.log(`   ✅ Success with: ${url.split('?')[0]}`);
                    const allShows = showResponse.data || [];
                    
                    // Filter to Phish shows only and normalize field names for compatibility
                    const phishShows = allShows
                        .filter(show => show.artist_name && show.artist_name.toLowerCase().includes('phish'))
                        .map(show => ({
                            ...show,
                            tourname: show.tour_name || show.tourname // Normalize field name
                        }));
                    
                    console.log(`   🎸 Filtered to ${phishShows.length} Phish shows from ${allShows.length} total shows`);
                    return phishShows;
                }
                
                lastError = new Error(`HTTP error: ${response.status}`);
            } catch (error) {
                lastError = error;
                continue;
            }
        }
        
        // If all endpoints fail, fall back to original setlists endpoint
        console.log(`   ⚠️  All shows endpoints failed, falling back to setlists endpoint`);
        const fallbackUrl = `${this.baseURL}/setlists/showyear/${year}.json?apikey=${this.apiKey}&artist=phish`;
        const response = await fetch(fallbackUrl);
        
        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        const showResponse = await response.json();
        return showResponse.data || [];
    }

    /**
     * Fetch setlist for a specific show date
     * 
     * CRITICAL: Setlist items contain live gap data embedded in response.
     * This gap data is current and should be used for statistics calculations
     * rather than the stale data from the general /songs.json endpoint.
     * 
     * @param {string} showDate - Show date in YYYY-MM-DD format
     * @returns {Promise<Array>} Array of setlist items with embedded gap data
     * @throws {Error} If API request fails
     * 
     * Port of iOS PhishNetAPIClient.fetchSetlist() lines 108-132
     */
    async fetchSetlist(showDate) {
        const url = `${this.baseURL}/setlists/showdate/${showDate}.json?apikey=${this.apiKey}&artist=phish`;
        
        const response = await fetch(url);
        
        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        const setlistResponse = await response.json();
        return setlistResponse.data || [];
    }


    /**
     * Fetch complete performance history for a song (includes gap data for each performance)
     * 
     * Uses the slug endpoint for better URL handling. This provides chronological
     * performance data that allows calculating historical last-played dates.
     * 
     * @param {string} songName - Name of song to fetch performance history for
     * @returns {Promise<Array>} Array of performance objects with dates and venues
     * @throws {Error} If API request fails
     * 
     * Port of iOS PhishNetAPIClient.fetchSongPerformanceHistory() lines 361-391
     */
    async fetchSongPerformanceHistory(songName) {
        // Use the slug endpoint for better URL handling
        const slugName = songName.toLowerCase()
            .replace(/ /g, '-')
            .replace(/'/g, '')
            .replace(/\./g, '')
            .replace(/,/g, '');

        const url = `${this.baseURL}/setlists/slug/${slugName}.json?apikey=${this.apiKey}`;

        const response = await fetch(url);

        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        const performanceResponse = await response.json();
        return performanceResponse.data || [];
    }

    /**
     * Fetch gap information for a specific song on a specific show date
     * 
     * This method replicates the iOS logic that gets real historical dates by:
     * 1. Fetching complete performance history for the song
     * 2. Finding the performance on the target show date
     * 3. Locating the previous performance that created the gap
     * 4. Extracting the historical last-played date and venue
     * 
     * @param {string} songName - Name of song to fetch gap info for
     * @param {string} showDate - Show date in YYYY-MM-DD format
     * @returns {Promise<Object|null>} Gap info with historical data or null if not found
     * @throws {Error} If API request fails
     * 
     * Port of iOS PhishNetAPIClient.fetchSongGap() lines 298-336
     */
    async fetchSongGap(songName, showDate) {
        const performances = await this.fetchSongPerformanceHistory(songName);

        // Find the performance matching the show date
        const currentPerformanceIndex = performances.findIndex(p => p.showdate === showDate);
        const currentPerformance = performances.find(p => p.showdate === showDate);

        if (currentPerformanceIndex === -1 || !currentPerformance) {
            return null;
        }

        // Find the previous performance (the one that created the gap)
        let historicalLastPlayed = null;
        let historicalVenue = null;
        let historicalCity = null;
        let historicalState = null;

        if (currentPerformanceIndex > 0) {
            const previousPerformance = performances[currentPerformanceIndex - 1];
            historicalLastPlayed = previousPerformance.showdate;
            historicalVenue = previousPerformance.venue;
            historicalCity = previousPerformance.city;
            historicalState = previousPerformance.state;
        }

        // Return gap info with proper historical data (matching iOS structure)
        return {
            songId: currentPerformance.songid,
            songName: currentPerformance.song,
            gap: currentPerformance.gap,
            lastPlayed: historicalLastPlayed || showDate, // Use historical date if available
            timesPlayed: performances.length,
            tourVenue: currentPerformance.venue,
            tourVenueRun: null, // Can be enhanced later with venue run data
            tourDate: showDate,
            historicalVenue: historicalVenue,
            historicalCity: historicalCity,
            historicalState: historicalState,
            historicalLastPlayed: historicalLastPlayed
        };
    }

    /**
     * Filter to Phish shows only
     * 
     * Excludes side projects, guest appearances, and other non-Phish performances.
     * Validates that show has proper date format and artist name.
     * 
     * @param {Array} shows - Array of show objects from API
     * @returns {Array} Filtered array containing only Phish shows
     * 
     * Port of iOS APIUtilities.filterPhishShows() logic
     */
    filterPhishShows(shows) {
        return shows.filter(show => 
            show.artist_name && 
            show.artist_name.toLowerCase().includes('phish') &&
            show.showdate && 
            show.showdate.length >= 10 // Valid date format
        );
    }
}