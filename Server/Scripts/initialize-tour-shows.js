/**
 * initialize-tour-shows.js
 *
 * Script to initialize all individual show files for the current tour.
 * Creates complete setlist and duration data files for each show in the tour.
 *
 * Architecture Features:
 * - Reads control file to determine which shows need initialization
 * - Creates individual show files in Server/Data/tours/ directory
 * - Uses existing enhanced setlist services for data collection
 * - Updates control file with show file references and smart flags
 * - Handles partial data scenarios (setlist available, durations pending)
 *
 * This script should be run once to initialize the hybrid file system,
 * then individual show files can be updated as needed.
 */

// Load environment variables from .env file (development only)
import dotenv from 'dotenv';
dotenv.config();

import { writeFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { EnhancedSetlistService } from '../Services/EnhancedSetlistService.js';
import { HistoricalDataEnhancer } from '../Services/HistoricalDataEnhancer.js';
import { PhishNetTourService } from '../Services/PhishNetTourService.js';
import { DataCollectionService } from '../Services/DataCollectionService.js';
import { LoggingService } from '../Services/LoggingService.js';
import StatisticsConfig from '../Config/StatisticsConfig.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration
const apiConfig = StatisticsConfig.getApiConfig('phishNet');
const CONFIG = {
    PHISH_NET_API_KEY: apiConfig.defaultApiKey,
    PHISH_NET_BASE_URL: apiConfig.baseUrl,
    PHISH_IN_BASE_URL: StatisticsConfig.getApiConfig('phishIn').baseUrl
};

/**
 * Check if a show file needs updating by comparing existing content with new data
 *
 * This optimization prevents unnecessary file rewrites when show data hasn't changed.
 *
 * @param {string} filePath - Path to the show file
 * @param {Object} newShowData - New show data to compare
 * @returns {{shouldUpdate: boolean, reason: string}}
 */
function checkShowFileNeedsUpdate(filePath, newShowData) {
    // Always update if file doesn't exist
    if (!existsSync(filePath)) {
        return { shouldUpdate: true, reason: 'Show file created (new)' };
    }

    try {
        // Load existing show file
        const existingData = JSON.parse(readFileSync(filePath, 'utf8'));

        // Compare key data completeness indicators
        const existingComplete = existingData.metadata?.dataComplete || false;
        const newComplete = newShowData.metadata?.dataComplete || false;

        // If new data is more complete, update
        if (!existingComplete && newComplete) {
            return { shouldUpdate: true, reason: 'Show file updated (data now complete)' };
        }

        // Compare data availability flags
        const existingDurations = existingData.metadata?.hasDurationData || false;
        const newDurations = newShowData.metadata?.hasDurationData || false;

        if (!existingDurations && newDurations) {
            return { shouldUpdate: true, reason: 'Show file updated (durations now available)' };
        }

        // Compare setlist item count (basic change detection)
        const existingSetlistCount = existingData.setlistItems?.length || 0;
        const newSetlistCount = newShowData.setlistItems?.length || 0;

        if (existingSetlistCount !== newSetlistCount) {
            return { shouldUpdate: true, reason: `Show file updated (setlist changed: ${existingSetlistCount} → ${newSetlistCount} songs)` };
        }

        // Compare track durations count
        const existingDurationCount = existingData.trackDurations?.length || 0;
        const newDurationCount = newShowData.trackDurations?.length || 0;

        if (existingDurationCount !== newDurationCount) {
            return { shouldUpdate: true, reason: `Show file updated (durations changed: ${existingDurationCount} → ${newDurationCount} tracks)` };
        }

        // If we reach here, no significant changes detected
        return { shouldUpdate: false, reason: 'Show file skipped (no changes detected)' };

    } catch (error) {
        // If we can't read existing file, recreate it
        LoggingService.warn(`Error reading existing show file ${filePath}: ${error.message}`);
        return { shouldUpdate: true, reason: 'Show file recreated (error reading existing)' };
    }
}

/**
 * Initialize all tour show files from the control file
 */
async function initializeTourShows() {
    try {
        LoggingService.start('Starting tour show files initialization...');
        console.time('🚀 Total Initialization Time');
        
        // Step 1: Read control file
        const controlFilePath = join(__dirname, '..', 'Data', 'tour-dashboard-data.json');
        
        if (!existsSync(controlFilePath)) {
            throw new Error(`Control file not found: ${controlFilePath}. Please run 'npm run update-tour-dashboard' first.`);
        }
        
        LoggingService.info('Reading tour control file...');
        const controlFileData = JSON.parse(readFileSync(controlFilePath, 'utf8'));
        const tourName = controlFileData.currentTour.name;
        
        LoggingService.info(`Initializing show files for: ${tourName}`);
        LoggingService.info(`Shows to process: ${controlFileData.currentTour.playedShows} played shows`);
        
        // Step 2: Create tour-specific shows directory
        const tourSlug = tourName.toLowerCase().replace(/\s+/g, '-'); // "2025-early-summer-tour"
        const tourShowsDir = join(__dirname, '..', 'Data', 'tours', tourSlug);
        if (!existsSync(tourShowsDir)) {
            mkdirSync(tourShowsDir, { recursive: true });
            LoggingService.info(`Created tour shows directory: ${tourShowsDir}`);
        }
        
        // Step 3: Use optimized data collection for all tour shows
        LoggingService.info('Collecting enhanced data for entire tour (optimized API approach)...');
        const dataCollectionService = new DataCollectionService(CONFIG.PHISH_NET_API_KEY);
        const dataContext = await dataCollectionService.collectAllTourData('2025', tourName);
        
        LoggingService.info(`Performance: Made ${dataContext.apiCalls.total} API calls for complete tour data`);
        
        // Step 4: Create enhanced setlist service for processing
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        
        // Step 5: Process each played show from the control file
        const updatedTourDates = [];
        const individualShowsTracking = {};
        let showsCreated = 0;
        let showsUpdated = 0;
        let showsSkipped = 0;
        let showsWithPartialData = 0;
        
        for (const tourDate of controlFileData.currentTour.tourDates) {
            if (tourDate.played) {
                LoggingService.start(`Processing show: ${tourDate.date} at ${tourDate.venue}`);
                
                try {
                    // Create enhanced setlist using pre-collected data context
                    const enhancedSetlist = enhancedService.createEnhancedSetlistFromContext(
                        tourDate.date,
                        dataContext
                    );
                    
                    if (!enhancedSetlist) {
                        LoggingService.warn(`Could not create enhanced setlist for ${tourDate.date}`);
                        showsSkipped++;
                        updatedTourDates.push(tourDate); // Keep original without showFile
                        continue;
                    }
                    
                    // Determine data completeness
                    const hasSetlistData = enhancedSetlist.setlistItems && enhancedSetlist.setlistItems.length > 0;
                    const hasDurationData = enhancedSetlist.trackDurations && enhancedSetlist.trackDurations.length > 0;
                    const hasGapData = enhancedSetlist.songGaps && enhancedSetlist.songGaps.length > 0;
                    
                    const dataComplete = hasSetlistData && hasDurationData && hasGapData;
                    const durationsAvailable = hasDurationData;
                    
                    if (!hasSetlistData) {
                        LoggingService.warn(`No setlist data for ${tourDate.date} - skipping`);
                        showsSkipped++;
                        updatedTourDates.push(tourDate); // Keep original without showFile
                        continue;
                    }
                    
                    // Create show file
                    const showFileName = `show-${tourDate.date}.json`;
                    const showFilePath = join(tourShowsDir, showFileName);

                    const showFileData = {
                        showDate: enhancedSetlist.showDate,
                        venue: tourDate.venue,
                        city: tourDate.city,
                        state: tourDate.state,
                        tourPosition: enhancedSetlist.tourPosition,
                        venueRun: enhancedSetlist.venueRun,
                        setlistItems: enhancedSetlist.setlistItems,
                        trackDurations: enhancedSetlist.trackDurations,
                        songGaps: enhancedSetlist.songGaps,
                        recordings: enhancedSetlist.recordings || [],
                        metadata: {
                            setlistSource: 'phishnet',
                            durationsSource: hasDurationData ? 'phishin' : null,
                            lastUpdated: new Date().toISOString(),
                            dataComplete: dataComplete,
                            hasSetlistData: hasSetlistData,
                            hasDurationData: hasDurationData,
                            hasGapData: hasGapData
                        }
                    };

                    // OPTIMIZATION: Check if show file needs updating
                    const updateCheck = checkShowFileNeedsUpdate(showFilePath, showFileData);
                    if (updateCheck.shouldUpdate) {
                        // Write show file only if it needs updating
                        writeFileSync(showFilePath, JSON.stringify(showFileData, null, 2));
                        LoggingService.info(`   ${updateCheck.reason}`);

                        if (updateCheck.reason.includes('created (new)')) {
                            showsCreated++;
                        } else {
                            showsUpdated++;
                        }
                    } else {
                        LoggingService.info(`   ${updateCheck.reason}`);
                        // File exists and no update needed - count as processed but not created/updated
                    }

                    // Update tour date with show file reference
                    const updatedTourDate = {
                        ...tourDate,
                        showFile: `tours/${tourSlug}/${showFileName}`
                    };
                    updatedTourDates.push(updatedTourDate);

                    // Track individual show status for smart updates
                    individualShowsTracking[tourDate.date] = {
                        exists: true,
                        lastUpdated: updateCheck.shouldUpdate ? new Date().toISOString() : (existsSync(showFilePath) ? readFileSync(showFilePath, 'utf8').match(/"lastUpdated":\s*"([^"]+)"/)?.[1] || new Date().toISOString() : new Date().toISOString()),
                        durationsAvailable: durationsAvailable,
                        dataComplete: dataComplete,
                        needsUpdate: !dataComplete // Need update if data is incomplete
                    };

                    if (!dataComplete) {
                        showsWithPartialData++;
                        LoggingService.info(`   Show file has partial data (setlist: ${hasSetlistData}, durations: ${hasDurationData}, gaps: ${hasGapData})`);
                    } else {
                        LoggingService.success(`   Complete show file (${enhancedSetlist.setlistItems.length} songs, ${enhancedSetlist.trackDurations.length} durations, ${enhancedSetlist.songGaps.length} gaps)`);
                    }
                    
                } catch (error) {
                    LoggingService.error(`Error processing show ${tourDate.date}: ${error.message}`);
                    showsSkipped++;
                    updatedTourDates.push(tourDate); // Keep original without showFile
                }
            } else {
                // Future show - keep as-is
                updatedTourDates.push(tourDate);
            }
        }
        
        // Step 6: Update control file with show file references and smart tracking
        // Only update if there were actual changes to show files
        const hadChanges = showsCreated > 0 || showsUpdated > 0;

        const updatedControlFile = {
            ...controlFileData,
            currentTour: {
                ...controlFileData.currentTour,
                tourDates: updatedTourDates
            },
            updateTracking: {
                // Only update timestamp if we made changes, otherwise preserve existing
                lastAPICheck: hadChanges
                    ? new Date().toISOString()
                    : controlFileData.updateTracking?.lastAPICheck || new Date().toISOString(),
                latestShowFromAPI: controlFileData.latestShow.date,
                pendingDurationChecks: Object.keys(individualShowsTracking).filter(date =>
                    individualShowsTracking[date].needsUpdate
                ),
                individualShows: individualShowsTracking
            }
        };

        // Only write control file if there were changes
        if (hadChanges) {
            writeFileSync(controlFilePath, JSON.stringify(updatedControlFile, null, 2));
            LoggingService.success('Control file updated with show file references');
        } else {
            LoggingService.info('Control file unchanged - no show updates needed');
        }
        
        console.timeEnd('🚀 Total Initialization Time');
        LoggingService.success('Tour show files initialization completed!');
        LoggingService.info(`Results:`);
        LoggingService.info(`   Shows created: ${showsCreated}`);
        LoggingService.info(`   Shows updated: ${showsUpdated}`);
        LoggingService.info(`   Shows skipped (no changes): ${controlFileData.currentTour.playedShows - showsCreated - showsUpdated - showsSkipped}`);
        LoggingService.info(`   Shows with partial data: ${showsWithPartialData}`);
        LoggingService.info(`   Shows failed: ${showsSkipped}`);
        LoggingService.info(`Show files location: ${tourShowsDir}`);
        LoggingService.info(`API Performance: ${dataContext.apiCalls.total} total calls for entire tour`);
        LoggingService.info(`Optimization: Only ${showsCreated + showsUpdated} of ${controlFileData.currentTour.playedShows} shows required file writes`);
        
        if (showsWithPartialData > 0) {
            LoggingService.info(`Next steps:`);
            LoggingService.info(`   - ${showsWithPartialData} shows have partial data and are marked for future updates`);
            LoggingService.info(`   - Smart update detection will check for duration data availability`);
            LoggingService.info(`   - Run the smart update script periodically to complete partial data`);
        }
        
        LoggingService.success(`Ready to run: npm run generate-stats (will use show files, 0 API calls)`);
        
    } catch (error) {
        LoggingService.error('Error initializing tour shows:', error);
        LoggingService.error('Stack trace:', error.stack);
        process.exit(1);
    }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    initializeTourShows();
}