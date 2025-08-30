/**
 * PhishQS Tour Statistics Calculation Engine
 * 
 * Shared JavaScript implementation for tour statistics calculations
 * Used by both Node.js server and iOS JavaScriptCore
 * 
 * Ports the exact logic from iOS TourStatisticsService.swift to ensure
 * perfect calculation consistency across platforms.
 */

/**
 * Calculate tour-progressive rarest songs (tracks top 3 across entire tour)
 * 
 * This is the core algorithm that mirrors iOS TourStatisticsService.calculateTourProgressiveRarestSongs
 * exactly. It processes all shows chronologically and tracks the highest gap for each song.
 * 
 * @param {Array} tourShows - All enhanced setlists from tour (chronological order)
 * @param {string} tourName - Name of the tour for logging context
 * @returns {Array} Top 3 rarest songs with gap info
 */
function calculateTourProgressiveRarestSongs(tourShows, tourName) {
    console.log(`🎯 Calculating progressive rarest songs across ${tourShows.length} shows`);
    
    // Validate input
    if (!Array.isArray(tourShows) || tourShows.length === 0) {
        console.log('⚠️ No tour shows provided for rarest song calculation');
        return [];
    }
    
    // Collect all unique songs and their gaps across the tour
    const tourSongGaps = new Map();
    
    tourShows.forEach((show, showIndex) => {
        console.log(`   Processing show ${showIndex + 1}: ${show.showDate}`);
        
        if (!show.songGaps || !Array.isArray(show.songGaps)) {
            console.log(`   ⚠️ No song gaps data for ${show.showDate}`);
            return;
        }
        
        show.songGaps.forEach(gapInfo => {
            if (!gapInfo.songName || typeof gapInfo.gap !== 'number' || gapInfo.gap < 0) {
                console.log(`   ⚠️ Invalid gap info for song in ${show.showDate}`);
                return;
            }
            
            const songKey = gapInfo.songName.toLowerCase();
            const existingGap = tourSongGaps.get(songKey);
            
            // For each song, keep the occurrence with the HIGHEST gap
            if (!existingGap || gapInfo.gap > existingGap.gap) {
                if (existingGap) {
                    console.log(`      🔄 Updating ${gapInfo.songName}: ${existingGap.gap} → ${gapInfo.gap}`);
                } else {
                    console.log(`      ➕ Adding ${gapInfo.songName}: Gap ${gapInfo.gap}`);
                }
                
                // Store enhanced gap info with tour context
                // IMPORTANT: Following API usage principle - venue data comes from Phish.net only
                // show.venue comes from Phish.net SetlistItem data, ensuring venue-date consistency
                tourSongGaps.set(songKey, {
                    songName: gapInfo.songName,
                    gap: gapInfo.gap,
                    lastPlayed: gapInfo.lastPlayed || null,
                    tourDate: show.showDate, // Always use Phish.net show date
                    tourVenue: show.venue || 'Unknown Venue', // Always use Phish.net venue from SetlistItem
                    timesPlayed: gapInfo.timesPlayed || 100, // Default value like iOS
                    // Preserve historical data if available
                    historicalVenue: gapInfo.historicalVenue || null,
                    historicalCity: gapInfo.historicalCity || null,
                    historicalState: gapInfo.historicalState || null,
                    historicalLastPlayed: gapInfo.historicalLastPlayed || gapInfo.lastPlayed
                });
            } else {
                console.log(`      ✓ Keeping ${gapInfo.songName}: ${existingGap.gap} > ${gapInfo.gap}`);
            }
        });
    });
    
    // Debug: Show all songs with gaps > 200 for validation
    const allSongs = Array.from(tourSongGaps.values());
    const highGapSongs = allSongs
        .filter(song => song.gap > 200)
        .sort((a, b) => b.gap - a.gap);
    
    if (highGapSongs.length > 0) {
        console.log('   🔍 All songs with gap > 200:');
        highGapSongs.slice(0, 10).forEach(song => {
            console.log(`      • ${song.songName}: ${song.gap} gap (from ${song.tourDate})`);
        });
    }
    
    // Get top 3 by gap size
    const topRarestSongs = allSongs
        .sort((a, b) => b.gap - a.gap)
        .slice(0, 3);
    
    console.log('   📊 Top 3 rarest across tour:');
    topRarestSongs.forEach((song, index) => {
        console.log(`      ${index + 1}. ${song.songName} - Gap: ${song.gap} (from ${song.tourDate})`);
    });
    
    return topRarestSongs;
}

/**
 * Calculate top 3 longest songs from track durations
 * 
 * Mirrors iOS TourStatisticsService.calculateLongestSongs exactly
 * 
 * @param {Array} trackDurations - Array of track duration objects
 * @returns {Array} Top 3 longest songs sorted by duration
 */
function calculateLongestSongs(trackDurations) {
    console.log(`🎵 Calculating longest songs from ${trackDurations.length} tracks`);
    
    // Validate input
    if (!Array.isArray(trackDurations) || trackDurations.length === 0) {
        console.log('⚠️ No track durations provided for longest song calculation');
        return [];
    }
    
    // Filter out tracks with invalid durations and sort by duration (highest first)
    const validTracks = trackDurations
        .filter(track => {
            return track && 
                   typeof track.durationSeconds === 'number' && 
                   track.durationSeconds > 0 &&
                   track.songName;
        })
        .sort((a, b) => b.durationSeconds - a.durationSeconds);
    
    // Get top 3
    const longestSongs = validTracks.slice(0, 3);
    
    console.log('🏆 Top 3 longest songs calculated:');
    longestSongs.forEach((song, index) => {
        const duration = formatDuration(song.durationSeconds);
        console.log(`   ${index + 1}. ${song.songName} - ${duration} (${song.showDate})`);
    });
    
    return longestSongs;
}

/**
 * Determine current tour context from latest show
 * 
 * @param {Object} latestShow - Latest show object with date and tour info
 * @returns {Object} Tour context information
 */
function getCurrentTourContext(latestShow) {
    if (!latestShow || !latestShow.showDate) {
        return {
            tourName: null,
            isActiveTour: false,
            showDate: null
        };
    }
    
    return {
        tourName: latestShow.tourName || extractTourFromDate(latestShow.showDate),
        isActiveTour: isCurrentTour(latestShow.showDate),
        showDate: latestShow.showDate
    };
}

/**
 * Validate tour data format before processing
 * 
 * @param {Object} tourData - Tour data to validate
 * @returns {Object} Validation result with status and errors
 */
function validateTourData(tourData) {
    const errors = [];
    
    if (!tourData) {
        errors.push('Tour data is null or undefined');
        return { isValid: false, errors };
    }
    
    if (!tourData.tourShows || !Array.isArray(tourData.tourShows)) {
        errors.push('Tour shows must be an array');
    }
    
    if (tourData.tourShows && tourData.tourShows.length === 0) {
        errors.push('Tour shows array is empty');
    }
    
    // Validate individual shows
    if (Array.isArray(tourData.tourShows)) {
        tourData.tourShows.forEach((show, index) => {
            if (!show.showDate) {
                errors.push(`Show ${index + 1} missing showDate`);
            }
            
            if (!show.songGaps && !show.trackDurations) {
                errors.push(`Show ${index + 1} (${show.showDate}) has no song data`);
            }
        });
    }
    
    return {
        isValid: errors.length === 0,
        errors: errors
    };
}

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

/**
 * Sort songs by duration (descending)
 * 
 * @param {Array} songs - Array of song objects with durationSeconds
 * @returns {Array} Sorted songs array
 */
function sortSongsByDuration(songs) {
    return songs.sort((a, b) => {
        const aDuration = a.durationSeconds || 0;
        const bDuration = b.durationSeconds || 0;
        return bDuration - aDuration;
    });
}

/**
 * Sort songs by gap size (descending)
 * 
 * @param {Array} songs - Array of song objects with gap property
 * @returns {Array} Sorted songs array
 */
function sortSongsByGap(songs) {
    return songs.sort((a, b) => {
        const aGap = a.gap || 0;
        const bGap = b.gap || 0;
        return bGap - aGap;
    });
}

/**
 * Format duration in seconds to MM:SS format
 * 
 * @param {number} seconds - Duration in seconds
 * @returns {string} Formatted duration string
 */
function formatDuration(seconds) {
    if (typeof seconds !== 'number' || seconds < 0) {
        return '0:00';
    }
    
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}

/**
 * Extract likely tour name from show date
 * Simple heuristic for tour season detection
 * 
 * @param {string} showDate - Show date in YYYY-MM-DD format
 * @returns {string} Likely tour name
 */
function extractTourFromDate(showDate) {
    if (!showDate || typeof showDate !== 'string') {
        return 'Unknown Tour';
    }
    
    const year = showDate.substring(0, 4);
    const month = parseInt(showDate.substring(5, 7));
    
    // Simple season detection
    if (month >= 6 && month <= 8) {
        return `Summer Tour ${year}`;
    } else if (month >= 9 && month <= 11) {
        return `Fall Tour ${year}`;
    } else if (month >= 12 || month <= 2) {
        return `Winter Tour ${year}`;
    } else {
        return `Spring Tour ${year}`;
    }
}

/**
 * Determine if a show date represents a current/active tour
 * 
 * @param {string} showDate - Show date in YYYY-MM-DD format
 * @returns {boolean} True if show is from current tour
 */
function isCurrentTour(showDate) {
    if (!showDate) return false;
    
    const showTime = new Date(showDate).getTime();
    const now = new Date().getTime();
    const sixMonthsAgo = now - (6 * 30 * 24 * 60 * 60 * 1000); // Rough 6 months
    
    // Consider a tour "current" if the latest show was within 6 months
    return showTime >= sixMonthsAgo;
}

// =============================================================================
// KNOWN RAREST SONGS DATA (for validation and fallback)
// =============================================================================

/**
 * Known accurate rarest songs data based on manual research
 * Used for validation and as fallback when gap calculation fails
 */
const KNOWN_RAREST_SONGS = [
    {
        songName: "On Your Way Down",
        gap: 522,
        lastPlayed: "2011-08-06",
        historicalVenue: "Gorge Amphitheatre",
        historicalCity: "George", 
        historicalState: "WA"
    },
    {
        songName: "Paul and Silas",
        gap: 323,
        lastPlayed: "2016-07-22",
        historicalVenue: "Albany Medical Center Arena",
        historicalCity: "Albany",
        historicalState: "NY"
    },
    {
        songName: "Devotion To a Dream", 
        gap: 322,
        lastPlayed: "2016-10-15",
        historicalVenue: "North Charleston Coliseum",
        historicalCity: "North Charleston",
        historicalState: "SC"
    }
];

/**
 * Get known rarest songs with enhanced historical data
 * 
 * @returns {Array} Known rarest songs with historical context
 */
function getKnownRarestSongs() {
    return KNOWN_RAREST_SONGS.map(song => ({
        ...song,
        timesPlayed: 100, // Default like iOS implementation
        tourDate: null,   // Will be filled by tour processing
        tourVenue: null   // Will be filled by tour processing
    }));
}

// =============================================================================
// MODULE EXPORTS (Node.js compatible)
// =============================================================================

// Support both CommonJS (Node.js) and global scope (iOS JavaScriptCore)
if (typeof module !== 'undefined' && module.exports) {
    // Node.js environment
    module.exports = {
        calculateTourProgressiveRarestSongs,
        calculateLongestSongs,
        getCurrentTourContext,
        validateTourData,
        sortSongsByDuration,
        sortSongsByGap,
        formatDuration,
        extractTourFromDate,
        isCurrentTour,
        getKnownRarestSongs
    };
} else {
    // Browser/JavaScriptCore environment - attach to global scope
    if (typeof globalThis !== 'undefined') {
        globalThis.tourCalculations = {
            calculateTourProgressiveRarestSongs,
            calculateLongestSongs,
            getCurrentTourContext,
            validateTourData,
            sortSongsByDuration,
            sortSongsByGap,
            formatDuration,
            extractTourFromDate,
            isCurrentTour,
            getKnownRarestSongs
        };
    }
}