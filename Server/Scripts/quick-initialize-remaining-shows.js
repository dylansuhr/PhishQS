/**
 * quick-initialize-remaining-shows.js
 * 
 * Quick script to initialize just the missing show files needed for single source architecture
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

async function initializeRemainingShows() {
    try {
        console.log('🎯 Initializing remaining show files for single source architecture...');
        
        // Read control file to see what's missing
        const controlFilePath = join(__dirname, '..', '..', 'api', 'Data', 'tour-dashboard-data.json');
        const controlFileData = JSON.parse(readFileSync(controlFilePath, 'utf8'));
        
        const tourSlug = '2025-early-summer-tour';
        const tourShowsDir = join(__dirname, '..', '..', 'api', 'Data', 'tours', tourSlug);
        
        // Find dates that need show files
        const missingDates = [];
        for (const tourDate of controlFileData.currentTour.tourDates) {
            if (tourDate.played && !tourDate.showFile) {
                missingDates.push(tourDate);
            }
        }
        
        console.log(`📊 Found ${missingDates.length} shows needing initialization:`);
        missingDates.forEach(date => console.log(`   • ${date.date} at ${date.venue}`));
        
        if (missingDates.length === 0) {
            console.log('✅ All show files already exist!');
            return;
        }
        
        const enhancedService = new EnhancedSetlistService(CONFIG.PHISH_NET_API_KEY);
        const updatedTourDates = [...controlFileData.currentTour.tourDates];
        let processedCount = 0;
        
        for (const tourDate of missingDates) {
            console.log(`\\n🔄 [${processedCount + 1}/${missingDates.length}] Processing ${tourDate.date}...`);
            
            try {
                const enhancedSetlist = await enhancedService.createEnhancedSetlist(tourDate.date);
                
                if (!enhancedSetlist) {
                    console.warn(`⚠️  Could not create enhanced setlist for ${tourDate.date}`);
                    continue;
                }
                
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
                        durationsSource: enhancedSetlist.trackDurations.length > 0 ? 'phishin' : null,
                        lastUpdated: new Date().toISOString(),
                        dataComplete: enhancedSetlist.setlistItems.length > 0 && enhancedSetlist.trackDurations.length > 0
                    }
                };
                
                writeFileSync(showFilePath, JSON.stringify(showFileData, null, 2));
                
                // Update the tour date in the array
                const dateIndex = updatedTourDates.findIndex(d => d.date === tourDate.date);
                if (dateIndex >= 0) {
                    updatedTourDates[dateIndex] = {
                        ...updatedTourDates[dateIndex],
                        showFile: `tours/${tourSlug}/${showFileName}`
                    };
                }
                
                console.log(`   ✅ Created: ${showFileName} (${enhancedSetlist.setlistItems.length} songs, ${enhancedSetlist.trackDurations.length} durations)`);
                processedCount++;
                
            } catch (error) {
                console.error(`   ❌ Error processing ${tourDate.date}: ${error.message}`);
            }
        }
        
        // Update control file with new show file references
        const updatedControlFile = {
            ...controlFileData,
            currentTour: {
                ...controlFileData.currentTour,
                tourDates: updatedTourDates
            }
        };
        
        writeFileSync(controlFilePath, JSON.stringify(updatedControlFile, null, 2));
        
        console.log(`\\n✅ Initialization complete!`);
        console.log(`📊 Shows processed: ${processedCount}/${missingDates.length}`);
        console.log(`🔄 Control file updated with show file references`);
        console.log(`🎯 Ready for: npm run generate-stats`);
        
    } catch (error) {
        console.error('❌ Error initializing remaining shows:', error);
        process.exit(1);
    }
}

initializeRemainingShows();