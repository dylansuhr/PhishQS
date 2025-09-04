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
import { HistoricalDataEnhancer } from '../Services/HistoricalDataEnhancer.js';
import { PhishNetTourService } from '../Services/PhishNetTourService.js';
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

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    generateTourStatistics();
}