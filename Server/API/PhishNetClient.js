/**
 * PhishNetClient.js
 * JavaScript port of iOS PhishNetAPIClient.swift
 * Maintains exact same API calls and response handling
 */

import fetch from 'node-fetch';

export class PhishNetClient {
    constructor(apiKey) {
        this.baseURL = 'https://api.phish.net/v5';
        this.apiKey = apiKey;
    }

    /**
     * Fetch the latest show (most recent chronologically)
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
     * Fetch all songs with gap information for tour statistics
     * Port of iOS PhishNetAPIClient.fetchAllSongsWithGaps() lines 137-180
     */
    async fetchAllSongsWithGaps() {
        const url = `${this.baseURL}/songs.json?apikey=${this.apiKey}`;
        
        const response = await fetch(url);
        
        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        const songsResponse = await response.json();
        
        // Convert API response to SongGapInfo objects (same as iOS lines 163-171)
        return (songsResponse.data || []).map(songData => ({
            songId: songData.songid,
            songName: songData.song,
            gap: songData.gap,
            lastPlayed: songData.last_played,
            timesPlayed: songData.times_played,
            tourVenue: null,
            tourVenueRun: null,
            tourDate: null,
            historicalVenue: null,
            historicalCity: null,
            historicalState: null,
            historicalLastPlayed: null
        }));
    }

    /**
     * Fetch song gaps for specific songs and show date
     * Creates gap info filtered to tour context
     */
    async fetchSongGaps(songNames, showDate) {
        // Get all song gap data
        const allGaps = await this.fetchAllSongsWithGaps();
        
        // Filter to songs that appear in the current setlist
        const songNameSet = new Set(songNames.map(name => name.toLowerCase()));
        
        return allGaps.filter(gapInfo => 
            songNameSet.has(gapInfo.songName.toLowerCase())
        );
    }

    /**
     * Filter to Phish shows only
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