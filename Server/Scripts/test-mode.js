#!/usr/bin/env node
/**
 * test-mode.js
 *
 * Switches the app to test mode using 2025 Early Summer Tour data.
 * Backs up production data for easy restoration.
 *
 * Usage: npm run test-mode [-- --through 2025-07-15]
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dataDir = path.join(__dirname, '..', 'Data');

// Configuration
const TEST_TOUR_DIR = 'tours/2025-early-summer-tour';
const THROUGH_DATE = process.argv.includes('--through')
    ? process.argv[process.argv.indexOf('--through') + 1]
    : '2025-07-15';

console.log('🧪 Switching to TEST MODE');
console.log(`   Tour: 2025 Early Summer Tour`);
console.log(`   Through: ${THROUGH_DATE}`);
console.log('');

// Step 1: Backup production data
const dashboardPath = path.join(dataDir, 'tour-dashboard-data.json');
const statsPath = path.join(dataDir, 'tour-stats.json');
const backupDashboardPath = path.join(dataDir, 'tour-dashboard-data.json.prod');
const backupStatsPath = path.join(dataDir, 'tour-stats.json.prod');

if (!fs.existsSync(backupDashboardPath)) {
    console.log('📦 Backing up production data...');
    fs.copyFileSync(dashboardPath, backupDashboardPath);
    fs.copyFileSync(statsPath, backupStatsPath);
    console.log('   ✓ Backed up tour-dashboard-data.json.prod');
    console.log('   ✓ Backed up tour-stats.json.prod');
} else {
    console.log('📦 Production backup already exists, skipping backup');
}

// Step 2: Find all shows up to THROUGH_DATE
const tourDir = path.join(dataDir, TEST_TOUR_DIR);
const showFiles = fs.readdirSync(tourDir)
    .filter(f => f.startsWith('show-') && f.endsWith('.json'))
    .filter(f => {
        const date = f.replace('show-', '').replace('.json', '');
        return date <= THROUGH_DATE;
    })
    .sort();

console.log(`\n📋 Including ${showFiles.length} shows:`);
showFiles.forEach((f, i) => {
    const date = f.replace('show-', '').replace('.json', '');
    console.log(`   ${i + 1}. ${date}`);
});

// Step 3: Load first show to get tour info
const firstShowPath = path.join(tourDir, showFiles[0]);
const firstShow = JSON.parse(fs.readFileSync(firstShowPath, 'utf8'));
const lastShowPath = path.join(tourDir, showFiles[showFiles.length - 1]);
const lastShow = JSON.parse(fs.readFileSync(lastShowPath, 'utf8'));

// Step 4: Build tour dates array
const tourDates = showFiles.map((f, index) => {
    const showPath = path.join(tourDir, f);
    const show = JSON.parse(fs.readFileSync(showPath, 'utf8'));
    const date = f.replace('show-', '').replace('.json', '');

    return {
        date: date,
        venue: show.venue,
        city: show.city,
        state: show.state,
        played: true,
        showNumber: index + 1,
        showFile: `${TEST_TOUR_DIR}/${f}`
    };
});

// Step 5: Create test tour-dashboard-data.json
const testDashboard = {
    currentTour: {
        name: "2025 Early Summer Tour",
        year: "2025",
        totalShows: showFiles.length,
        playedShows: showFiles.length,
        startDate: tourDates[0].date,
        endDate: tourDates[tourDates.length - 1].date,
        tourDates: tourDates
    },
    latestShow: {
        date: lastShow.showDate,
        venue: lastShow.venue,
        city: lastShow.city,
        state: lastShow.state,
        tourPosition: {
            showNumber: showFiles.length,
            totalShows: showFiles.length,
            tourName: "2025 Early Summer Tour"
        }
    },
    futureTours: [],
    metadata: {
        lastUpdated: new Date().toISOString(),
        dataVersion: "1.0",
        updateReason: "test_mode",
        nextShow: null
    },
    updateTracking: {
        lastAPICheck: new Date().toISOString(),
        latestShowFromAPI: tourDates[tourDates.length - 1].date,
        pendingDurationChecks: [],
        individualShows: {}
    }
};

// Add individual show tracking
tourDates.forEach(td => {
    testDashboard.updateTracking.individualShows[td.date] = {
        exists: true,
        lastUpdated: new Date().toISOString(),
        durationsAvailable: true,
        dataComplete: true,
        needsUpdate: false
    };
});

// Write test dashboard
fs.writeFileSync(dashboardPath, JSON.stringify(testDashboard, null, 2));
console.log('\n✅ Created test tour-dashboard-data.json');

// Step 6: Regenerate stats
console.log('\n🔄 Regenerating statistics...\n');
import { execSync } from 'child_process';
try {
    execSync('npm run generate-stats -- --force', {
        stdio: 'inherit',
        cwd: path.join(__dirname, '..', '..')
    });
} catch (error) {
    console.error('Error generating stats:', error.message);
}

console.log('\n🧪 TEST MODE ACTIVE');
console.log('   Run "npm run prod-mode" to restore production data');
console.log('   Run "npm run deploy" to deploy test data (careful!)');
