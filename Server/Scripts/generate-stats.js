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

import { writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { TourStatisticsService } from '../Services/TourStatisticsService.js';
import { EnhancedSetlistService } from '../Services/EnhancedSetlistService.js';
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
        
        // Initialize enhanced setlist service with real API key
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        
        // Step 1: Get latest show (exact same as iOS LatestSetlistViewModel:38)
        console.log('📡 Fetching latest show from Phish.net...');
        const latestShow = await enhancedService.phishNetClient.fetchLatestShow();
        if (!latestShow) {
            throw new Error('No latest show found - cannot generate statistics');
        }
        console.log(`🎪 Latest show found: ${latestShow.showdate} at ${latestShow.venue || 'Unknown Venue'}`);
        
        // Step 2: Get enhanced setlist with tour info (same as iOS APIManager.fetchEnhancedSetlist)
        console.log('🔗 Creating enhanced setlist with multi-API data...');
        const latestEnhanced = await enhancedService.createEnhancedSetlist(latestShow.showdate);
        
        // Step 3: Determine current tour (same as iOS :292)
        const tourName = latestEnhanced.tourPosition?.tourName || "Current Tour";
        console.log(`📍 Current tour identified: ${tourName}`);
        
        // Step 4: Collect all tour shows (same as iOS :306-316)
        console.log('📋 Collecting enhanced data for entire tour...');
        const allTourShows = await enhancedService.collectTourData(tourName, latestShow.showdate);
        console.log(`🎪 Tour data collected: ${allTourShows.length} shows processed`);
        
        // Step 5: Calculate statistics using new modular architecture
        console.log('📊 Calculating tour statistics using modular calculator system...');
        const tourStats = TourStatisticsService.calculateTourStatistics(allTourShows, tourName);
        
        // Step 6: Save result to both locations (Server/Data and api/Data)
        const serverOutputPath = join(__dirname, '..', 'Data', 'tour-stats.json');
        const apiOutputPath = join(__dirname, '..', '..', 'api', 'Data', 'tour-stats.json');
        
        const jsonData = JSON.stringify(tourStats, null, 2);
        writeFileSync(serverOutputPath, jsonData);
        writeFileSync(apiOutputPath, jsonData);
        
        console.log('✅ Real tour statistics generated successfully!');
        console.log(`📁 Server data: ${serverOutputPath}`);
        console.log(`📁 API data: ${apiOutputPath}`);
        console.log(`🎵 Generated statistics for: ${tourStats.tourName}`);
        console.log(`   📊 Longest songs: ${tourStats.longestSongs.length}`);
        console.log(`   📊 Rarest songs: ${tourStats.rarestSongs.length}`); 
        console.log(`   📊 Most played: ${tourStats.mostPlayedSongs.length}`);
        
    } catch (error) {
        console.error('❌ Error generating tour statistics:', error);
        console.error('Stack trace:', error.stack);
        process.exit(1);
    }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    generateTourStatistics();
}