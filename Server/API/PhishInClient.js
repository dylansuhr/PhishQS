/**
 * PhishInClient.js
 *
 * Phish.in API client for audio-related data ONLY:
 * - Song durations (primary use)
 * - Recordings metadata (future implementation)
 *
 * IMPORTANT: All other data (setlists, gaps, venue runs, tour positions)
 * must come from Phish.net API, not Phish.in.
 */

import fetch from 'node-fetch';

export class PhishInClient {
    constructor() {
        this.baseURL = 'https://phish.in/api/v2';
        // No API key required for v2 API
    }

    /**
     * Make API request helper
     * Port of iOS PhishInAPIClient.makeRequest() lines 38-79
     */
    async makeRequest(endpoint, queryParameters = {}) {
        const url = new URL(`${this.baseURL}/${endpoint}`);
        
        // Add query parameters
        Object.entries(queryParameters).forEach(([key, value]) => {
            url.searchParams.append(key, value);
        });

        const response = await fetch(url);
        
        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        return await response.json();
    }

    /**
     * Fetch show data by date (PRIVATE - internal use only)
     * Used internally by fetchTrackDurations() to get track data
     * @private
     */
    async _fetchShowByDate(showDate) {
        return await this.makeRequest(`shows/${showDate}`);
    }

    /**
     * Fetch track durations for a specific show date
     * Port of iOS PhishInAPIClient.fetchTrackDurations() lines 84-110
     */
    async fetchTrackDurations(showDate) {
        try {
            // First get the show data for the date
            const show = await this._fetchShowByDate(showDate);
            
            if (!show.tracks) {
                return [];
            }

            // Get venue information from the show (for display only)
            const venueName = show.venue?.name;

            // NOTE: Venue runs should come from Phish.net, not Phish.in
            // Removed venueRun fetching as per architecture requirements

            // Convert tracks to TrackDuration objects (same as iOS lines 103-109)
            return show.tracks.filter(track => track.duration && track.title).map(track => ({
                id: String(track.id),
                songName: track.title,
                songId: track.songs?.[0]?.id || null,
                durationSeconds: Math.round(track.duration / 1000),
                showDate: showDate,
                setNumber: String(track.set_name || '1'),
                venue: venueName,
                venueRun: null // Venue runs come from Phish.net, not Phish.in
            }));

        } catch (error) {
            console.log(`Warning: Could not fetch track durations for ${showDate}: ${error.message}`);
            return [];
        }
    }

    // REMOVED: fetchVenueRuns() - Venue runs must come from Phish.net, not Phish.in
    // Use PhishNetTourService.calculateVenueRuns() instead

    // REMOVED: fetchTourPosition() - Tour positions must come from Phish.net, not Phish.in
    // Use PhishNetTourService.calculateTourPosition() instead

    /**
     * Fetch recordings for a specific show date
     *
     * FUTURE IMPLEMENTATION: This method is preserved for future audio features.
     * Currently not actively used in the app but will be implemented when audio
     * playback functionality is added. Recordings data includes audio URLs and metadata.
     *
     * @param {string} showDate - Show date in YYYY-MM-DD format
     * @returns {Promise<Array>} Array of recording objects (for future use)
     */
    async fetchRecordings(showDate) {
        // TODO: Implement audio playback features in future version
        try {
            const show = await this._fetchShowByDate(showDate);
            
            // Convert PhishIn show to Recording model (same as iOS lines 117-125)
            const recording = {
                id: String(show.id),
                showDate: showDate,
                venue: show.venue?.name || 'Unknown Venue',
                recordingType: show.sbd === true ? 'soundboard' : 'audience',
                url: show.tracks?.[0]?.mp3 || null,
                isAvailable: !(show.missing || false)
            };
            
            return [recording];

        } catch (error) {
            return [];
        }
    }

    // REMOVED: Tour-related helper methods (getCachedTourShows, fetchShowsForTourName, etc.)
    // These are no longer needed as tour data comes from Phish.net, not Phish.in
}