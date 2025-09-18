#!/usr/bin/env node

/**
 * cleanup-venue-runs.js
 *
 * Removes embedded venueRun data from trackDurations in all show files.
 * Venue runs should only come from Phish.net, not be embedded in Phish.in duration data.
 *
 * This script:
 * 1. Finds all show JSON files
 * 2. Removes venueRun from each track duration entry
 * 3. Preserves all other duration data
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import LoggingService from '../Services/LoggingService.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Data directory path
const DATA_DIR = path.join(__dirname, '..', 'Data', 'tours');

/**
 * Clean venueRun from trackDurations in a show file
 */
function cleanShowFile(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const show = JSON.parse(content);

        let modified = false;

        // Check if trackDurations exists and has data
        if (show.trackDurations && Array.isArray(show.trackDurations)) {
            show.trackDurations.forEach(track => {
                if (track.venueRun) {
                    delete track.venueRun;
                    modified = true;
                }
            });
        }

        if (modified) {
            // Write back the cleaned data
            fs.writeFileSync(filePath, JSON.stringify(show, null, 2));
            return true;
        }

        return false;
    } catch (error) {
        LoggingService.error(`Error processing ${filePath}: ${error.message}`);
        return false;
    }
}

/**
 * Find all show JSON files in the tours directory
 */
function findShowFiles(dir) {
    const files = [];

    try {
        const items = fs.readdirSync(dir, { withFileTypes: true });

        for (const item of items) {
            const fullPath = path.join(dir, item.name);

            if (item.isDirectory()) {
                // Recursively search subdirectories
                files.push(...findShowFiles(fullPath));
            } else if (item.isFile() && item.name.startsWith('show-') && item.name.endsWith('.json')) {
                files.push(fullPath);
            }
        }
    } catch (error) {
        LoggingService.error(`Error reading directory ${dir}: ${error.message}`);
    }

    return files;
}

/**
 * Main cleanup function
 */
function cleanupVenueRuns() {
    LoggingService.start('Starting venue run cleanup from track durations...');

    // Check if data directory exists
    if (!fs.existsSync(DATA_DIR)) {
        LoggingService.error('Data directory not found:', DATA_DIR);
        process.exit(1);
    }

    // Find all show files
    const showFiles = findShowFiles(DATA_DIR);
    LoggingService.info(`Found ${showFiles.length} show files to check`);

    let cleanedCount = 0;
    let skippedCount = 0;

    // Process each show file
    showFiles.forEach(file => {
        const relativePath = path.relative(DATA_DIR, file);
        process.stdout.write(`   Checking ${relativePath}... `);

        if (cleanShowFile(file)) {
            console.log('✅ Cleaned');
            cleanedCount++;
        } else {
            console.log('⏭️  Skipped (no venue runs found)');
            skippedCount++;
        }
    });

    LoggingService.info('Cleanup Summary:');
    LoggingService.info(`   ✅ Cleaned: ${cleanedCount} files`);
    LoggingService.info(`   ⏭️  Skipped: ${skippedCount} files`);
    LoggingService.info(`   📁 Total: ${showFiles.length} files`);

    if (cleanedCount > 0) {
        LoggingService.success('Venue run data has been removed from track durations!');
        LoggingService.info('Venue runs should only come from Phish.net, not Phish.in.');
    } else {
        LoggingService.success('No venue run data found in track durations - already clean!');
    }
}

// Run the cleanup
cleanupVenueRuns();