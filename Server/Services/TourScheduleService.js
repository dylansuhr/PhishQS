/**
 * TourScheduleService.js
 * 
 * Service to provide complete tour schedules including future shows.
 * This solves the limitation where setlist APIs only return played shows.
 * 
 * For accurate tour position calculations (e.g., "23/31"), we need:
 * - Played shows (from setlist APIs) for statistics
 * - Complete tour schedule (from this service) for total counts
 */

import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export class TourScheduleService {
    constructor() {
        // Load tour schedule data
        const schedulePath = join(__dirname, '..', 'Data', 'tour-schedules.json');
        this.tourSchedules = JSON.parse(readFileSync(schedulePath, 'utf8'));
    }

    /**
     * Get the total number of shows scheduled for a tour
     * @param {string} tourName - Tour name (e.g., '2025 Summer Tour')
     * @returns {number} Total shows scheduled (including future shows)
     */
    getTotalShowCount(tourName) {
        const tour = this.tourSchedules[tourName];
        return tour ? tour.totalShows : 0;
    }

    /**
     * Get all scheduled show dates for a tour
     * @param {string} tourName - Tour name (e.g., '2025 Summer Tour')
     * @returns {string[]} Array of show dates in YYYY-MM-DD format
     */
    getScheduledShowDates(tourName) {
        const tour = this.tourSchedules[tourName];
        return tour ? tour.shows : [];
    }

    /**
     * Calculate tour position for a specific show date
     * @param {string} showDate - Show date in YYYY-MM-DD format
     * @param {string} tourName - Tour name (e.g., '2025 Summer Tour')
     * @returns {Object} Tour position info
     */
    calculateTourPosition(showDate, tourName) {
        const scheduledDates = this.getScheduledShowDates(tourName);
        const totalShows = this.getTotalShowCount(tourName);
        
        if (scheduledDates.length === 0) {
            return null;
        }

        // Find position of this show in the complete tour schedule
        const showNumber = scheduledDates.findIndex(date => date === showDate) + 1;
        
        if (showNumber === 0) {
            // Show not found in schedule
            return null;
        }

        return {
            showNumber,
            totalShows,
            tourName,
            tourYear: showDate.split('-')[0]
        };
    }

    /**
     * Check if a tour is supported by this service
     * @param {string} tourName - Tour name to check
     * @returns {boolean} True if tour is supported
     */
    isTourSupported(tourName) {
        return this.tourSchedules.hasOwnProperty(tourName);
    }

    /**
     * Get all supported tour names
     * @returns {string[]} Array of supported tour names
     */
    getSupportedTours() {
        return Object.keys(this.tourSchedules);
    }
}