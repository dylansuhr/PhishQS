/**
 * generate-stats.js
 *
 * Script to generate tour statistics JSON from real API data using
 * the new modular calculator architecture with configuration-driven settings.
 *
 * Architecture Features:
 * - Uses StatisticsConfig for all configuration (no hardcoding)
 * - Leverages StatisticsRegistry for modular calculator system
 * - Maintains exact iOS data flow pattern for compatibility
 * - Generates identical output format for seamless API integration
 *
 * Follows iOS project architecture patterns with server-side optimizations
 */

// Load environment variables from .env file (development only)
import dotenv from 'dotenv';
dotenv.config();

import { writeFileSync, readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { TourStatisticsService } from '../Services/TourStatisticsService.js';
import { EnhancedSetlistService } from '../Services/EnhancedSetlistService.js';
import { HistoricalDataEnhancer } from '../Services/HistoricalDataEnhancer.js';
import { PhishNetTourService } from '../Services/PhishNetTourService.js';
import { DataCollectionService } from '../Services/DataCollectionService.js';
import StatisticsConfig from '../Config/StatisticsConfig.js';
import LoggingService from '../Services/LoggingService.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration - now managed through StatisticsConfig
const apiConfig = StatisticsConfig.getApiConfig('phishNet');
const CONFIG = {
    PHISH_NET_API_KEY: apiConfig.defaultApiKey, // TODO: Move to environment variables  
    PHISH_NET_BASE_URL: apiConfig.baseUrl,
    PHISH_IN_BASE_URL: StatisticsConfig.getApiConfig('phishIn').baseUrl
};

/**
 * Main function to generate tour statistics from real API data
 * Follows exact iOS data flow: Latest Show → Enhanced Setlist → Tour Detection → Statistics
 */
async function generateTourStatistics() {
    try {
        LoggingService.start('Real tour statistics generation');
        
        // Initialize services with real API key
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        const tourService = new PhishNetTourService(CONFIG.PHISH_NET_API_KEY);
        
        // Step 1: Get latest Summer Tour show (not just latest show)
        LoggingService.info('Fetching 2025 shows from Phish.net...');
        const year2025Shows = await enhancedService.phishNetClient.fetchShows('2025');
        LoggingService.info(`Found ${year2025Shows.length} total 2025 shows`);
        
        // Debug: Show unique tour names and sample data
        const tourNames = [...new Set(year2025Shows.map(show => show.tourname))];
        LoggingService.debug(`Available tour names: ${tourNames.join(', ')}`);
        
        // Debug: Show sample show data to understand structure
        if (year2025Shows.length > 0) {
            console.log(`🔍 Sample show data:`, JSON.stringify(year2025Shows[0], null, 2));
        }
        
        // Find the latest Summer Tour show specifically  
        const summerTourShows = year2025Shows.filter(show => show.tourname === '2025 Summer Tour');
        console.log(`🎪 Found ${summerTourShows.length} Summer Tour 2025 shows`);
        console.log(`📊 This includes ${summerTourShows.length} played shows. Full tour should have 31 total shows per phish.net`);
        
        if (summerTourShows.length === 0) {
            throw new Error('No Summer Tour 2025 shows found - cannot generate statistics');
        }
        
        // Get the latest Summer Tour show (last chronologically)
        const latestShow = summerTourShows.sort((a, b) => a.showdate.localeCompare(b.showdate)).pop();
        console.log(`🎪 Latest Summer Tour show found: ${latestShow.showdate} at ${latestShow.venue || 'Unknown Venue'}`);
        
        // Step 2: Determine current tour (we know it's Summer Tour 2025)
        console.log('🔍 Using Summer Tour 2025 as current tour...');
        const tourName = '2025 Summer Tour';
        console.log(`📍 Current tour identified: ${tourName}`);
        
        // Step 3: Get enhanced setlist with multi-API data
        console.log('🔗 Creating enhanced setlist with multi-API data...');
        const latestEnhanced = await enhancedService.createEnhancedSetlist(latestShow.showdate);
        
        // Step 4: Collect all tour shows using Phish.net (includes future shows)
        console.log('📋 Collecting enhanced data for entire tour...');
        const allTourShows = await enhancedService.collectTourData(tourName, latestShow.showdate);
        console.log(`🎪 Tour data collected: ${allTourShows.length} shows processed (includes future scheduled shows)`);
        
        // Step 5: Calculate statistics using new modular architecture
        console.log('📊 Calculating tour statistics using modular calculator system...');
        const tourStats = TourStatisticsService.calculateTourStatistics(allTourShows, tourName);
        
        // Step 6: Enhance statistics with historical data (only for top N results)
        console.log('🔍 Enhancing statistics with historical data...');
        const historicalEnhancer = new HistoricalDataEnhancer(enhancedService.phishNetClient);
        const enhancedTourStats = await historicalEnhancer.enhanceStatistics(tourStats);
        
        // Step 7: Save result to Server/Data directory (single source of truth)
        const outputPath = join(__dirname, '..', 'Data', 'tour-stats.json');

        const jsonData = JSON.stringify(enhancedTourStats, null, 2);
        writeFileSync(outputPath, jsonData);

        console.log('✅ Real tour statistics generated successfully!');
        console.log(`📁 Data saved to: ${outputPath}`);
        console.log(`🎵 Generated statistics for: ${enhancedTourStats.tourName}`);
        console.log(`   📊 Longest songs: ${enhancedTourStats.longestSongs.length}`);
        console.log(`   📊 Rarest songs: ${enhancedTourStats.rarestSongs.length} (${StatisticsConfig.getHistoricalEnhancementConfig('rarestSongs').enhanceTopN} enhanced with historical data)`); 
        console.log(`   📊 Most played: ${enhancedTourStats.mostPlayedSongs.length}`);
        
    } catch (error) {
        console.error('❌ Error generating tour statistics:', error);
        console.error('Stack trace:', error.stack);
        process.exit(1);
    }
}

/**
 * OPTIMIZED: Generate tour statistics with minimal API calls
 * 
 * This optimized version uses DataCollectionService to collect all required
 * data in a single coordinated process, eliminating the ~116 redundant API calls
 * from the original approach.
 * 
 * Performance improvements:
 * - Reduces API calls by ~96% (116 → ~5 calls)
 * - Faster execution due to elimination of API latency per show
 * - Same exact output format as original function
 */
async function generateTourStatisticsOptimized() {
    try {
        console.log('🚀 Starting OPTIMIZED tour statistics generation...');
        console.time('🚀 Total Generation Time');
        
        // Step 1: Collect ALL required data with minimal API calls
        console.log('📊 Using DataCollectionService for optimal data collection...');
        const dataCollectionService = new DataCollectionService(CONFIG.PHISH_NET_API_KEY);
        const dataContext = await dataCollectionService.collectAllTourData('2025', '2025 Early Summer Tour');
        
        // Show performance comparison
        console.log(`📈 Performance: Made ${dataContext.apiCalls.total} API calls (vs ~116 in original approach)`);
        
        // Step 2: Find the latest Summer Tour show from pre-collected data
        const latestShow = dataContext.tourShows
            .sort((a, b) => a.showdate.localeCompare(b.showdate))
            .pop();
        
        if (!latestShow) {
            throw new Error('No Summer Tour 2025 shows found - cannot generate statistics');
        }
        
        console.log(`🎪 Latest Summer Tour show found: ${latestShow.showdate} at ${latestShow.venue || 'Unknown Venue'}`);
        console.log(`📍 Current tour identified: ${dataContext.tourName}`);
        
        // Step 3: Create enhanced setlist for latest show using pre-collected data
        console.log('🔗 Creating enhanced setlist with pre-collected data...');
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        const latestEnhanced = enhancedService.createEnhancedSetlistFromContext(
            latestShow.showdate, 
            dataContext
        );
        
        // Step 4: Collect all tour enhanced setlists using pre-collected data
        console.log('📋 Creating enhanced setlists for entire tour...');
        const allTourShows = enhancedService.collectTourDataFromContext(dataContext);
        console.log(`🎪 Tour data processed: ${allTourShows.length} shows enhanced (includes complete tour data)`);
        
        // Step 5: Calculate statistics using new modular architecture (same as original)
        console.log('📊 Calculating tour statistics using modular calculator system...');
        const tourStats = TourStatisticsService.calculateTourStatistics(allTourShows, dataContext.tourName);
        
        // Step 6: Enhance statistics with historical data (same as original)
        console.log('🔍 Enhancing statistics with historical data...');
        const historicalEnhancer = new HistoricalDataEnhancer(enhancedService.phishNetClient);
        const enhancedTourStats = await historicalEnhancer.enhanceStatistics(tourStats);
        
        // Step 7: Save result to Server/Data directory (single source of truth)
        const outputPath = join(__dirname, '..', 'Data', 'tour-stats.json');

        const jsonData = JSON.stringify(enhancedTourStats, null, 2);
        writeFileSync(outputPath, jsonData);

        console.timeEnd('🚀 Total Generation Time');
        console.log('✅ OPTIMIZED tour statistics generated successfully!');
        console.log(`📁 Data saved to: ${outputPath}`);
        console.log(`🎵 Generated statistics for: ${enhancedTourStats.tourName}`);
        console.log(`   📊 Longest songs: ${enhancedTourStats.longestSongs.length}`);
        console.log(`   📊 Rarest songs: ${enhancedTourStats.rarestSongs.length} (${StatisticsConfig.getHistoricalEnhancementConfig('rarestSongs').enhanceTopN} enhanced with historical data)`); 
        console.log(`   📊 Most played: ${enhancedTourStats.mostPlayedSongs.length}`);
        console.log(`🚀 API Call Optimization: ${dataContext.apiCalls.total} calls (reduced from ~116 calls)`);
        
    } catch (error) {
        console.error('❌ Error generating optimized tour statistics:', error);
        console.error('Stack trace:', error.stack);
        process.exit(1);
    }
}

/**
 * SINGLE SOURCE: Generate tour statistics using control file + individual show files
 *
 * This version implements the "Current Tour Single Source of Truth" architecture.
 * Instead of making API calls, it reads data from the control file and individual
 * show files created by the update-tour-dashboard.js script.
 *
 * Performance improvements:
 * - Zero API calls (100% reduction from optimized version)
 * - No network latency (instant data access)
 * - Consistent data with Component A
 * - Same exact output format as previous functions
 * - SMART EARLY EXIT: Skip processing if latest show unchanged
 *
 * Architecture:
 * - Control file: Server/Data/tour-dashboard-data.json (tour orchestration)
 * - Show files: Server/Data/tours/[tour-name]/show-YYYY-MM-DD.json (detailed setlist data)
 */
async function generateTourStatisticsFromControlFile() {
    try {
        console.log('🎯 Starting SINGLE SOURCE tour statistics generation...');
        console.time('🎯 Total Generation Time');

        // Step 1: Read control file for tour orchestration
        const controlFilePath = join(__dirname, '..', 'Data', 'tour-dashboard-data.json');

        if (!existsSync(controlFilePath)) {
            throw new Error(`Control file not found: ${controlFilePath}. Please run 'npm run update-tour-dashboard' first.`);
        }

        console.log('📖 Reading tour control file...');
        const controlFileData = JSON.parse(readFileSync(controlFilePath, 'utf8'));
        const tourName = controlFileData.currentTour.name;

        // OPTIMIZATION: Early exit if statistics don't need updating
        console.log('🔍 Checking if statistics update is needed...');
        const updateCheck = await checkIfStatisticsUpdateNeeded(controlFileData);
        if (!updateCheck.shouldUpdate) {
            console.timeEnd('🎯 Total Generation Time');
            console.log(`ℹ️ Statistics update not needed: ${updateCheck.reason}`);
            console.log('✅ Early exit - no processing required');
            return;
        }

        console.log(`🎯 Statistics update needed: ${updateCheck.reason}`);
        
        console.log(`📍 Tour identified from control file: ${tourName}`);
        console.log(`🎪 Tour shows: ${controlFileData.currentTour.playedShows} played of ${controlFileData.currentTour.totalShows} total`);
        
        // Step 2: Load individual show files for statistical analysis
        console.log('📋 Loading individual show files for tour data...');
        const allTourShows = [];
        let showsLoaded = 0;
        let showsSkipped = 0;
        
        for (const tourDate of controlFileData.currentTour.tourDates) {
            if (tourDate.played && tourDate.showFile) {
                const showFilePath = join(__dirname, '..', 'Data', tourDate.showFile);
                
                if (existsSync(showFilePath)) {
                    try {
                        const showData = JSON.parse(readFileSync(showFilePath, 'utf8'));
                        
                        // Convert show file format to expected format for TourStatisticsService
                        const enhancedShow = {
                            showDate: showData.showDate,
                            setlistItems: showData.setlistItems || [],
                            trackDurations: showData.trackDurations || [],
                            venueRun: showData.venueRun || null,
                            tourPosition: showData.tourPosition || null,
                            recordings: showData.recordings || [],
                            songGaps: showData.songGaps || []
                        };
                        
                        allTourShows.push(enhancedShow);
                        showsLoaded++;
                        
                    } catch (error) {
                        console.warn(`⚠️  Failed to load show file ${tourDate.showFile}: ${error.message}`);
                        showsSkipped++;
                    }
                } else {
                    console.warn(`⚠️  Show file not found: ${tourDate.showFile}`);
                    showsSkipped++;
                }
            }
        }
        
        console.log(`📊 Show files loaded: ${showsLoaded} successful, ${showsSkipped} skipped`);
        
        // Check for shows that are played, have show files, but couldn't be loaded
        // This is more lenient - we only fail if a show file exists but can't be loaded
        const showsWithFiles = controlFileData.currentTour.tourDates.filter(td => td.played && td.showFile);
        if (showsLoaded < showsWithFiles.length) {
            const failedToLoad = showsWithFiles.length - showsLoaded;
            console.error(`❌ SINGLE SOURCE ERROR: Could not load ${failedToLoad} show files that should exist.`);
            console.error(`❌ Please check the show files or run: npm run initialize-tour-shows`);
            throw new Error(`Single source of truth violation: Failed to load ${failedToLoad} existing show files.`);
        }
        
        // Info message about shows without setlists yet (not an error)
        const showsWithoutSetlists = controlFileData.currentTour.tourDates.filter(td => td.played && !td.showFile);
        if (showsWithoutSetlists.length > 0) {
            console.log(`ℹ️  ${showsWithoutSetlists.length} played show(s) don't have setlists yet (likely just finished):`);
            showsWithoutSetlists.forEach(td => console.log(`   • ${td.date} at ${td.venue}`));
            console.log(`   These will be processed in the next update once setlist data is available.`);
        }
        
        if (allTourShows.length === 0) {
            throw new Error('No show data loaded. Please run initialization script to create show files.');
        }
        
        // Step 3: Fetch comprehensive song database for statistics that need it
        console.log('🎵 Fetching comprehensive song database for MostCommonSongsNotPlayed calculator...');
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        const comprehensiveSongs = await fetchComprehensiveSongDatabase(enhancedService.phishNetClient);

        // Step 4: Calculate statistics using existing modular architecture with context
        console.log('📊 Calculating tour statistics using modular calculator system...');
        const context = {
            comprehensiveSongs: comprehensiveSongs
        };
        const tourStats = TourStatisticsService.calculateTourStatistics(allTourShows, tourName, context);

        // Step 5: Enhance statistics with historical data
        console.log('🔍 Enhancing statistics with historical data...');
        const historicalEnhancer = new HistoricalDataEnhancer(enhancedService.phishNetClient);
        const enhancedTourStats = await historicalEnhancer.enhanceStatistics(tourStats);
        
        // Step 6: Save result to Server/Data directory (single source of truth)
        const outputPath = join(__dirname, '..', 'Data', 'tour-stats.json');

        // Add tracking information for future optimization checks
        const statisticsWithTracking = {
            ...enhancedTourStats,
            latestShowProcessed: controlFileData.latestShow.date,
            generatedAt: new Date().toISOString(),
            tourName: tourName // Ensure tour name is preserved
        };

        const jsonData = JSON.stringify(statisticsWithTracking, null, 2);
        writeFileSync(outputPath, jsonData);

        console.timeEnd('🎯 Total Generation Time');
        console.log('✅ SINGLE SOURCE tour statistics generated successfully!');
        console.log(`📁 Data saved to: ${outputPath}`);
        console.log(`🎵 Generated statistics for: ${enhancedTourStats.tourName}`);
        console.log(`   📊 Longest songs: ${enhancedTourStats.longestSongs.length}`);
        console.log(`   📊 Rarest songs: ${enhancedTourStats.rarestSongs.length} (${StatisticsConfig.getHistoricalEnhancementConfig('rarestSongs').enhanceTopN} enhanced with historical data)`);
        console.log(`   📊 Most played: ${enhancedTourStats.mostPlayedSongs.length}`);
        console.log(`   📊 Common not played: ${enhancedTourStats.mostCommonSongsNotPlayed?.length || 0} (from ${comprehensiveSongs.length} total Phish songs)`);
        console.log(`🚀 Data Source: Control file + individual show files (0 API calls for tour data)`);
        console.log(`📖 Shows processed: ${allTourShows.length} enhanced setlists from control file`);
        
    } catch (error) {
        console.error('❌ Error generating single source tour statistics:', error);
        console.error('Stack trace:', error.stack);
        process.exit(1);
    }
}

/**
 * Check if statistics update is needed by comparing latest show with existing statistics
 *
 * This is the key optimization: if the latest show hasn't changed, statistics can't change.
 *
 * @param {Object} controlFileData - Tour dashboard control data
 * @returns {Promise<{shouldUpdate: boolean, reason: string}>}
 */
async function checkIfStatisticsUpdateNeeded(controlFileData) {
    const outputPath = join(__dirname, '..', 'Data', 'tour-stats.json');

    // Always update if no existing statistics file
    if (!existsSync(outputPath)) {
        return { shouldUpdate: true, reason: 'no_existing_statistics_file' };
    }

    try {
        // Load existing statistics
        const existingStats = JSON.parse(readFileSync(outputPath, 'utf8'));

        // Get current latest show from control file
        const currentLatestShow = controlFileData.latestShow;

        if (!currentLatestShow) {
            return { shouldUpdate: true, reason: 'no_latest_show_in_control_file' };
        }

        // Check if latest show has changed since last statistics generation
        const existingLatestShow = existingStats.latestShowProcessed;

        if (!existingLatestShow) {
            // Old format statistics file - needs update to track latest show
            return { shouldUpdate: true, reason: 'statistics_format_upgrade_needed' };
        }

        if (existingLatestShow !== currentLatestShow.date) {
            return {
                shouldUpdate: true,
                reason: `latest_show_changed (${existingLatestShow} → ${currentLatestShow.date})`
            };
        }

        // Latest show unchanged - no statistics update needed
        return {
            shouldUpdate: false,
            reason: `latest_show_unchanged (${currentLatestShow.date})`
        };

    } catch (error) {
        // If we can't read existing statistics, regenerate them
        console.warn(`⚠️ Error reading existing statistics: ${error.message}`);
        return { shouldUpdate: true, reason: 'error_reading_existing_statistics' };
    }
}

/**
 * Fetch comprehensive song database from Phish.net for "Most Common Songs Not Played" calculator
 *
 * Uses the same filtering logic as documented in CLAUDE.md to get all songs
 * performed by Phish (originals + covers), excluding side projects.
 *
 * @param {Object} phishNetClient - Phish.net API client instance
 * @returns {Promise<Array>} Filtered array of Phish-performed songs
 */
async function fetchComprehensiveSongDatabase(phishNetClient) {
    try {
        console.log('🔍 Fetching comprehensive song database from Phish.net...');
        const allSongs = await phishNetClient.fetchSongs();
        console.log(`📊 Retrieved ${allSongs.length} total songs from Phish.net`);

        // Filter to Phish-performed songs using side project exclusion
        const sideProjectArtists = [
            'Trey Anastasio', 'Mike Gordon', 'Page McConnell', 'Jon Fishman',
            'Oysterhead', 'Vida Blue', 'TAB', 'Surrender to the Air',
            'Phil Lesh and Friends', 'Bernie Worrell Orchestra'
        ];

        const phishPerformedSongs = allSongs.filter(song =>
            song.times_played > 0 &&
            !sideProjectArtists.includes(song.artist)
        );

        console.log(`✅ Filtered to ${phishPerformedSongs.length} Phish-performed songs (originals + covers)`);
        console.log(`🎯 Excluded ${allSongs.length - phishPerformedSongs.length} side project songs`);

        // Debug: Show breakdown
        const originals = phishPerformedSongs.filter(song => song.artist === 'Phish').length;
        const covers = phishPerformedSongs.length - originals;
        console.log(`   📈 ${originals} Phish originals + ${covers} covers by Phish`);

        return phishPerformedSongs;

    } catch (error) {
        console.error('❌ Error fetching comprehensive song database:', error);
        console.warn('⚠️  Returning empty song database - MostCommonSongsNotPlayed will return no results');
        return [];
    }
}

// Run comparison test: optimized vs single source
if (import.meta.url === `file://${process.argv[1]}`) {
    if (process.argv.includes('--compare')) {
        console.log('🔍 Running comparison test between optimized API and single source approaches...\n');
        
        console.log('=== OPTIMIZED API APPROACH ===');
        await generateTourStatisticsOptimized();
        
        console.log('\n=== SINGLE SOURCE APPROACH ===');
        await generateTourStatisticsFromControlFile();
        
    } else if (process.argv.includes('--optimized')) {
        generateTourStatisticsOptimized();
    } else {
        generateTourStatisticsFromControlFile();
    }
}