/**
 * update-youtube-videos.js
 *
 * Independent YouTube video updater.
 * Runs on every cron regardless of show/duration changes.
 * Only needs current tour start date.
 *
 * Architecture:
 * - Decoupled from statistics generation
 * - Reads tour start date from control file
 * - Writes to separate youtube-videos.json file
 * - Auto-resets when a future tour becomes current tour
 */

import dotenv from 'dotenv';
dotenv.config();

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { YouTubeService } from '../Services/YouTubeService.js';
import LoggingService from '../Services/LoggingService.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

async function updateYouTubeVideos() {
    try {
        LoggingService.start('Starting YouTube video update...');
        console.time('YouTube Update Time');

        // Read control file for current tour start date
        const controlFilePath = join(__dirname, '..', 'Data', 'tour-dashboard-data.json');

        if (!existsSync(controlFilePath)) {
            throw new Error(`Control file not found: ${controlFilePath}. Please run 'npm run update-tour-dashboard' first.`);
        }

        const controlData = JSON.parse(readFileSync(controlFilePath, 'utf8'));

        // Get current tour start date (first date in tourDates array)
        const tourDates = controlData.currentTour?.tourDates;
        if (!tourDates || tourDates.length === 0) {
            throw new Error('No tour dates found in control file');
        }

        const tourStartDate = tourDates[0].date;
        const tourName = controlData.currentTour.name;
        const today = new Date().toISOString().split('T')[0];

        // Extract valid show dates for filtering
        const validShowDates = new Set(tourDates.map(show => show.date));

        LoggingService.info(`Current tour: ${tourName}`);
        LoggingService.info(`Date range: ${tourStartDate} to ${today}`);
        LoggingService.info(`Valid show dates: ${Array.from(validShowDates).join(', ')}`);

        // Fetch YouTube videos with show date filtering
        const youtubeService = new YouTubeService();
        const videos = await youtubeService.fetchTourVideos(tourStartDate, today, validShowDates);

        LoggingService.info(`Fetched ${videos.length} videos from YouTube API`);

        // Read existing file to check if update needed
        const outputPath = join(__dirname, '..', 'Data', 'youtube-videos.json');
        let existingData = null;
        let existingCount = 0;

        if (existsSync(outputPath)) {
            existingData = JSON.parse(readFileSync(outputPath, 'utf8'));
            existingCount = existingData.videos?.length || 0;
        }

        // Check if tour changed (new tour started)
        const tourChanged = existingData && existingData.tourStartDate !== tourStartDate;
        if (tourChanged) {
            LoggingService.info(`Tour changed: ${existingData.tourName} → ${tourName}`);
            LoggingService.info(`New start date: ${tourStartDate}`);
        }

        // Write if: count changed, tour changed, or file doesn't exist
        const shouldWrite = videos.length !== existingCount || tourChanged || !existingData;

        if (shouldWrite) {
            const output = {
                tourName: tourName,
                tourStartDate: tourStartDate,
                fetchedAt: new Date().toISOString(),
                videoCount: videos.length,
                videos: videos
            };

            writeFileSync(outputPath, JSON.stringify(output, null, 2));

            console.timeEnd('YouTube Update Time');

            if (tourChanged) {
                LoggingService.success(`New tour detected! Reset to ${videos.length} videos`);
            } else {
                LoggingService.success(`Updated: ${existingCount} → ${videos.length} videos`);
            }
        } else {
            console.timeEnd('YouTube Update Time');
            LoggingService.info(`No changes needed (${videos.length} videos)`);
        }

        LoggingService.info(`Output: ${outputPath}`);

    } catch (error) {
        LoggingService.error('Error updating YouTube videos:', error);
        LoggingService.error('Stack trace:', error.stack);
        process.exit(1);
    }
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
    updateYouTubeVideos();
}

export { updateYouTubeVideos };
