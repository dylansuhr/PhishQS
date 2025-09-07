/**
 * test-single-show.js
 * 
 * Test script to create a single show file and verify the process works
 * before running the full initialization for all 23 shows.
 */

import { writeFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { EnhancedSetlistService } from '../Services/EnhancedSetlistService.js';
import StatisticsConfig from '../Config/StatisticsConfig.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration
const apiConfig = StatisticsConfig.getApiConfig('phishNet');
const CONFIG = {
    PHISH_NET_API_KEY: apiConfig.defaultApiKey,
};

async function testSingleShow() {
    try {
        console.log('🧪 Testing single show file creation...');
        
        // Create shows directory
        const showsDir = join(__dirname, '..', '..', 'api', 'Data', 'shows');
        if (!existsSync(showsDir)) {
            mkdirSync(showsDir, { recursive: true });
        }
        
        // Test with recent show
        const testDate = '2025-07-27';
        console.log(`🎯 Creating enhanced setlist for ${testDate}...`);
        
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        const enhancedSetlist = await enhancedService.createEnhancedSetlist(testDate);
        
        if (!enhancedSetlist) {
            throw new Error(`Could not create enhanced setlist for ${testDate}`);
        }
        
        console.log(`✅ Enhanced setlist created:`);
        console.log(`   📋 Setlist items: ${enhancedSetlist.setlistItems.length}`);
        console.log(`   🎵 Track durations: ${enhancedSetlist.trackDurations.length}`);
        console.log(`   📊 Song gaps: ${enhancedSetlist.songGaps.length}`);
        console.log(`   🎧 Recordings: ${enhancedSetlist.recordings.length}`);
        
        // Create show file
        const showFileName = `show-${testDate}.json`;
        const showFilePath = join(showsDir, showFileName);
        
        const showFileData = {
            showDate: enhancedSetlist.showDate,
            venue: enhancedSetlist.setlistItems?.[0]?.venue || 'Unknown Venue',
            city: enhancedSetlist.venueRun?.city || 'Unknown City',
            state: enhancedSetlist.venueRun?.state || 'Unknown State',
            tourPosition: enhancedSetlist.tourPosition,
            venueRun: enhancedSetlist.venueRun,
            setlistItems: enhancedSetlist.setlistItems,
            trackDurations: enhancedSetlist.trackDurations,
            songGaps: enhancedSetlist.songGaps,
            recordings: enhancedSetlist.recordings,
            metadata: {
                setlistSource: 'phishnet',
                durationsSource: enhancedSetlist.trackDurations.length > 0 ? 'phishin' : null,
                lastUpdated: new Date().toISOString(),
                dataComplete: enhancedSetlist.setlistItems.length > 0 && enhancedSetlist.trackDurations.length > 0
            }
        };
        
        writeFileSync(showFilePath, JSON.stringify(showFileData, null, 2));
        
        console.log(`💾 Show file created: ${showFilePath}`);
        console.log(`📊 File size: ${(Buffer.byteLength(JSON.stringify(showFileData), 'utf8') / 1024).toFixed(2)} KB`);
        
        // Test reading it back
        const readBack = JSON.parse(readFileSync(showFilePath, 'utf8'));
        console.log(`✅ File read back successfully with ${readBack.setlistItems.length} songs`);
        
        console.log('\\n🎯 Single show test completed successfully!');
        
    } catch (error) {
        console.error('❌ Error in single show test:', error);
        console.error('Stack trace:', error.stack);
        process.exit(1);
    }
}

testSingleShow();