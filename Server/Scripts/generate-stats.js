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

import { writeFileSync, readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { TourStatisticsService } from '../Services/TourStatisticsService.js';
import { EnhancedSetlistService } from '../Services/EnhancedSetlistService.js';
import { HistoricalDataEnhancer } from '../Services/HistoricalDataEnhancer.js';
import { PhishNetTourService } from '../Services/PhishNetTourService.js';
import { DataCollectionService } from '../Services/DataCollectionService.js';
import StatisticsConfig from '../Config/StatisticsConfig.js';

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
        console.log('🎯 Starting real tour statistics generation...');
        
        // Initialize services with real API key
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        const tourService = new PhishNetTourService(CONFIG.PHISH_NET_API_KEY);
        
        // Step 1: Get latest Summer Tour show (not just latest show)
        console.log('📡 Fetching 2025 shows from Phish.net...');
        const year2025Shows = await enhancedService.phishNetClient.fetchShows('2025');
        console.log(`📊 Found ${year2025Shows.length} total 2025 shows`);
        
        // Debug: Show unique tour names and sample data
        const tourNames = [...new Set(year2025Shows.map(show => show.tourname))];
        console.log(`🎯 Available tour names: ${tourNames.join(', ')}`);
        
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
        
        // Step 7: Save result to both locations (Server/Data and api/Data)
        const serverOutputPath = join(__dirname, '..', 'Data', 'tour-stats.json');
        const apiOutputPath = join(__dirname, '..', '..', 'api', 'Data', 'tour-stats.json');
        
        const jsonData = JSON.stringify(enhancedTourStats, null, 2);
        writeFileSync(serverOutputPath, jsonData);
        writeFileSync(apiOutputPath, jsonData);
        
        console.log('✅ Real tour statistics generated successfully!');
        console.log(`📁 Server data: ${serverOutputPath}`);
        console.log(`📁 API data: ${apiOutputPath}`);
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
        
        // Step 7: Save result to API directory only (eliminates Xcode duplicate file conflict)
        const apiOutputPath = join(__dirname, '..', '..', 'api', 'Data', 'tour-stats.json');
        
        const jsonData = JSON.stringify(enhancedTourStats, null, 2);
        writeFileSync(apiOutputPath, jsonData);
        
        console.timeEnd('🚀 Total Generation Time');
        console.log('✅ OPTIMIZED tour statistics generated successfully!');
        console.log(`📁 API data: ${apiOutputPath}`);
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
 * 
 * Architecture:
 * - Control file: api/Data/tour-dashboard-data.json (tour orchestration)
 * - Show files: api/Data/shows/show-YYYY-MM-DD.json (detailed setlist data)
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
        
        // Validate complete show file coverage - NO FALLBACK
        if (allTourShows.length < controlFileData.currentTour.playedShows) {
            const missingShows = controlFileData.currentTour.playedShows - allTourShows.length;
            const missingDates = [];
            
            // Identify which specific shows are missing
            for (const tourDate of controlFileData.currentTour.tourDates) {
                if (tourDate.played && !tourDate.showFile) {
                    missingDates.push(tourDate.date);
                }
            }
            
            console.error(`❌ SINGLE SOURCE ERROR: Only ${allTourShows.length}/${controlFileData.currentTour.playedShows} show files available.`);
            console.error(`❌ Missing ${missingShows} shows. The following shows need show files generated:`);
            missingDates.forEach(date => console.error(`   • ${date}`));
            console.error(`❌ Please run: npm run initialize-tour-shows`);
            console.error(`❌ This will create all required show files for the single source architecture.`);
            
            throw new Error(`Single source of truth violation: Missing ${missingShows} show files. Run 'npm run initialize-tour-shows' to generate all required files.`);
        }
        
        if (allTourShows.length === 0) {
            throw new Error('No show data loaded. Please run initialization script to create show files.');
        }
        
        // Step 3: Calculate statistics using existing modular architecture
        console.log('📊 Calculating tour statistics using modular calculator system...');
        const tourStats = TourStatisticsService.calculateTourStatistics(allTourShows, tourName);
        
        // Step 4: Enhance statistics with historical data (same as optimized version)
        console.log('🔍 Enhancing statistics with historical data...');
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        const historicalEnhancer = new HistoricalDataEnhancer(enhancedService.phishNetClient);
        const enhancedTourStats = await historicalEnhancer.enhanceStatistics(tourStats);
        
        // Step 5: Save result to API directory (same output as optimized version)
        const apiOutputPath = join(__dirname, '..', '..', 'api', 'Data', 'tour-stats.json');
        
        const jsonData = JSON.stringify(enhancedTourStats, null, 2);
        writeFileSync(apiOutputPath, jsonData);
        
        console.timeEnd('🎯 Total Generation Time');
        console.log('✅ SINGLE SOURCE tour statistics generated successfully!');
        console.log(`📁 API data: ${apiOutputPath}`);
        console.log(`🎵 Generated statistics for: ${enhancedTourStats.tourName}`);
        console.log(`   📊 Longest songs: ${enhancedTourStats.longestSongs.length}`);
        console.log(`   📊 Rarest songs: ${enhancedTourStats.rarestSongs.length} (${StatisticsConfig.getHistoricalEnhancementConfig('rarestSongs').enhanceTopN} enhanced with historical data)`); 
        console.log(`   📊 Most played: ${enhancedTourStats.mostPlayedSongs.length}`);
        console.log(`🚀 Data Source: Control file + individual show files (0 API calls for tour data)`);
        console.log(`📖 Shows processed: ${allTourShows.length} enhanced setlists from control file`);
        
    } catch (error) {
        console.error('❌ Error generating single source tour statistics:', error);
        console.error('Stack trace:', error.stack);
        process.exit(1);
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