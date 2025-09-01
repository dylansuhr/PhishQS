/**
 * PhishInClient.js  
 * JavaScript port of iOS PhishInAPIClient.swift
 * Maintains exact same API calls and response handling
 */

import fetch from 'node-fetch';

export class PhishInClient {
    constructor() {
        this.baseURL = 'https://phish.in/api/v2';
        // No API key required for v2 API (same as iOS)
        this.tourShowsCache = new Map(); // Simple cache like iOS
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
     * Fetch show data by date
     * Port of iOS PhishInAPIClient.fetchShowByDate() lines 212-218
     */
    async fetchShowByDate(showDate) {
        return await this.makeRequest(`shows/${showDate}`);
    }

    /**
     * Fetch track durations for a specific show date
     * Port of iOS PhishInAPIClient.fetchTrackDurations() lines 84-110
     */
    async fetchTrackDurations(showDate) {
        try {
            // First get the show data for the date (same as iOS line 86)
            const show = await this.fetchShowByDate(showDate);
            
            if (!show.tracks) {
                return [];
            }

            // Get venue information from the show (same as iOS line 93)
            const venueName = show.venue?.name;
            
            // Fetch venue run information for this show (same as iOS lines 96-101)
            let venueRun = null;
            try {
                venueRun = await this.fetchVenueRuns(showDate);
            } catch (error) {
                // Continue without venue run info if fetch fails (same as iOS)
            }

            // Convert tracks to TrackDuration objects (same as iOS lines 103-109)
            return show.tracks.filter(track => track.duration && track.title).map(track => ({
                id: String(track.id),
                songName: track.title,
                songId: track.songs?.[0]?.id || null,
                durationSeconds: track.duration,
                showDate: showDate,
                setNumber: String(track.set_name || '1'),
                venue: venueName,
                venueRun: venueRun
            }));

        } catch (error) {
            console.log(`Warning: Could not fetch track durations for ${showDate}: ${error.message}`);
            return [];
        }
    }

    /**
     * Fetch venue run information for a specific show date
     * Port of iOS PhishInAPIClient.fetchVenueRuns() lines 146-179
     */
    async fetchVenueRuns(showDate) {
        try {
            const phishInShow = await this.fetchShowByDate(showDate);
            
            if (!phishInShow.venue || !phishInShow.tour_name) {
                return null;
            }

            const venue = phishInShow.venue;
            const tourName = phishInShow.tour_name;
            
            // Get tour shows with caching (same as iOS line 157)
            const allTourShows = await this.getCachedTourShows(tourName);
            
            // Filter tour shows to this venue only (same as iOS lines 160-162)
            const venueShows = allTourShows
                .filter(show => show.venue?.slug === venue.slug || show.venue?.name === venue.name)
                .sort((a, b) => a.date.localeCompare(b.date));
            
            // Only create venue run if there are multiple nights (same as iOS lines 165-168)
            if (venueShows.length <= 1) {
                return null;
            }

            const currentShowIndex = venueShows.findIndex(show => show.date === showDate);
            if (currentShowIndex === -1) {
                return null;
            }

            // Create VenueRun object (same as iOS lines 171-178)
            return {
                venue: venue.name,
                city: venue.location?.split(', ')[0] || '',
                state: venue.location?.split(', ')[1] || null,
                nightNumber: currentShowIndex + 1,
                totalNights: venueShows.length,
                showDates: venueShows.map(show => show.date)
            };

        } catch (error) {
            return null;
        }
    }

    /**
     * Fetch tour position information for a specific show date
     * Port of iOS PhishInAPIClient.fetchTourPosition() lines 182-205
     */
    async fetchTourPosition(showDate) {
        try {
            const phishInShow = await this.fetchShowByDate(showDate);
            
            if (!phishInShow.tour_name) {
                return null;
            }

            const tourName = phishInShow.tour_name;
            
            // Get tour shows with caching (same as iOS line 190)
            const tourShows = await this.getCachedTourShows(tourName);
            
            const currentShowIndex = tourShows.findIndex(show => show.date === showDate);
            if (currentShowIndex === -1) {
                return null;
            }

            // Extract year from date (same as iOS line 197)
            const tourYear = showDate.substring(0, 4);
            
            // Create TourShowPosition object (same as iOS lines 199-204)
            return {
                tourName: tourName,
                showNumber: currentShowIndex + 1,
                totalShows: tourShows.length,
                tourYear: tourYear
            };

        } catch (error) {
            return null;
        }
    }

    /**
     * Fetch recordings for a specific show date
     * Port of iOS PhishInAPIClient.fetchRecordings() lines 113-127
     */
    async fetchRecordings(showDate) {
        try {
            const show = await this.fetchShowByDate(showDate);
            
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

    /**
     * Get tour shows with caching to avoid duplicate API calls
     * Port of iOS PhishInAPIClient.getCachedTourShows() lines 246-281
     */
    async getCachedTourShows(tourName) {
        // Check cache first (same as iOS)
        if (this.tourShowsCache.has(tourName)) {
            return this.tourShowsCache.get(tourName);
        }

        // Try exact match first (same as iOS line 257)
        let shows = await this.fetchShowsForTourName(tourName);
        
        if (shows.length === 0) {
            // Try fuzzy matching if exact fails (same as iOS line 270)
            shows = await this.tryFuzzyTourMatching(tourName);
        }

        // Cache the result (same as iOS lines 273-278)
        this.tourShowsCache.set(tourName, shows);
        
        return shows;
    }

    /**
     * Try to fetch shows for a specific tour name
     * Port of iOS PhishInAPIClient.fetchShowsForTourName() lines 284-297
     */
    async fetchShowsForTourName(tourName) {
        try {
            const response = await this.makeRequest('shows', {
                'tour_name': tourName,
                'per_page': '500'
            });
            
            return (response.shows || [])
                .filter(show => show.tour_name === tourName)
                .sort((a, b) => a.date.localeCompare(b.date));

        } catch (error) {
            return [];
        }
    }

    /**
     * Try different tour name variations if exact match fails
     * Port of iOS PhishInAPIClient.tryFuzzyTourMatching() lines 300-311
     */
    async tryFuzzyTourMatching(originalTourName) {
        const variations = this.generateTourNameVariations(originalTourName);
        
        for (const variation of variations) {
            const shows = await this.fetchShowsForTourName(variation);
            if (shows.length > 0) {
                return shows;
            }
        }
        
        return [];
    }

    /**
     * Generate different variations of tour names to try
     * Port of iOS PhishInAPIClient.generateTourNameVariations() lines 314-340
     */
    generateTourNameVariations(originalTourName) {
        const variations = [];
        
        // Common patterns for tour names (same as iOS logic)
        if (originalTourName.includes('Summer Tour')) {
            const year = originalTourName.replace('Summer Tour ', '');
            variations.push(`Summer ${year}`);
            variations.push(`${year} Summer Tour`);
            variations.push(`Summer '${year.slice(-2)}`);
        } else if (originalTourName.includes('Winter Tour')) {
            const year = originalTourName.replace('Winter Tour ', '');
            variations.push(`Winter ${year}`);
            variations.push(`${year} Winter Tour`);
            variations.push(`Winter '${year.slice(-2)}`);
        }
        
        return variations;
    }
}