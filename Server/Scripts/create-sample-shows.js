/**
 * create-sample-shows.js
 * 
 * Quick script to create 4-5 sample show files for testing the full architecture
 */

import { writeFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { EnhancedSetlistService } from '../Services/EnhancedSetlistService.js';
import StatisticsConfig from '../Config/StatisticsConfig.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const apiConfig = StatisticsConfig.getApiConfig('phishNet');
const CONFIG = {
    PHISH_NET_API_KEY: apiConfig.defaultApiKey,
};

async function createSampleShows() {
    try {
        console.log('🎯 Creating sample show files for testing...');
        
        const tourSlug = '2025-early-summer-tour';
        const tourShowsDir = join(__dirname, '..', '..', 'api', 'Data', 'tours', tourSlug);
        
        // Sample dates from different parts of the tour
        const sampleDates = ['2025-07-26', '2025-07-25', '2025-07-23', '2025-07-22'];
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        
        for (const testDate of sampleDates) {
            console.log(`\n🎯 Creating enhanced setlist for ${testDate}...`);
            
            try {
                const enhancedSetlist = await enhancedService.createEnhancedSetlist(testDate);
                
                if (!enhancedSetlist) {
                    console.warn(`⚠️  Could not create enhanced setlist for ${testDate}`);
                    continue;
                }
                
                console.log(`✅ Enhanced setlist created:`);
                console.log(`   📋 Setlist items: ${enhancedSetlist.setlistItems.length}`);
                console.log(`   🎵 Track durations: ${enhancedSetlist.trackDurations.length}`);
                console.log(`   📊 Song gaps: ${enhancedSetlist.songGaps.length}`);
                
                const showFileName = `show-${testDate}.json`;
                const showFilePath = join(tourShowsDir, showFileName);
                
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
                console.log(`💾 Show file created: ${showFileName}`);
                
            } catch (error) {
                console.error(`❌ Error creating show ${testDate}: ${error.message}`);
            }
        }
        
        console.log('\\n🎯 Sample show creation completed!');
        
    } catch (error) {
        console.error('❌ Error creating sample shows:', error);
        process.exit(1);
    }
}

createSampleShows();