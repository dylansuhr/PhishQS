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
        const url = `${this.baseURL}/setlists/showyear/${year}.json?apikey=${this.apiKey}&artist=phish`;
        
        const response = await fetch(url);
        
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