/**
 * Phish.net API Explorer
 *
 * Generic utility for exploring Phish.net API endpoints and data structures.
 * Useful for discovering new endpoints, understanding data formats, and testing API responses.
 *
 * Usage Examples:
 * - Explore songs database: node tools/phish-net-explorer.js --endpoint songs
 * - Test specific show: node tools/phish-net-explorer.js --endpoint shows --year 2025
 * - Custom exploration: Edit the exploreFunctions object below
 */

// Load environment variables from .env file (development only)
import dotenv from 'dotenv';
dotenv.config();

const API_KEY = process.env.PHISH_NET_API_KEY || '4771B8589CD3E53848E7'; // Fallback for development
const BASE_URL = 'https://api.phish.net/v5';

/**
 * Generic API fetch utility
 */
async function fetchPhishNetData(endpoint, params = {}) {
    const queryParams = new URLSearchParams({ apikey: API_KEY, ...params });
    const url = `${BASE_URL}${endpoint}?${queryParams}`;

    console.log(`🔍 Fetching: ${endpoint}`);
    console.log(`   URL: ${url.replace(API_KEY, '***')}`);

    try {
        const response = await fetch(url);
        console.log(`   Status: ${response.status}`);

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        return data;
    } catch (error) {
        console.error(`   ❌ Error: ${error.message}`);
        return null;
    }
}

/**
 * Phish song filtering utility (reusable)
 */
function filterPhishPerformedSongs(allSongs) {
    const sideProjectArtists = [
        'Trey Anastasio', 'Mike Gordon', 'Page Mcconnell', 'Page McConnell',
        'Leo Kotke/Mike Gordon', 'Mike Gordon and Leo Kottke',
        'Trey, Mike, and The Benevento/Russo Duo', 'Trey Anastasio & Don Hart'
    ];

    return allSongs.filter(song =>
        song.times_played > 0 &&
        !sideProjectArtists.includes(song.artist)
    );
}

/**
 * Data analysis utilities
 */
const analysisUtils = {
    /**
     * Analyze song play count distribution
     */
    analyzeSongDistribution(songs) {
        const playCountRanges = [
            { min: 0, max: 10, label: '1-10 plays' },
            { min: 11, max: 50, label: '11-50 plays' },
            { min: 51, max: 100, label: '51-100 plays' },
            { min: 101, max: 200, label: '101-200 plays' },
            { min: 201, max: 500, label: '201-500 plays' },
            { min: 501, max: Infinity, label: '500+ plays' }
        ];

        console.log('\n📊 Song Play Count Distribution:');
        playCountRanges.forEach(range => {
            const count = songs.filter(song =>
                song.times_played >= range.min && song.times_played <= range.max
            ).length;
            console.log(`   ${range.label}: ${count} songs`);
        });
    },

    /**
     * Find songs matching criteria
     */
    findSongs(songs, criteria) {
        return songs.filter(song => {
            if (criteria.minPlays && song.times_played < criteria.minPlays) return false;
            if (criteria.maxPlays && song.times_played > criteria.maxPlays) return false;
            if (criteria.nameContains && !song.song.toLowerCase().includes(criteria.nameContains.toLowerCase())) return false;
            if (criteria.artist && song.artist !== criteria.artist) return false;
            return true;
        });
    },

    /**
     * Show top N songs by play count
     */
    showTopSongs(songs, limit = 10, title = 'Top Songs') {
        const topSongs = songs
            .sort((a, b) => b.times_played - a.times_played)
            .slice(0, limit);

        console.log(`\n🏆 ${title} (Top ${limit}):`);
        topSongs.forEach((song, index) => {
            console.log(`   ${index + 1}. ${song.song}: ${song.times_played} times (${song.artist})`);
        });
    }
};

/**
 * Exploration functions for different endpoints
 */
const exploreFunctions = {

    /**
     * Explore songs database
     */
    async songs() {
        const data = await fetchPhishNetData('/songs.json');
        if (!data || !data.data) return;

        console.log(`\n📋 Songs Database Analysis:`);
        console.log(`   Total songs: ${data.data.length}`);

        // Filter to Phish-performed songs
        const phishSongs = filterPhishPerformedSongs(data.data);
        console.log(`   Phish-performed songs: ${phishSongs.length}`);

        // Show distribution
        analysisUtils.analyzeSongDistribution(phishSongs);

        // Show top songs
        analysisUtils.showTopSongs(phishSongs, 20);

        // Show some covers
        const covers = phishSongs.filter(song => song.artist !== 'Phish').slice(0, 10);
        console.log(`\n🎸 Sample Covers Performed by Phish:`);
        covers.forEach(song => {
            console.log(`   ${song.song} (Original: ${song.artist}, ${song.times_played} times)`);
        });

        return phishSongs;
    },

    /**
     * Explore shows for a specific year
     */
    async shows(year = '2025') {
        const data = await fetchPhishNetData('/shows/showyear.json', { year });
        if (!data || !data.data) return;

        console.log(`\n📅 Shows for ${year}:`);
        console.log(`   Total shows: ${data.data.length}`);

        // Filter to Phish shows
        const phishShows = data.data.filter(show =>
            show.artist_name && show.artist_name.toLowerCase().includes('phish')
        );
        console.log(`   Phish shows: ${phishShows.length}`);

        // Show tours
        const tours = [...new Set(phishShows.map(show => show.tourname))].filter(Boolean);
        console.log(`   Tours: ${tours.join(', ')}`);

        // Show recent shows
        const recentShows = phishShows
            .sort((a, b) => b.showdate.localeCompare(a.showdate))
            .slice(0, 10);

        console.log(`\n🎪 Recent Shows:`);
        recentShows.forEach(show => {
            console.log(`   ${show.showdate}: ${show.venue || 'Unknown'} (${show.tourname || 'No tour'})`);
        });

        return phishShows;
    },

    /**
     * Test endpoint discovery
     */
    async discover() {
        const endpoints = [
            '/songs.json',
            '/songs/stats.json',
            '/songs/popular.json',
            '/artists.json',
            '/venues.json',
            '/tours.json',
            '/stats.json'
        ];

        console.log(`\n🔍 Endpoint Discovery:`);
        for (const endpoint of endpoints) {
            const data = await fetchPhishNetData(endpoint);
            const status = data ? '✅ Works' : '❌ Failed';
            console.log(`   ${endpoint}: ${status}`);

            if (data && data.data) {
                const dataType = Array.isArray(data.data) ? 'Array' : typeof data.data;
                const count = Array.isArray(data.data) ? data.data.length : 'N/A';
                console.log(`      Type: ${dataType}, Count: ${count}`);
            }
        }
    },

    /**
     * Custom exploration function - edit as needed
     */
    async custom() {
        console.log(`\n🛠️  Custom Exploration:`);

        // Example: Find all songs with "jam" in the name
        const songsData = await fetchPhishNetData('/songs.json');
        if (songsData && songsData.data) {
            const jamSongs = analysisUtils.findSongs(songsData.data, {
                nameContains: 'jam',
                minPlays: 1
            });

            console.log(`\n🎵 Songs with "jam" in name:`);
            jamSongs.forEach(song => {
                console.log(`   ${song.song}: ${song.times_played} times`);
            });
        }
    }
};

/**
 * Main exploration function
 */
async function explore() {
    const args = process.argv.slice(2);
    const endpoint = args.find(arg => arg.startsWith('--endpoint='))?.split('=')[1] ||
                     (args.includes('--endpoint') ? args[args.indexOf('--endpoint') + 1] : 'songs');
    const year = args.find(arg => arg.startsWith('--year='))?.split('=')[1] ||
                 (args.includes('--year') ? args[args.indexOf('--year') + 1] : '2025');

    console.log('🚀 Phish.net API Explorer');
    console.log(`   Exploring: ${endpoint}`);

    if (exploreFunctions[endpoint]) {
        await exploreFunctions[endpoint](year);
    } else {
        console.log(`❌ Unknown endpoint: ${endpoint}`);
        console.log(`Available endpoints: ${Object.keys(exploreFunctions).join(', ')}`);
    }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    explore().then(() => {
        console.log('\n🏁 Exploration complete!');
        process.exit(0);
    }).catch(error => {
        console.error('💥 Exploration failed:', error);
        process.exit(1);
    });
}

// Export for use in other scripts
export { fetchPhishNetData, filterPhishPerformedSongs, analysisUtils, exploreFunctions };