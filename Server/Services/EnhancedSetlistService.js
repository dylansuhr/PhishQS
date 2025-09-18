/**
 * EnhancedSetlistService.js
 * JavaScript port of iOS APIManager.fetchEnhancedSetlist() method
 * Creates enhanced setlist by combining Phish.net and Phish.in API data
 * 
 * OPTIMIZATION: Now supports both original API-based methods and new
 * data-context-based methods for eliminating redundant API calls
 */

import { PhishNetClient } from '../API/PhishNetClient.js';
import { PhishInClient } from '../API/PhishInClient.js';
import { PhishNetTourService } from './PhishNetTourService.js';
import { DataCollectionService } from './DataCollectionService.js';
import LoggingService from './LoggingService.js';

export class EnhancedSetlistService {
    constructor(phishNetApiKey) {
        this.phishNetClient = new PhishNetClient(phishNetApiKey);
        this.phishInClient = new PhishInClient();
        this.phishNetTourService = new PhishNetTourService(phishNetApiKey);
    }

    /**
     * Create enhanced setlist by combining Phish.net and Phish.in data
     * Port of iOS APIManager.fetchEnhancedSetlist() lines 64-148
     */
    async createEnhancedSetlist(showDate) {
        LoggingService.start(`Creating enhanced setlist for ${showDate}`);

        // Step 1: Get base setlist from Phish.net (same as iOS line 72)
        const setlistItems = await this.phishNetClient.fetchSetlist(showDate);
        LoggingService.info(`Found ${setlistItems.length} setlist items from Phish.net`);
        
        // Step 1.5: Get show data from Phish.net to extract venue/city/state information
        let showVenueInfo = null;
        try {
            const year = showDate.split('-')[0];
            const yearShows = await this.phishNetClient.fetchShows(year);
            const matchingShow = yearShows.find(show => show.showdate === showDate);
            if (matchingShow) {
                showVenueInfo = {
                    venue: matchingShow.venue,
                    city: matchingShow.city,
                    state: matchingShow.state
                };
                LoggingService.info(`Found venue info from Phish.net: ${showVenueInfo.venue}, ${showVenueInfo.city}, ${showVenueInfo.state}`);
            }
        } catch (error) {
            LoggingService.warn(`Could not fetch show venue info: ${error.message}`);
        }

        // Step 2: Initialize enhancement data containers (same as iOS lines 74-79)
        let trackDurations = [];
        let venueRun = null;
        let tourPosition = null;
        let recordings = [];
        let songGaps = [];

        // Step 3: Execute all API calls in parallel for better performance (same as iOS lines 98-129)
        LoggingService.start('Fetching enhancement data in parallel...');
        
        // Parallel API calls - Phish.in for AUDIO DATA ONLY (durations/recordings), Phish.net for tour position
        const phishInResults = await Promise.allSettled([
            this.phishInClient.fetchTrackDurations(showDate),
            this.phishInClient.fetchRecordings(showDate)
        ]);
        
        // Get tour position from Phish.net (migrated from Phish.in for accuracy)
        const tourPositionResult = await Promise.allSettled([
            this.phishNetTourService.getTourContext(showDate)
        ]);

        // Extract results with individual error handling (AUDIO DATA ONLY)
        if (phishInResults[0].status === 'fulfilled') {
            trackDurations = phishInResults[0].value;
            LoggingService.info(`Found ${trackDurations.length} track durations from Phish.in`);
        } else {
            LoggingService.warn(`Could not fetch track durations: ${phishInResults[0].reason?.message}`);
        }

        if (phishInResults[1].status === 'fulfilled') {
            recordings = phishInResults[1].value;
            LoggingService.info(`Found ${recordings.length} recordings from Phish.in`);
        } else {
            LoggingService.warn(`Could not fetch recordings: ${phishInResults[1].reason?.message}`);
        }

        if (tourPositionResult[0].status === 'fulfilled') {
            const tourContext = tourPositionResult[0].value;
            tourPosition = tourContext.tourPosition;
            if (tourPosition) {
                LoggingService.info(`Found tour position: Show ${tourPosition.showNumber}/${tourPosition.totalShows} of ${tourPosition.tourName}`);
            }
            
            // Get venue run from Phish.net (NOT Phish.in) - if tour context is available
            if (tourContext.venueRun) {
                venueRun = tourContext.venueRun;
                LoggingService.info(`Found venue run from Phish.net: N${venueRun.nightNumber}/${venueRun.totalNights} at ${venueRun.venue}`);
            }
        } else {
            LoggingService.warn(`Could not fetch tour position: ${tourPositionResult[0].reason?.message}`);
        }

        // Step 4: Extract gap data from setlist (gap data is already in setlist response)
        LoggingService.info(`Extracting gap data from setlist items...`);
        
        // STEP 4.1: Get complete Phish-only historical data for all songs during generation
        LoggingService.start(`Fetching complete Phish-only historical data for ${setlistItems.length} songs...`);
        songGaps = [];

        for (let i = 0; i < setlistItems.length; i++) {
            const item = setlistItems[i];
            LoggingService.debug(`[${i + 1}/${setlistItems.length}] Getting historical data for "${item.song}"...`);

            try {
                // Use the fixed fetchSongGap method to get complete Phish-only historical data
                const historicalData = await this.phishNetClient.fetchSongGap(item.song, showDate);

                if (historicalData) {
                    songGaps.push(historicalData);
                    LoggingService.success(`Complete data for "${item.song}": gap ${historicalData.gap}, last played ${historicalData.historicalLastPlayed || 'N/A'}`);
                } else {
                    // Fallback to basic data if historical lookup fails
                    songGaps.push({
                        songId: item.songid,
                        songName: item.song,
                        gap: item.gap,
                        lastPlayed: item.lastplayed || null,
                        timesPlayed: null,
                        tourVenue: null,
                        tourVenueRun: null,
                        tourDate: showDate,
                        historicalVenue: null,
                        historicalCity: null,
                        historicalState: null,
                        historicalLastPlayed: null
                    });
                    LoggingService.warn(`No historical data found for "${item.song}"`);
                }
            } catch (error) {
                // Fallback to basic data if API call fails
                songGaps.push({
                    songId: item.songid,
                    songName: item.song,
                    gap: item.gap,
                    lastPlayed: item.lastplayed || null,
                    timesPlayed: null,
                    tourVenue: null,
                    tourVenueRun: null,
                    tourDate: showDate,
                    historicalVenue: null,
                    historicalCity: null,
                    historicalState: null,
                    historicalLastPlayed: null
                });
                LoggingService.error(`Failed to get historical data for "${item.song}": ${error.message}`);
            }

            // Rate limiting delay between API calls
            if (i < setlistItems.length - 1) {
                await new Promise(resolve => setTimeout(resolve, 100)); // 100ms delay
            }
        }
        
        LoggingService.info(`Extracted gap data for ${songGaps.length} songs from setlist`);

        // Step 5: Create enhanced setlist object (same as iOS lines 134-142)
        const enhancedSetlist = {
            showDate: showDate,
            setlistItems: setlistItems,
            trackDurations: trackDurations,
            venueRun: venueRun,
            tourPosition: tourPosition,
            recordings: recordings,
            songGaps: songGaps,
            showVenueInfo: showVenueInfo // Include Phish.net venue info for city/state extraction
        };

        LoggingService.success(`Enhanced setlist created with ${Object.keys(enhancedSetlist).length} data components`);
        return enhancedSetlist;
    }

    /**
     * Collect tour data by fetching enhanced setlists for all shows in a tour
     * Port of iOS fetchTourEnhancedSetlistsOptimized logic
     */
    async collectTourData(tourName, currentShowDate) {
        LoggingService.start(`Collecting enhanced data for tour: ${tourName}`);
        
        try {
            // Get all shows for the tour using Phish.net (migrated from Phish.in)
            const year = currentShowDate.split('-')[0]; // Extract year from show date
            const tourShows = await this.phishNetTourService.fetchTourShows(year, tourName);
            LoggingService.info(`Found ${tourShows.length} shows in ${tourName}`);

            if (tourShows.length === 0) {
                LoggingService.warn('No tour shows found, returning current show only');
                // Return just current show if no tour data found
                const currentEnhanced = await this.createEnhancedSetlist(currentShowDate);
                return [currentEnhanced];
            }

            // Create enhanced setlists for each show (only for played shows with setlist data)
            LoggingService.start('Creating enhanced setlists for played tour shows...');
            const enhancedSetlists = [];
            
            // Filter to only shows that are in the past or present (have actually been played)
            const today = new Date().toISOString().split('T')[0];
            const playedShows = tourShows.filter(show => show.showdate <= today);
            LoggingService.info(`Processing ${playedShows.length}/${tourShows.length} played shows (excluding ${tourShows.length - playedShows.length} future shows)`);
            
            for (let i = 0; i < playedShows.length; i++) {
                const show = playedShows[i];
                try {
                    LoggingService.debug(`Processing show ${i + 1}/${playedShows.length}: ${show.showdate}`);
                    const enhanced = await this.createEnhancedSetlist(show.showdate);
                    enhancedSetlists.push(enhanced);
                } catch (error) {
                    LoggingService.warn(`Skipping show ${show.showdate}: ${error.message}`);
                    // Continue processing other shows even if one fails
                }
            }

            // Sort chronologically (same as iOS)
            enhancedSetlists.sort((a, b) => a.showDate.localeCompare(b.showDate));
            
            LoggingService.success(`Successfully created ${enhancedSetlists.length} enhanced setlists for ${tourName}`);
            return enhancedSetlists;

        } catch (error) {
            LoggingService.error(`Error collecting tour data: ${error.message}`);
            LoggingService.info('Falling back to current show only');
            
            // Fallback to current show only if tour collection fails
            const currentEnhanced = await this.createEnhancedSetlist(currentShowDate);
            return [currentEnhanced];
        }
    }
    
    /**
     * OPTIMIZED: Collect tour data using pre-fetched data context
     * 
     * This method replaces the API-heavy collectTourData method by using
     * pre-collected data from DataCollectionService, eliminating redundant API calls.
     * 
     * @param {Object} dataContext - Pre-collected tour data context
     * @returns {Array} Array of enhanced setlists (same format as original)
     */
    collectTourDataFromContext(dataContext) {
        LoggingService.start(`Creating enhanced setlists from pre-collected data for ${dataContext.tourName}`);
        LoggingService.info(`Processing ${dataContext.playedShowCount}/${dataContext.totalShows} played shows`);
        
        const enhancedSetlists = [];
        
        // Create enhanced setlist for each played show using pre-collected data
        for (const show of dataContext.playedShows) {
            try {
                const enhanced = DataCollectionService.createEnhancedSetlistFromContext(
                    show.showdate, 
                    dataContext
                );
                enhancedSetlists.push(enhanced);
                
                const setlistCount = enhanced.setlistItems.length;
                const durationCount = enhanced.trackDurations.length;
                LoggingService.debug(`${show.showdate}: ${setlistCount} songs, ${durationCount} durations`);
                
            } catch (error) {
                LoggingService.warn(`Error processing ${show.showdate}: ${error.message}`);
                // Continue processing other shows even if one fails
            }
        }
        
        // Sort chronologically (same as iOS)
        enhancedSetlists.sort((a, b) => a.showDate.localeCompare(b.showDate));
        
        LoggingService.success(`Created ${enhancedSetlists.length} enhanced setlists using optimized data context`);
        return enhancedSetlists;
    }
    
    /**
     * OPTIMIZED: Create single enhanced setlist from pre-fetched data context
     * 
     * This method replaces createEnhancedSetlist() by using pre-collected data,
     * eliminating the individual API calls for venue info and tour context.
     * 
     * @param {string} showDate - Date of show to enhance
     * @param {Object} dataContext - Pre-collected tour data context
     * @returns {Object} Enhanced setlist object (same format as original)
     */
    createEnhancedSetlistFromContext(showDate, dataContext) {
        LoggingService.start(`Creating enhanced setlist for ${showDate} from pre-collected data...`);
        
        const enhanced = DataCollectionService.createEnhancedSetlistFromContext(showDate, dataContext);
        
        // Log the same information as the original method for consistency
        LoggingService.info(`Found ${enhanced.setlistItems.length} setlist items from context`);
        if (enhanced.showVenueInfo) {
            LoggingService.info(`Found venue info: ${enhanced.showVenueInfo.venue}, ${enhanced.showVenueInfo.city}, ${enhanced.showVenueInfo.state}`);
        }
        LoggingService.info(`Found ${enhanced.trackDurations.length} track durations from context`);
        if (enhanced.venueRun) {
            LoggingService.info(`Found venue run: N${enhanced.venueRun.nightNumber}/${enhanced.venueRun.totalNights} at ${enhanced.venueRun.venue}`);
        }
        if (enhanced.tourPosition) {
            LoggingService.info(`Found tour position: Show ${enhanced.tourPosition.showNumber}/${enhanced.tourPosition.totalShows} of ${enhanced.tourPosition.tourName}`);
        }
        LoggingService.info(`Found ${enhanced.recordings.length} recordings from context`);
        LoggingService.info(`Extracted gap data for ${enhanced.songGaps.length} songs from setlist`);
        LoggingService.success(`Enhanced setlist created with ${Object.keys(enhanced).length} data components`);
        
        return enhanced;
    }
}