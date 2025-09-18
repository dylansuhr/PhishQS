/**
 * PhishNetTourService.js
 * 
 * Service for fetching tour-related data from Phish.net API
 * Replaces Phish.in as the authoritative source for tour organization, show counts, and venue runs
 * 
 * Created by Claude on 9/4/25
 */

import { PhishNetClient } from '../API/PhishNetClient.js';
import { TourScheduleService } from './TourScheduleService.js';
import LoggingService from './LoggingService.js';

export class PhishNetTourService {
    
    constructor(apiKey) {
        this.phishNetClient = new PhishNetClient(apiKey);
        this.tourScheduleService = new TourScheduleService();
    }
    
    // MARK: - Tour Show Methods
    
    /**
     * Fetch all shows for a specific tour by year and tour name
     * Replaces Phish.in getCachedTourShows functionality
     * 
     * @param {string} year - Year to fetch shows for (e.g., '2025')
     * @param {string} tourName - Tour name to filter by (e.g., '2025 Summer Tour')
     * @returns {Promise<Array>} Array of show objects for the tour
     */
    async fetchTourShows(year, tourName) {
        try {
            const allYearShows = await this.phishNetClient.fetchShows(year);
            
            // Filter shows by tour name (exact match) - use 'tourname' field from Phish.net
            const tourShows = allYearShows.filter(show => show.tourname === tourName);
            
            LoggingService.info(`Found ${tourShows.length} shows for ${tourName}`);
            
            // Sort by date to ensure proper order (though API should already be ordered)
            return tourShows.sort((a, b) => a.showdate.localeCompare(b.showdate));
        } catch (error) {
            console.error(`Error fetching tour shows for ${tourName} in ${year}:`, error);
            return [];
        }
    }
    
    /**
     * Get all shows for a year (used for tour detection)
     * 
     * @param {string} year - Year to fetch shows for
     * @returns {Promise<Array>} Array of all shows for the year
     */
    async fetchAllShowsForYear(year) {
        return await this.phishNetClient.fetchShows(year);
    }
    
    // MARK: - Tour Position Calculation
    
    /**
     * Calculate tour position for a specific show
     * Replaces Phish.in fetchTourPosition functionality
     * 
     * @param {string} showDate - Show date in YYYY-MM-DD format
     * @param {string} tourName - Tour name
     * @returns {Promise<Object|null>} TourShowPosition object or null
     */
    async calculateTourPosition(showDate, tourName) {
        try {
            // First check if we have schedule data for accurate total show counts
            if (this.tourScheduleService.isTourSupported(tourName)) {
                return this.tourScheduleService.calculateTourPosition(showDate, tourName);
            }
            
            // Fallback to setlist-based calculation for unsupported tours
            const year = showDate.substring(0, 4);
            
            // Get all played shows for the tour (from setlist API)
            const tourShows = await this.fetchTourShows(year, tourName);
            
            // Find the show in the tour
            const currentShowIndex = tourShows.findIndex(show => show.showdate === showDate);
            if (currentShowIndex === -1) {
                return null;
            }
            
            // Return position (1-indexed) - note: totalShows will only reflect played shows
            return {
                tourName: tourName,
                showNumber: currentShowIndex + 1,
                totalShows: tourShows.length,
                tourYear: year
            };
        } catch (error) {
            console.error(`Error calculating tour position for ${showDate}:`, error);
            return null;
        }
    }
    
    // MARK: - Tour Detection
    
    /**
     * Extract tour name from a show (if available)
     * Replaces Phish.in tour_name field usage
     * 
     * @param {Object} show - Show object
     * @returns {string|null} Tour name or null
     */
    extractTourFromShow(show) {
        return show.tourname || null;
    }
    
    /**
     * Get tour name for a specific show date by fetching show data
     * 
     * @param {string} showDate - Show date in YYYY-MM-DD format
     * @returns {Promise<string|null>} Tour name or null
     */
    async getTourNameForShow(showDate) {
        try {
            const year = showDate.substring(0, 4);
            const allYearShows = await this.fetchAllShowsForYear(year);
            
            const show = allYearShows.find(show => show.showdate === showDate);
            if (!show) {
                return null;
            }
            
            return this.extractTourFromShow(show);
        } catch (error) {
            console.error(`Error getting tour name for ${showDate}:`, error);
            return null;
        }
    }
    
    // MARK: - Venue Run Calculation
    
    /**
     * Calculate venue runs for a set of shows
     * Replaces Phish.in venue run detection
     * 
     * @param {Array} shows - Array of show objects
     * @returns {Object} Object mapping show dates to VenueRun objects
     */
    calculateVenueRuns(shows) {
        const venueRuns = {};
        
        // Group shows by venue (venue + city + state as key)
        const venueGroups = {};
        
        shows.forEach(show => {
            const venueKey = `${show.venue || 'Unknown'}-${show.city || 'Unknown'}-${show.state || 'Unknown'}`;
            if (!venueGroups[venueKey]) {
                venueGroups[venueKey] = [];
            }
            venueGroups[venueKey].push(show);
        });
        
        // Process each venue group
        Object.values(venueGroups).forEach(venueShows => {
            const sortedShows = venueShows.sort((a, b) => a.showdate.localeCompare(b.showdate));
            
            // Only create venue runs for multi-night stands
            if (sortedShows.length > 1) {
                const showDates = sortedShows.map(show => show.showdate);
                const firstShow = sortedShows[0];
                
                sortedShows.forEach((show, index) => {
                    const venueRun = {
                        venue: firstShow.venue || 'Unknown Venue',
                        city: firstShow.city || 'Unknown City',
                        state: firstShow.state || null,
                        nightNumber: index + 1,
                        totalNights: sortedShows.length,
                        showDates: showDates
                    };
                    
                    venueRuns[show.showdate] = venueRun;
                });
            }
        });
        
        return venueRuns;
    }
    
    /**
     * Get venue run for a specific show date within a tour
     * 
     * @param {string} showDate - Show date in YYYY-MM-DD format
     * @param {Array} tourShows - Array of tour show objects
     * @returns {Object|null} VenueRun object or null
     */
    getVenueRun(showDate, tourShows) {
        const venueRuns = this.calculateVenueRuns(tourShows);
        return venueRuns[showDate] || null;
    }
    
    // MARK: - Convenience Methods
    
    /**
     * Get complete tour context for a show (position + venue run)
     * 
     * @param {string} showDate - Show date in YYYY-MM-DD format
     * @returns {Promise<Object>} Object with tourPosition and venueRun properties
     */
    async getTourContext(showDate) {
        try {
            const tourName = await this.getTourNameForShow(showDate);
            if (!tourName) {
                return { tourPosition: null, venueRun: null };
            }
            
            const year = showDate.substring(0, 4);
            const tourShows = await this.fetchTourShows(year, tourName);
            
            const tourPosition = await this.calculateTourPosition(showDate, tourName);
            const venueRun = this.getVenueRun(showDate, tourShows);
            
            return { tourPosition, venueRun };
        } catch (error) {
            console.error(`Error getting tour context for ${showDate}:`, error);
            return { tourPosition: null, venueRun: null };
        }
    }
    
    // MARK: - Tour Name Normalization
    
    /**
     * Normalize tour names between different API sources
     * Maps Phish.in format to Phish.net format
     * 
     * @param {string} tourName - Tour name to normalize
     * @returns {string} Normalized tour name
     */
    static normalizeTourName(tourName) {
        // Handle common tour name variations
        if (tourName === 'Summer Tour 2025') {
            return '2025 Summer Tour';
        }
        
        // Add more mappings as needed
        return tourName;
    }
    
    /**
     * Get current tour from latest show
     * Used by statistics generation to determine active tour
     * 
     * @returns {Promise<string|null>} Current tour name or null
     */
    async getCurrentTour() {
        try {
            const latestShow = await this.phishNetClient.fetchLatestShow();
            if (!latestShow) {
                return null;
            }
            
            return this.extractTourFromShow(latestShow);
        } catch (error) {
            console.error('Error getting current tour:', error);
            return null;
        }
    }
}