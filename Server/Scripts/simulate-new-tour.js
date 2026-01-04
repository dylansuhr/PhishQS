#!/usr/bin/env node
/**
 * simulate-new-tour.js
 *
 * Simulates the first show of a new tour being played.
 * Used to test that the app correctly handles tour transitions before app store release.
 *
 * This script:
 * 1. Backs up production data
 * 2. Creates mock show file for 2026-01-28 (first Mexico show)
 * 3. Updates tour-dashboard-data.json to reflect the transition
 * 4. Creates mock tour-stats.json for the new tour
 * 5. Validates all data structures
 *
 * Usage: npm run simulate-new-tour
 * Restore: npm run prod-mode
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dataDir = path.join(__dirname, '..', 'Data');

// Configuration
const NEW_TOUR_NAME = '2026 Mexico';
const NEW_TOUR_SLUG = '2026-mexico';
const FIRST_SHOW_DATE = '2026-01-28';
const VENUE = 'Moon Palace';
const CITY = 'Cancun, Quintana Roo';
const STATE = '';
const COUNTRY = 'Mexico';

console.log('🌴 SIMULATING NEW TOUR: 2026 Mexico');
console.log('   First Show: ' + FIRST_SHOW_DATE);
console.log('   Venue: ' + VENUE);
console.log('');

// =============================================================================
// Step 1: Backup production data
// =============================================================================

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

// =============================================================================
// Step 2: Create tours/2026-mexico/ directory
// =============================================================================

const tourDir = path.join(dataDir, 'tours', NEW_TOUR_SLUG);
if (!fs.existsSync(tourDir)) {
    fs.mkdirSync(tourDir, { recursive: true });
    console.log('📁 Created directory: tours/' + NEW_TOUR_SLUG);
} else {
    console.log('📁 Directory already exists: tours/' + NEW_TOUR_SLUG);
}

// =============================================================================
// Step 3: Create mock show file
// =============================================================================

const mockShowData = {
    showDate: FIRST_SHOW_DATE,
    venue: VENUE,
    city: CITY,
    state: STATE,
    tourPosition: {
        showNumber: 1,
        totalShows: 4,
        tourName: NEW_TOUR_NAME,
        tourYear: '2026'
    },
    venueRun: {
        venue: VENUE,
        city: CITY,
        state: STATE,
        nightNumber: 1,
        totalNights: 4,
        showDates: ['2026-01-28', '2026-01-29', '2026-01-30', '2026-01-31']
    },
    setlistItems: createMockSetlist(),
    trackDurations: createMockDurations(),
    footnoteLegend: [],
    songGaps: createMockSongGaps(),
    metadata: {
        setlistSource: 'simulated',
        durationsSource: 'simulated',
        lastUpdated: new Date().toISOString(),
        dataComplete: true
    }
};

const showFilePath = path.join(tourDir, `show-${FIRST_SHOW_DATE}.json`);
fs.writeFileSync(showFilePath, JSON.stringify(mockShowData, null, 2));
console.log('📄 Created show file: show-' + FIRST_SHOW_DATE + '.json');

// =============================================================================
// Step 4: Update tour-dashboard-data.json
// =============================================================================

const existingDashboard = JSON.parse(fs.readFileSync(dashboardPath, 'utf8'));

// Build new current tour from the first future tour (Mexico)
const mexicoTour = existingDashboard.futureTours.find(t => t.name === NEW_TOUR_NAME);

if (!mexicoTour) {
    console.error('❌ Could not find 2026 Mexico in futureTours!');
    process.exit(1);
}

// Update tour dates to mark first show as played
const updatedTourDates = mexicoTour.tourDates.map((date, index) => ({
    ...date,
    played: index === 0, // Only first show is played
    showFile: `tours/${NEW_TOUR_SLUG}/show-${date.date}.json`
}));

const newDashboard = {
    currentTour: {
        name: NEW_TOUR_NAME,
        year: '2026',
        totalShows: 4,
        playedShows: 1,
        startDate: '2026-01-28',
        endDate: '2026-01-31',
        tourDates: updatedTourDates
    },
    latestShow: {
        date: FIRST_SHOW_DATE,
        venue: VENUE,
        city: CITY,
        state: STATE,
        tourPosition: {
            showNumber: 1,
            totalShows: 4,
            tourName: NEW_TOUR_NAME
        }
    },
    // Remove Mexico from future tours, keep Sphere
    futureTours: existingDashboard.futureTours.filter(t => t.name !== NEW_TOUR_NAME),
    metadata: {
        lastUpdated: new Date().toISOString(),
        dataVersion: '1.0',
        updateReason: 'simulated_new_tour',
        nextShow: {
            date: '2026-01-29',
            venue: VENUE,
            city: CITY,
            state: STATE
        }
    },
    updateTracking: {
        lastAPICheck: new Date().toISOString(),
        latestShowFromAPI: FIRST_SHOW_DATE,
        pendingDurationChecks: [],
        individualShows: {
            [FIRST_SHOW_DATE]: {
                exists: true,
                lastUpdated: new Date().toISOString(),
                durationsAvailable: true,
                dataComplete: true,
                needsUpdate: false
            }
        }
    }
};

fs.writeFileSync(dashboardPath, JSON.stringify(newDashboard, null, 2));
console.log('📄 Updated tour-dashboard-data.json');

// =============================================================================
// Step 5: Create mock tour-stats.json
// =============================================================================

const mockStats = {
    tourName: NEW_TOUR_NAME,
    longestSongs: createMockLongestSongs(),
    rarestSongs: createMockRarestSongs(),
    mostPlayedSongs: createMockMostPlayed(),
    mostCommonSongsNotPlayed: [],
    openersClosers: {
        '1_opener': [{ songName: 'Buried Alive', songId: 96, count: 1, dates: [FIRST_SHOW_DATE] }],
        '1_closer': [{ songName: 'Run Like an Antelope', songId: 478, count: 1, dates: [FIRST_SHOW_DATE] }],
        '2_opener': [{ songName: 'Down with Disease', songId: 174, count: 1, dates: [FIRST_SHOW_DATE] }],
        '2_closer': [{ songName: 'Slave to the Traffic Light', songId: 512, count: 1, dates: [FIRST_SHOW_DATE] }],
        'e_all': [{ songName: 'Character Zero', songId: 127, count: 1, dates: [FIRST_SHOW_DATE] }]
    },
    repeats: {
        shows: [{
            date: FIRST_SHOW_DATE,
            venue: VENUE,
            city: CITY,
            state: STATE,
            venueRun: 'N1',
            totalSongs: 18,
            repeats: 0,
            repeatPercentage: 0,
            averageGap: 25.5,
            showNumber: 1,
            totalTourShows: 4
        }],
        hasRepeats: false,
        maxPercentage: 0,
        maxAverageGap: 25.5,
        totalShows: 1
    },
    debuts: {
        songs: [],
        latestShowDate: FIRST_SHOW_DATE,
        latestShowVenue: VENUE,
        latestShowCity: CITY,
        latestShowState: STATE,
        latestShowVenueRun: {
            venue: VENUE,
            city: CITY,
            state: STATE,
            nightNumber: 1,
            totalNights: 4,
            showDates: ['2026-01-28', '2026-01-29', '2026-01-30', '2026-01-31']
        },
        latestShowTourPosition: {
            showNumber: 1,
            totalShows: 4,
            tourName: NEW_TOUR_NAME,
            tourYear: '2026'
        }
    },
    showDurationAvailability: [{
        date: FIRST_SHOW_DATE,
        venue: VENUE,
        city: CITY,
        state: STATE,
        durationsAvailable: true
    }]
};

fs.writeFileSync(statsPath, JSON.stringify(mockStats, null, 2));
console.log('📄 Created mock tour-stats.json');

// =============================================================================
// Step 6: Validation
// =============================================================================

console.log('\n🔍 VALIDATION CHECKS:');

const validations = [
    {
        name: 'currentTour.name === "2026 Mexico"',
        check: () => {
            const data = JSON.parse(fs.readFileSync(dashboardPath, 'utf8'));
            return data.currentTour.name === NEW_TOUR_NAME;
        }
    },
    {
        name: 'currentTour.playedShows === 1',
        check: () => {
            const data = JSON.parse(fs.readFileSync(dashboardPath, 'utf8'));
            return data.currentTour.playedShows === 1;
        }
    },
    {
        name: 'latestShow.date === "2026-01-28"',
        check: () => {
            const data = JSON.parse(fs.readFileSync(dashboardPath, 'utf8'));
            return data.latestShow.date === FIRST_SHOW_DATE;
        }
    },
    {
        name: 'latestShow.tourPosition.tourName === "2026 Mexico"',
        check: () => {
            const data = JSON.parse(fs.readFileSync(dashboardPath, 'utf8'));
            return data.latestShow.tourPosition.tourName === NEW_TOUR_NAME;
        }
    },
    {
        name: 'futureTours[0].name === "2026 Sphere"',
        check: () => {
            const data = JSON.parse(fs.readFileSync(dashboardPath, 'utf8'));
            return data.futureTours[0]?.name === '2026 Sphere';
        }
    },
    {
        name: 'Show file exists and is valid JSON',
        check: () => {
            if (!fs.existsSync(showFilePath)) return false;
            try {
                const data = JSON.parse(fs.readFileSync(showFilePath, 'utf8'));
                return data.showDate === FIRST_SHOW_DATE;
            } catch {
                return false;
            }
        }
    },
    {
        name: 'tour-stats.json references new tour',
        check: () => {
            const data = JSON.parse(fs.readFileSync(statsPath, 'utf8'));
            return data.tourName === NEW_TOUR_NAME;
        }
    }
];

let allPassed = true;
validations.forEach(v => {
    const passed = v.check();
    console.log(`   ${passed ? '✓' : '✗'} ${v.name}`);
    if (!passed) allPassed = false;
});

console.log('');
if (allPassed) {
    console.log('✅ SIMULATION COMPLETE - All validations passed!');
    console.log('');
    console.log('Next steps:');
    console.log('   1. Run: npm run deploy');
    console.log('   2. Test on your physical device');
    console.log('   3. Run: npm run prod-mode (to restore)');
    console.log('   4. Run: npm run deploy (to restore production)');
} else {
    console.log('❌ SIMULATION FAILED - Some validations did not pass');
    process.exit(1);
}

// =============================================================================
// Helper Functions
// =============================================================================

function createMockSetlist() {
    const baseDate = FIRST_SHOW_DATE;
    const permalink = `https://phish.net/setlists/phish-january-28-2026-moon-palace-cancun-mexico.html`;

    // Realistic Mexico setlist based on historical patterns
    const songs = [
        // Set 1
        { song: 'Buried Alive', slug: 'buried-alive', songid: 96, set: '1', position: 1, trans_mark: ' > ', gap: 5 },
        { song: 'AC/DC Bag', slug: 'acdc-bag', songid: 8, set: '1', position: 2, trans_mark: ', ', gap: 6 },
        { song: 'Moma Dance', slug: 'the-moma-dance', songid: 349, set: '1', position: 3, trans_mark: ', ', gap: 3 },
        { song: 'Tube', slug: 'tube', songid: 650, set: '1', position: 4, trans_mark: ', ', gap: 8 },
        { song: 'Blaze On', slug: 'blaze-on', songid: 2359, set: '1', position: 5, trans_mark: ', ', gap: 2 },
        { song: 'Horn', slug: 'horn', songid: 274, set: '1', position: 6, trans_mark: ' > ', gap: 12 },
        { song: 'Rift', slug: 'rift', songid: 462, set: '1', position: 7, trans_mark: ', ', gap: 4 },
        { song: 'Stash', slug: 'stash', songid: 536, set: '1', position: 8, trans_mark: ' > ', gap: 7 },
        { song: 'Possum', slug: 'possum', songid: 439, set: '1', position: 9, trans_mark: '', gap: 5 },
        { song: 'Run Like an Antelope', slug: 'run-like-an-antelope', songid: 478, set: '1', position: 10, trans_mark: '', gap: 6 },
        // Set 2
        { song: 'Down with Disease', slug: 'down-with-disease', songid: 174, set: '2', position: 11, trans_mark: ' -> ', gap: 4 },
        { song: 'Light', slug: 'light', songid: 1908, set: '2', position: 12, trans_mark: ' > ', gap: 3 },
        { song: 'Tweezer', slug: 'tweezer', songid: 646, set: '2', position: 13, trans_mark: ' -> ', gap: 5 },
        { song: 'Ghost', slug: 'ghost', songid: 231, set: '2', position: 14, trans_mark: ' > ', gap: 8 },
        { song: 'Theme from the Bottom', slug: 'theme-from-the-bottom', songid: 609, set: '2', position: 15, trans_mark: ' > ', gap: 7 },
        { song: 'Piper', slug: 'piper', songid: 430, set: '2', position: 16, trans_mark: ' > ', gap: 9 },
        { song: "Slave to the Traffic Light", slug: 'slave-to-the-traffic-light', songid: 512, set: '2', position: 17, trans_mark: '', gap: 5 },
        // Encore
        { song: 'Character Zero', slug: 'character-zero', songid: 127, set: 'e', position: 18, trans_mark: '', gap: 4 }
    ];

    return songs.map(s => ({
        showid: 99999999,
        showdate: baseDate,
        permalink: permalink,
        showyear: '2026',
        uniqueid: 900000 + s.position,
        meta: '',
        reviews: 0,
        exclude: 0,
        setlistnotes: '',
        soundcheck: '',
        songid: s.songid,
        position: s.position,
        transition: s.trans_mark === ' > ' ? 2 : s.trans_mark === ' -> ' ? 3 : s.trans_mark === ', ' ? 1 : 4,
        footnote: '',
        set: s.set,
        isjam: 0,
        isreprise: 0,
        isjamchart: 0,
        jamchart_description: '',
        tracktime: '',
        gap: s.gap,
        tourid: 999,
        tourname: NEW_TOUR_NAME,
        tourwhen: '2026 Mexico',
        song: s.song,
        nickname: s.song,
        slug: s.slug,
        is_original: 1,
        venueid: 9999,
        venue: VENUE,
        city: CITY,
        state: STATE,
        country: COUNTRY,
        trans_mark: s.trans_mark,
        artistid: 1,
        artist_slug: 'phish',
        artist_name: 'Phish',
        footnoteIndices: []
    }));
}

function createMockDurations() {
    // Realistic durations in seconds
    const durations = [
        { song: 'Buried Alive', duration: 245, set: 'Set 1' },
        { song: 'AC/DC Bag', duration: 612, set: 'Set 1' },
        { song: 'Moma Dance', duration: 485, set: 'Set 1' },
        { song: 'Tube', duration: 398, set: 'Set 1' },
        { song: 'Blaze On', duration: 542, set: 'Set 1' },
        { song: 'Horn', duration: 312, set: 'Set 1' },
        { song: 'Rift', duration: 387, set: 'Set 1' },
        { song: 'Stash', duration: 956, set: 'Set 1' },
        { song: 'Possum', duration: 723, set: 'Set 1' },
        { song: 'Run Like an Antelope', duration: 845, set: 'Set 1' },
        { song: 'Down with Disease', duration: 1124, set: 'Set 2' },
        { song: 'Light', duration: 987, set: 'Set 2' },
        { song: 'Tweezer', duration: 1456, set: 'Set 2' },
        { song: 'Ghost', duration: 876, set: 'Set 2' },
        { song: 'Theme from the Bottom', duration: 1234, set: 'Set 2' },
        { song: 'Piper', duration: 1089, set: 'Set 2' },
        { song: "Slave to the Traffic Light", duration: 654, set: 'Set 2' },
        { song: 'Character Zero', duration: 398, set: 'Encore' }
    ];

    return durations.map((d, i) => ({
        id: String(50000 + i),
        songName: d.song,
        songId: null,
        durationSeconds: d.duration,
        showDate: FIRST_SHOW_DATE,
        setNumber: d.set,
        venue: VENUE,
        venueRun: null
    }));
}

function createMockSongGaps() {
    const songs = [
        { songId: 96, songName: 'Buried Alive', gap: 5 },
        { songId: 8, songName: 'AC/DC Bag', gap: 6 },
        { songId: 349, songName: 'Moma Dance', gap: 3 },
        { songId: 650, songName: 'Tube', gap: 8 },
        { songId: 2359, songName: 'Blaze On', gap: 2 },
        { songId: 274, songName: 'Horn', gap: 12 },
        { songId: 462, songName: 'Rift', gap: 4 },
        { songId: 536, songName: 'Stash', gap: 7 },
        { songId: 439, songName: 'Possum', gap: 5 },
        { songId: 478, songName: 'Run Like an Antelope', gap: 6 },
        { songId: 174, songName: 'Down with Disease', gap: 4 },
        { songId: 1908, songName: 'Light', gap: 3 },
        { songId: 646, songName: 'Tweezer', gap: 5 },
        { songId: 231, songName: 'Ghost', gap: 8 },
        { songId: 609, songName: 'Theme from the Bottom', gap: 7 },
        { songId: 430, songName: 'Piper', gap: 9 },
        { songId: 512, songName: "Slave to the Traffic Light", gap: 5 },
        { songId: 127, songName: 'Character Zero', gap: 4 }
    ];

    return songs.map(s => ({
        songId: s.songId,
        songName: s.songName,
        gap: s.gap,
        lastPlayed: '',
        timesPlayed: 0,
        tourVenue: null,
        tourVenueRun: null,
        tourDate: FIRST_SHOW_DATE,
        historicalVenue: null,
        historicalCity: null,
        historicalState: null,
        historicalLastPlayed: null
    }));
}

function createMockLongestSongs() {
    const venueRunData = {
        venue: VENUE,
        city: CITY,
        state: STATE,
        nightNumber: 1,
        totalNights: 4,
        showDates: ['2026-01-28', '2026-01-29', '2026-01-30', '2026-01-31']
    };
    const tourPositionData = {
        showNumber: 1,
        totalShows: 4,
        tourName: NEW_TOUR_NAME,
        tourYear: '2026'
    };
    return [
        {
            id: '60001',
            songName: 'Tweezer',
            songId: 646,
            durationSeconds: 1456,
            showDate: FIRST_SHOW_DATE,
            setNumber: 'Set 2',
            venue: VENUE,
            venueRun: venueRunData,
            city: CITY,
            state: STATE,
            tourPosition: tourPositionData,
            formattedDuration: '24:16'
        },
        {
            id: '60002',
            songName: 'Theme from the Bottom',
            songId: 609,
            durationSeconds: 1234,
            showDate: FIRST_SHOW_DATE,
            setNumber: 'Set 2',
            venue: VENUE,
            venueRun: venueRunData,
            city: CITY,
            state: STATE,
            tourPosition: tourPositionData,
            formattedDuration: '20:34'
        },
        {
            id: '60003',
            songName: 'Down with Disease',
            songId: 174,
            durationSeconds: 1124,
            showDate: FIRST_SHOW_DATE,
            setNumber: 'Set 2',
            venue: VENUE,
            venueRun: venueRunData,
            city: CITY,
            state: STATE,
            tourPosition: tourPositionData,
            formattedDuration: '18:44'
        },
        {
            id: '60004',
            songName: 'Piper',
            songId: 430,
            durationSeconds: 1089,
            showDate: FIRST_SHOW_DATE,
            setNumber: 'Set 2',
            venue: VENUE,
            venueRun: venueRunData,
            city: CITY,
            state: STATE,
            tourPosition: tourPositionData,
            formattedDuration: '18:09'
        },
        {
            id: '60005',
            songName: 'Light',
            songId: 1908,
            durationSeconds: 987,
            showDate: FIRST_SHOW_DATE,
            setNumber: 'Set 2',
            venue: VENUE,
            venueRun: venueRunData,
            city: CITY,
            state: STATE,
            tourPosition: tourPositionData,
            formattedDuration: '16:27'
        }
    ];
}

function createMockRarestSongs() {
    const tourPositionData = {
        showNumber: 1,
        totalShows: 4,
        tourName: NEW_TOUR_NAME,
        tourYear: '2026'
    };
    return [
        {
            id: 274,
            songId: 274,
            songName: 'Horn',
            gap: 12,
            lastPlayed: '2025-12-29',
            timesPlayed: 287,
            tourVenue: VENUE,
            tourVenueRun: null,
            tourDate: FIRST_SHOW_DATE,
            tourCity: CITY,
            tourState: STATE,
            tourPosition: tourPositionData,
            historicalVenue: 'Madison Square Garden',
            historicalCity: 'New York',
            historicalState: 'NY',
            historicalLastPlayed: '2025-12-29'
        },
        {
            id: 430,
            songId: 430,
            songName: 'Piper',
            gap: 9,
            lastPlayed: '2025-12-30',
            timesPlayed: 412,
            tourVenue: VENUE,
            tourVenueRun: null,
            tourDate: FIRST_SHOW_DATE,
            tourCity: CITY,
            tourState: STATE,
            tourPosition: tourPositionData,
            historicalVenue: 'Madison Square Garden',
            historicalCity: 'New York',
            historicalState: 'NY',
            historicalLastPlayed: '2025-12-30'
        },
        {
            id: 650,
            songId: 650,
            songName: 'Tube',
            gap: 8,
            lastPlayed: '2025-12-31',
            timesPlayed: 356,
            tourVenue: VENUE,
            tourVenueRun: null,
            tourDate: FIRST_SHOW_DATE,
            tourCity: CITY,
            tourState: STATE,
            tourPosition: tourPositionData,
            historicalVenue: 'Madison Square Garden',
            historicalCity: 'New York',
            historicalState: 'NY',
            historicalLastPlayed: '2025-12-31'
        },
        {
            id: 231,
            songId: 231,
            songName: 'Ghost',
            gap: 8,
            lastPlayed: '2025-12-31',
            timesPlayed: 478,
            tourVenue: VENUE,
            tourVenueRun: null,
            tourDate: FIRST_SHOW_DATE,
            tourCity: CITY,
            tourState: STATE,
            tourPosition: tourPositionData,
            historicalVenue: 'Madison Square Garden',
            historicalCity: 'New York',
            historicalState: 'NY',
            historicalLastPlayed: '2025-12-31'
        },
        {
            id: 536,
            songId: 536,
            songName: 'Stash',
            gap: 7,
            lastPlayed: '2025-12-30',
            timesPlayed: 523,
            tourVenue: VENUE,
            tourVenueRun: null,
            tourDate: FIRST_SHOW_DATE,
            tourCity: CITY,
            tourState: STATE,
            tourPosition: tourPositionData,
            historicalVenue: 'Madison Square Garden',
            historicalCity: 'New York',
            historicalState: 'NY',
            historicalLastPlayed: '2025-12-30'
        }
    ];
}

function createMockMostPlayed() {
    // With only 1 show, all songs are played once
    return [
        { id: 96, songId: 96, songName: 'Buried Alive', playCount: 1 },
        { id: 8, songId: 8, songName: 'AC/DC Bag', playCount: 1 },
        { id: 349, songId: 349, songName: 'Moma Dance', playCount: 1 },
        { id: 650, songId: 650, songName: 'Tube', playCount: 1 },
        { id: 2359, songId: 2359, songName: 'Blaze On', playCount: 1 }
    ];
}

function createMockBiggestGaps() {
    return [
        {
            song: 'Horn',
            gap: 12,
            showDate: FIRST_SHOW_DATE,
            venue: VENUE,
            city: CITY,
            state: STATE,
            historicalLastPlayed: '2025-12-29'
        },
        {
            song: 'Piper',
            gap: 9,
            showDate: FIRST_SHOW_DATE,
            venue: VENUE,
            city: CITY,
            state: STATE,
            historicalLastPlayed: '2025-12-30'
        },
        {
            song: 'Tube',
            gap: 8,
            showDate: FIRST_SHOW_DATE,
            venue: VENUE,
            city: CITY,
            state: STATE,
            historicalLastPlayed: '2025-12-31'
        }
    ];
}
