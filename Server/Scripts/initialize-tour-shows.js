/**
 * initialize-tour-shows.js
 * 
 * Script to initialize all individual show files for the current tour.
 * Creates complete setlist and duration data files for each show in the tour.
 * 
 * Architecture Features:
 * - Reads control file to determine which shows need initialization
 * - Creates individual show files in api/Data/shows/ directory
 * - Uses existing enhanced setlist services for data collection
 * - Updates control file with show file references and smart flags
 * - Handles partial data scenarios (setlist available, durations pending)
 * 
 * This script should be run once to initialize the hybrid file system,
 * then individual show files can be updated as needed.
 */

import { writeFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { EnhancedSetlistService } from '../Services/EnhancedSetlistService.js';
import { HistoricalDataEnhancer } from '../Services/HistoricalDataEnhancer.js';
import { PhishNetTourService } from '../Services/PhishNetTourService.js';
import { DataCollectionService } from '../Services/DataCollectionService.js';
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
 * Initialize all tour show files from the control file
 */
async function initializeTourShows() {
    try {
        console.log('🚀 Starting tour show files initialization...');
        console.time('🚀 Total Initialization Time');
        
        // Step 1: Read control file
        const controlFilePath = join(__dirname, '..', '..', 'api', 'Data', 'tour-dashboard-data.json');
        
        if (!existsSync(controlFilePath)) {
            throw new Error(`Control file not found: ${controlFilePath}. Please run 'npm run update-tour-dashboard' first.`);
        }
        
        console.log('📖 Reading tour control file...');
        const controlFileData = JSON.parse(readFileSync(controlFilePath, 'utf8'));
        const tourName = controlFileData.currentTour.name;
        
        console.log(`📍 Initializing show files for: ${tourName}`);
        console.log(`🎪 Shows to process: ${controlFileData.currentTour.playedShows} played shows`);
        
        // Step 2: Create tour-specific shows directory
        const tourSlug = tourName.toLowerCase().replace(/\s+/g, '-'); // "2025-early-summer-tour"
        const tourShowsDir = join(__dirname, '..', '..', 'api', 'Data', 'tours', tourSlug);
        if (!existsSync(tourShowsDir)) {
            mkdirSync(tourShowsDir, { recursive: true });
            console.log(`📁 Created tour shows directory: ${tourShowsDir}`);
        }
        
        // Step 3: Use optimized data collection for all tour shows
        console.log('📊 Collecting enhanced data for entire tour (optimized API approach)...');
        const dataCollectionService = new DataCollectionService(CONFIG.PHISH_NET_API_KEY);
        const dataContext = await dataCollectionService.collectAllTourData('2025', tourName);
        
        console.log(`📈 Performance: Made ${dataContext.apiCalls.total} API calls for complete tour data`);
        
        // Step 4: Create enhanced setlist service for processing
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        
        // Step 5: Process each played show from the control file
        const updatedTourDates = [];
        const individualShowsTracking = {};
        let showsCreated = 0;
        let showsSkipped = 0;
        let showsWithPartialData = 0;
        
        for (const tourDate of controlFileData.currentTour.tourDates) {
            if (tourDate.played) {
                console.log(`\\n🔄 Processing show: ${tourDate.date} at ${tourDate.venue}`);
                
                try {
                    // Create enhanced setlist using pre-collected data context
                    const enhancedSetlist = enhancedService.createEnhancedSetlistFromContext(
                        tourDate.date,
                        dataContext
                    );
                    
                    if (!enhancedSetlist) {
                        console.warn(`⚠️  Could not create enhanced setlist for ${tourDate.date}`);
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
                        console.warn(`⚠️  No setlist data for ${tourDate.date} - skipping`);
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
                    
                    // Write show file
                    writeFileSync(showFilePath, JSON.stringify(showFileData, null, 2));
                    
                    // Update tour date with show file reference
                    const updatedTourDate = {
                        ...tourDate,
                        showFile: `tours/${tourSlug}/${showFileName}`
                    };
                    updatedTourDates.push(updatedTourDate);
                    
                    // Track individual show status for smart updates
                    individualShowsTracking[tourDate.date] = {
                        exists: true,
                        lastUpdated: new Date().toISOString(),
                        durationsAvailable: durationsAvailable,
                        dataComplete: dataComplete,
                        needsUpdate: !dataComplete // Need update if data is incomplete
                    };
                    
                    showsCreated++;
                    
                    if (!dataComplete) {
                        showsWithPartialData++;
                        console.log(`   ⏳ Show file created with partial data (setlist: ${hasSetlistData}, durations: ${hasDurationData}, gaps: ${hasGapData})`);
                    } else {
                        console.log(`   ✅ Complete show file created (${enhancedSetlist.setlistItems.length} songs, ${enhancedSetlist.trackDurations.length} durations, ${enhancedSetlist.songGaps.length} gaps)`);
                    }
                    
                } catch (error) {
                    console.error(`❌ Error processing show ${tourDate.date}: ${error.message}`);
                    showsSkipped++;
                    updatedTourDates.push(tourDate); // Keep original without showFile
                }
            } else {
                // Future show - keep as-is
                updatedTourDates.push(tourDate);
            }
        }
        
        // Step 6: Update control file with show file references and smart tracking
        const updatedControlFile = {
            ...controlFileData,
            currentTour: {
                ...controlFileData.currentTour,
                tourDates: updatedTourDates
            },
            updateTracking: {
                lastAPICheck: new Date().toISOString(),
                latestShowFromAPI: controlFileData.latestShow.date,
                pendingDurationChecks: Object.keys(individualShowsTracking).filter(date => 
                    individualShowsTracking[date].needsUpdate
                ),
                individualShows: individualShowsTracking
            }
        };
        
        writeFileSync(controlFilePath, JSON.stringify(updatedControlFile, null, 2));
        
        console.timeEnd('🚀 Total Initialization Time');
        console.log('\\n✅ Tour show files initialization completed!');
        console.log(`📊 Results:`);
        console.log(`   🎯 Shows created: ${showsCreated}`);
        console.log(`   ⏳ Shows with partial data: ${showsWithPartialData}`);
        console.log(`   ❌ Shows skipped: ${showsSkipped}`);
        console.log(`📁 Show files location: ${tourShowsDir}`);
        console.log(`🔄 Control file updated with show file references and smart tracking flags`);
        console.log(`🚀 API Performance: ${dataContext.apiCalls.total} total calls for entire tour`);
        
        if (showsWithPartialData > 0) {
            console.log(`\\n🔍 Next steps:`);
            console.log(`   - ${showsWithPartialData} shows have partial data and are marked for future updates`);
            console.log(`   - Smart update detection will check for duration data availability`);
            console.log(`   - Run the smart update script periodically to complete partial data`);
        }
        
        console.log(`\\n🎯 Ready to run: npm run generate-stats (will use show files, 0 API calls)`);
        
    } catch (error) {
        console.error('❌ Error initializing tour shows:', error);
        console.error('Stack trace:', error.stack);
        process.exit(1);
    }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    initializeTourShows();
}