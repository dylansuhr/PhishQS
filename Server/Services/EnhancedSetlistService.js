/**
 * EnhancedSetlistService.js
 * JavaScript port of iOS APIManager.fetchEnhancedSetlist() method
 * Creates enhanced setlist by combining Phish.net and Phish.in API data
 */

import { PhishNetClient } from '../API/PhishNetClient.js';
import { PhishInClient } from '../API/PhishInClient.js';

export class EnhancedSetlistService {
    constructor(phishNetApiKey) {
        this.phishNetClient = new PhishNetClient(phishNetApiKey);
        this.phishInClient = new PhishInClient();
    }

    /**
     * Create enhanced setlist by combining Phish.net and Phish.in data
     * Port of iOS APIManager.fetchEnhancedSetlist() lines 64-148
     */
    async createEnhancedSetlist(showDate) {
        console.log(`🔗 Creating enhanced setlist for ${showDate}...`);

        // Step 1: Get base setlist from Phish.net (same as iOS line 72)
        const setlistItems = await this.phishNetClient.fetchSetlist(showDate);
        console.log(`   📋 Found ${setlistItems.length} setlist items from Phish.net`);

        // Step 2: Initialize enhancement data containers (same as iOS lines 74-79)
        let trackDurations = [];
        let venueRun = null;
        let tourPosition = null;
        let recordings = [];
        let songGaps = [];

        // Step 3: Execute all API calls in parallel for better performance (same as iOS lines 98-129)
        console.log('   🔄 Fetching enhancement data in parallel...');
        
        // Parallel Phish.in API calls (same pattern as iOS lines 99-128)
        const phishInResults = await Promise.allSettled([
            this.phishInClient.fetchTrackDurations(showDate),
            this.phishInClient.fetchVenueRuns(showDate),
            this.phishInClient.fetchTourPosition(showDate), 
            this.phishInClient.fetchRecordings(showDate)
        ]);

        // Extract results with individual error handling (same as iOS lines 105-128)
        if (phishInResults[0].status === 'fulfilled') {
            trackDurations = phishInResults[0].value;
            console.log(`   🎵 Found ${trackDurations.length} track durations from Phish.in`);
        } else {
            console.log(`   ⚠️  Could not fetch track durations: ${phishInResults[0].reason?.message}`);
        }

        if (phishInResults[1].status === 'fulfilled') {
            venueRun = phishInResults[1].value;
            if (venueRun) {
                console.log(`   🏟️  Found venue run: N${venueRun.nightNumber}/${venueRun.totalNights} at ${venueRun.venue}`);
            }
        } else {
            console.log(`   ⚠️  Could not fetch venue run info: ${phishInResults[1].reason?.message}`);
        }

        if (phishInResults[2].status === 'fulfilled') {
            tourPosition = phishInResults[2].value;
            if (tourPosition) {
                console.log(`   🎪 Found tour position: Show ${tourPosition.showNumber}/${tourPosition.totalShows} of ${tourPosition.tourName}`);
            }
        } else {
            console.log(`   ⚠️  Could not fetch tour position: ${phishInResults[2].reason?.message}`);
        }

        if (phishInResults[3].status === 'fulfilled') {
            recordings = phishInResults[3].value;
            console.log(`   🎧 Found ${recordings.length} recordings from Phish.in`);
        } else {
            console.log(`   ⚠️  Could not fetch recordings: ${phishInResults[3].reason?.message}`);
        }

        // Step 4: Get gap data from Phish.net (same as iOS lines 82-96) 
        try {
            // Get unique song names from the setlist (same as iOS line 84)
            const songNames = [...new Set(setlistItems.map(item => item.song))];
            console.log(`   📊 Fetching gap data for ${songNames.length} unique songs...`);
            
            songGaps = await this.phishNetClient.fetchSongGaps(songNames, showDate);
            console.log(`   📊 Found gap data for ${songGaps.length} songs from Phish.net`);
        } catch (error) {
            console.log(`   ⚠️  Could not fetch gap data: ${error.message}`);
            songGaps = [];
        }

        // Step 5: Create enhanced setlist object (same as iOS lines 134-142)
        const enhancedSetlist = {
            showDate: showDate,
            setlistItems: setlistItems,
            trackDurations: trackDurations,
            venueRun: venueRun,
            tourPosition: tourPosition,
            recordings: recordings,
            songGaps: songGaps
        };

        console.log(`   ✅ Enhanced setlist created with ${Object.keys(enhancedSetlist).length} data components`);
        return enhancedSetlist;
    }

    /**
     * Collect tour data by fetching enhanced setlists for all shows in a tour
     * Port of iOS fetchTourEnhancedSetlistsOptimized logic
     */
    async collectTourData(tourName, currentShowDate) {
        console.log(`🎪 Collecting enhanced data for tour: ${tourName}`);
        
        try {
            // Get all shows for the tour (same as iOS fetchTourShows pattern)
            const tourShows = await this.phishInClient.getCachedTourShows(tourName);
            console.log(`   📋 Found ${tourShows.length} shows in ${tourName}`);

            if (tourShows.length === 0) {
                console.log('   ⚠️  No tour shows found, returning current show only');
                // Return just current show if no tour data found
                const currentEnhanced = await this.createEnhancedSetlist(currentShowDate);
                return [currentEnhanced];
            }

            // Create enhanced setlists for each show (optimized like iOS)
            console.log('   🔄 Creating enhanced setlists for all tour shows...');
            const enhancedSetlists = [];
            
            for (let i = 0; i < tourShows.length; i++) {
                const show = tourShows[i];
                try {
                    console.log(`   📅 Processing show ${i + 1}/${tourShows.length}: ${show.date}`);
                    const enhanced = await this.createEnhancedSetlist(show.date);
                    enhancedSetlists.push(enhanced);
                } catch (error) {
                    console.log(`   ⚠️  Skipping show ${show.date}: ${error.message}`);
                    // Continue processing other shows even if one fails
                }
            }

            // Sort chronologically (same as iOS)
            enhancedSetlists.sort((a, b) => a.showDate.localeCompare(b.showDate));
            
            console.log(`   ✅ Successfully created ${enhancedSetlists.length} enhanced setlists for ${tourName}`);
            return enhancedSetlists;

        } catch (error) {
            console.log(`   ❌ Error collecting tour data: ${error.message}`);
            console.log('   📅 Falling back to current show only');
            
            // Fallback to current show only if tour collection fails
            const currentEnhanced = await this.createEnhancedSetlist(currentShowDate);
            return [currentEnhanced];
        }
    }
}