/**
 * update-tour-dashboard.js
 * 
 * Generates the tour dashboard control file that serves as the single source of truth
 * for both Component A (Latest Setlist) and Component B (Tour Statistics).
 * 
 * This control file determines:
 * - What tour we're currently in
 * - What the latest show is
 * - Which shows have been played
 * - What future tours are scheduled
 * 
 * Components read this file to know what data to generate/display.
 */

import { PhishNetClient } from '../API/PhishNetClient.js';
import StatisticsConfig from '../Config/StatisticsConfig.js';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

// Setup directory paths
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration - using same pattern as generate-stats.js
const apiConfig = StatisticsConfig.getApiConfig('phishNet');
const CONFIG = {
    PHISH_NET_API_KEY: apiConfig.defaultApiKey, // TODO: Move to environment variables
    OUTPUT_PATH: join(__dirname, '..', '..', 'api', 'Data', 'tour-dashboard-data.json')
};

/**
 * Main function to update the tour dashboard control file
 */
async function updateTourDashboard() {
    try {
        console.log('🎯 Starting tour dashboard update...');
        
        // Initialize API client
        const apiClient = new PhishNetClient(CONFIG.PHISH_NET_API_KEY);
        
        // Fetch current year shows
        const currentYear = new Date().getFullYear().toString();
        console.log(`📡 Fetching ${currentYear} shows from Phish.net...`);
        const currentYearShows = await apiClient.fetchShows(currentYear);
        
        // Filter to Phish shows only
        const phishShows = filterPhishShows(currentYearShows);
        console.log(`📊 Found ${phishShows.length} Phish shows in ${currentYear}`);
        
        // Determine current tour and latest show
        let { currentTourName, latestShow } = determineCurrentTour(phishShows);
        
        // If no current tour found in current year, search historical years
        if (!currentTourName) {
            console.log('🔍 No current year tour found, searching history...');
            const historicalResult = await findLatestTourFromHistory(currentYear - 1);
            currentTourName = historicalResult.currentTourName;
            latestShow = historicalResult.latestShow;
        }
        
        if (!currentTourName) {
            console.log('⚠️ No tour found in current year or 3-year history');
            return;
        }
        
        console.log(`🎪 Current tour: ${currentTourName}`);
        console.log(`🎵 Latest show: ${latestShow ? latestShow.date : 'None yet'}`);
        
        // Build current tour object (may need historical data)
        let currentTour;
        if (phishShows.some(show => show.tourname === currentTourName)) {
            // Current tour exists in current year data
            currentTour = buildCurrentTour(phishShows, currentTourName);
        } else {
            // Need to fetch historical year for complete tour data
            const tourYear = latestShow ? new Date(latestShow.date).getFullYear() : currentYear - 1;
            console.log(`🔍 Fetching ${tourYear} data for complete tour info...`);
            const tourYearShows = await apiClient.fetchShows(tourYear.toString());
            const tourPhishShows = filterPhishShows(tourYearShows);
            currentTour = buildCurrentTour(tourPhishShows, currentTourName);
        }
        
        // Calculate tour position for latest show
        let latestShowWithPosition = null;
        if (latestShow) {
            latestShowWithPosition = {
                ...latestShow,
                tourPosition: calculateTourPosition(currentTour.tourDates, latestShow.date, currentTourName)
            };
        }
        
        // Find future tours
        const futureTours = findFutureTours(phishShows, currentTourName);
        console.log(`🔮 Found ${futureTours.length} future tours`);
        
        // Build the complete data structure
        const tourDashboardData = {
            currentTour,
            latestShow: latestShowWithPosition,
            futureTours
        };
        
        // Check if update is needed
        const existingData = loadExistingData();
        const updateInfo = checkIfUpdateNeeded(existingData, tourDashboardData);
        
        if (updateInfo.shouldUpdate) {
            // Write the file
            writeTourDashboard(tourDashboardData, updateInfo.reason);
            console.log(`✅ Tour dashboard updated: ${updateInfo.reason}`);
        } else {
            console.log('ℹ️ No update needed - data unchanged');
        }
        
    } catch (error) {
        console.error('❌ Error updating tour dashboard:', error);
        process.exit(1);
    }
}

/**
 * Filter shows to Phish only (exclude side projects)
 */
function filterPhishShows(shows) {
    return shows.filter(show => 
        show.artistid === 1 || 
        show.artist_name === 'Phish' ||
        !show.artistid // Some shows may not have artistid
    );
}

/**
 * Find the latest tour by searching backwards through recent years
 */
async function findLatestTourFromHistory(startYear) {
    const apiClient = new PhishNetClient(CONFIG.PHISH_NET_API_KEY);
    const maxYearsBack = 3;
    
    for (let year = startYear; year >= startYear - maxYearsBack; year--) {
        console.log(`🔍 Searching ${year} for completed tours...`);
        
        try {
            const yearShows = await apiClient.fetchShows(year.toString());
            const phishShows = filterPhishShows(yearShows);
            
            // Only look at played shows from this year
            const today = new Date().toISOString().split('T')[0];
            const playedShows = phishShows.filter(show => show.showdate <= today);
            
            if (playedShows.length > 0) {
                // Found played shows! Use latest one
                playedShows.sort((a, b) => b.showdate.localeCompare(a.showdate));
                const latestShow = playedShows[0];
                
                console.log(`✅ Found latest tour: ${latestShow.tourname} (${latestShow.showdate})`);
                return {
                    currentTourName: latestShow.tourname,
                    latestShow: {
                        date: latestShow.showdate,
                        venue: latestShow.venue || 'Unknown Venue',
                        city: latestShow.city || '',
                        state: latestShow.state || ''
                    }
                };
            }
        } catch (error) {
            console.warn(`⚠️ Failed to fetch ${year} shows:`, error.message);
            continue; // Try next year
        }
    }
    
    // Fallback: No historical tours found
    return { currentTourName: null, latestShow: null };
}

/**
 * Determine the current tour based on the latest played show
 */
function determineCurrentTour(shows) {
    const today = new Date().toISOString().split('T')[0];
    
    // Find shows that have been played (date <= today)
    const playedShows = shows.filter(show => show.showdate <= today);
    
    if (playedShows.length === 0) {
        // No shows played yet, find first upcoming tour
        const upcomingShows = shows.filter(show => show.showdate > today);
        if (upcomingShows.length > 0) {
            upcomingShows.sort((a, b) => a.showdate.localeCompare(b.showdate));
            return {
                currentTourName: upcomingShows[0].tourname,
                latestShow: null
            };
        }
        return { currentTourName: null, latestShow: null };
    }
    
    // Sort by date descending to get latest
    playedShows.sort((a, b) => b.showdate.localeCompare(a.showdate));
    const latestShow = playedShows[0];
    
    return {
        currentTourName: latestShow.tourname,
        latestShow: {
            date: latestShow.showdate,
            venue: latestShow.venue || 'Unknown Venue',
            city: latestShow.city || '',
            state: latestShow.state || ''
        }
    };
}

/**
 * Build the current tour object with all tour dates
 */
function buildCurrentTour(shows, tourName) {
    const today = new Date().toISOString().split('T')[0];
    
    // Filter to shows in current tour
    const tourShows = shows.filter(show => show.tourname === tourName);
    
    // Sort by date ascending
    tourShows.sort((a, b) => a.showdate.localeCompare(b.showdate));
    
    // Build tour dates array
    const tourDates = tourShows.map((show, index) => ({
        date: show.showdate,
        venue: show.venue || 'Unknown Venue',
        city: show.city || '',
        state: show.state || '',
        played: show.showdate <= today,
        showNumber: index + 1
    }));
    
    // Count played shows
    const playedShows = tourDates.filter(show => show.played).length;
    
    return {
        name: tourName,
        year: tourShows[0]?.showyear || new Date().getFullYear().toString(),
        totalShows: tourShows.length,
        playedShows: playedShows,
        startDate: tourShows[0]?.showdate || '',
        endDate: tourShows[tourShows.length - 1]?.showdate || '',
        tourDates: tourDates
    };
}

/**
 * Calculate tour position for the latest show
 */
function calculateTourPosition(tourDates, latestShowDate, tourName) {
    const showIndex = tourDates.findIndex(show => show.date === latestShowDate);
    
    if (showIndex === -1) {
        return null;
    }
    
    return {
        showNumber: showIndex + 1,
        totalShows: tourDates.length,
        tourName: tourName
    };
}

/**
 * Find future tours that haven't started yet
 */
function findFutureTours(shows, currentTourName) {
    const today = new Date().toISOString().split('T')[0];
    
    // Group shows by tour
    const tourGroups = {};
    shows.forEach(show => {
        if (show.tourname && show.tourname !== currentTourName) {
            if (!tourGroups[show.tourname]) {
                tourGroups[show.tourname] = [];
            }
            tourGroups[show.tourname].push(show);
        }
    });
    
    // Find tours where all shows are in the future
    const futureTours = [];
    for (const [tourName, tourShows] of Object.entries(tourGroups)) {
        const allFuture = tourShows.every(show => show.showdate > today);
        if (allFuture && tourShows.length > 0) {
            tourShows.sort((a, b) => a.showdate.localeCompare(b.showdate));
            futureTours.push({
                name: tourName,
                year: tourShows[0].showyear || new Date().getFullYear().toString(),
                startDate: tourShows[0].showdate,
                endDate: tourShows[tourShows.length - 1].showdate,
                shows: tourShows.length
            });
        }
    }
    
    // Sort future tours by start date
    futureTours.sort((a, b) => a.startDate.localeCompare(b.startDate));
    
    return futureTours;
}

/**
 * Load existing data if it exists
 */
function loadExistingData() {
    if (existsSync(CONFIG.OUTPUT_PATH)) {
        try {
            const data = readFileSync(CONFIG.OUTPUT_PATH, 'utf8');
            return JSON.parse(data);
        } catch (error) {
            console.error('⚠️ Error reading existing data:', error.message);
            return null;
        }
    }
    return null;
}

/**
 * Check if an update is needed
 */
function checkIfUpdateNeeded(existingData, newData) {
    // Always update if no existing file
    if (!existingData) {
        return { shouldUpdate: true, reason: 'initial_creation' };
    }
    
    // Update if latest show changed
    if (existingData.latestShow?.date !== newData.latestShow?.date) {
        return { shouldUpdate: true, reason: 'new_show' };
    }
    
    // Update if tour changed
    if (existingData.currentTour?.name !== newData.currentTour?.name) {
        return { shouldUpdate: true, reason: 'tour_change' };
    }
    
    // Update if number of played shows changed
    if (existingData.currentTour?.playedShows !== newData.currentTour?.playedShows) {
        return { shouldUpdate: true, reason: 'show_played' };
    }
    
    // Update if future tours changed
    const existingFutureTours = JSON.stringify(existingData.futureTours || []);
    const newFutureTours = JSON.stringify(newData.futureTours || []);
    if (existingFutureTours !== newFutureTours) {
        return { shouldUpdate: true, reason: 'future_tours_changed' };
    }
    
    return { shouldUpdate: false, reason: null };
}

/**
 * Write the tour dashboard data to file
 */
function writeTourDashboard(data, updateReason) {
    const output = {
        ...data,
        metadata: {
            lastUpdated: new Date().toISOString(),
            dataVersion: '1.0',
            updateReason: updateReason,
            nextShow: findNextShow(data.currentTour?.tourDates)
        }
    };
    
    // Ensure directory exists
    const dir = dirname(CONFIG.OUTPUT_PATH);
    if (!existsSync(dir)) {
        console.log(`📁 Creating directory: ${dir}`);
        mkdirSync(dir, { recursive: true });
    }
    
    // Write the file
    writeFileSync(CONFIG.OUTPUT_PATH, JSON.stringify(output, null, 2));
    console.log(`💾 Tour dashboard written to: ${CONFIG.OUTPUT_PATH}`);
}

/**
 * Find the next unplayed show
 */
function findNextShow(tourDates) {
    if (!tourDates) return null;
    
    const unplayedShows = tourDates.filter(show => !show.played);
    if (unplayedShows.length === 0) return null;
    
    // Return the first unplayed show (already sorted by date)
    const nextShow = unplayedShows[0];
    return {
        date: nextShow.date,
        venue: nextShow.venue,
        city: nextShow.city,
        state: nextShow.state
    };
}

// Add missing import for mkdirSync
import { mkdirSync } from 'fs';

// Run the update if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    updateTourDashboard();
}

export { updateTourDashboard };