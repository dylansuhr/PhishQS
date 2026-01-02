/**
 * TourStatistics.js
 * Server-side models for tour statistics data
 * Mirrors iOS SharedModels.swift structure
 */

/**
 * Most played song information for tour statistics
 * Mirrors Swift MostPlayedSong struct
 */
export class MostPlayedSong {
    constructor(songId, songName, playCount) {
        this.id = songId;
        this.songId = songId;
        this.songName = songName;
        this.playCount = playCount;
    }
}

/**
 * Most common song not played information for tour statistics
 * Represents popular songs from Phish history that haven't been played on current tour
 * Mirrors Swift MostCommonSongNotPlayed struct
 */
export class MostCommonSongNotPlayed {
    constructor(songId, songName, historicalPlayCount, originalArtist = null) {
        this.id = songId;
        this.songId = songId;
        this.songName = songName;
        this.historicalPlayCount = historicalPlayCount;
        this.originalArtist = originalArtist;
    }

    /**
     * Get display text showing if this is a cover song
     * @returns {string} Display text for song type
     */
    get songTypeDisplay() {
        if (this.originalArtist && this.originalArtist !== 'Phish') {
            return `Cover (${this.originalArtist})`;
        }
        return 'Original';
    }
}

/**
 * Track duration information with venue context
 * Mirrors Swift TrackDuration struct
 */
export class TrackDuration {
    constructor(id, songName, songId, durationSeconds, showDate, setNumber, venue, venueRun = null, options = {}) {
        this.id = id;
        this.songName = songName;
        this.songId = songId;
        this.durationSeconds = durationSeconds;
        this.showDate = showDate;
        this.setNumber = setNumber;
        this.venue = venue;
        this.venueRun = venueRun;
        
        // Tour context fields
        this.city = options.city || null;
        this.state = options.state || null;
        this.tourPosition = options.tourPosition || null;
        
        // Pre-computed formatted duration for JSON serialization
        this.formattedDuration = this.formatDuration(durationSeconds);
    }
    
    /**
     * Format duration from seconds to MM:SS format
     * @param {number} seconds - Duration in seconds
     * @returns {string} Formatted duration as MM:SS
     */
    formatDuration(seconds) {
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
    }
    
    
    get venueDisplayText() {
        if (!this.venue) return null;
        
        // If multi-night run, include night indicator
        if (this.venueRun && this.venueRun.totalNights > 1) {
            return `${this.venue}, N${this.venueRun.nightNumber}`;
        }
        
        // Single night, just venue name
        return this.venue;
    }
}

/**
 * Song gap information for rarest songs
 * Mirrors Swift SongGapInfo struct
 */
export class SongGapInfo {
    constructor(songId, songName, gap, lastPlayed, timesPlayed, options = {}) {
        this.id = songId;
        this.songId = songId;
        this.songName = songName;
        this.gap = gap;
        this.lastPlayed = lastPlayed || "";
        this.timesPlayed = timesPlayed || 0;
        this.tourVenue = options.tourVenue || null;
        this.tourVenueRun = options.tourVenueRun || null;
        this.tourDate = options.tourDate || null;
        
        // Tour context fields
        this.tourCity = options.tourCity || null;
        this.tourState = options.tourState || null;
        this.tourPosition = options.tourPosition || null;
        
        this.historicalVenue = options.historicalVenue || null;
        this.historicalCity = options.historicalCity || null;
        this.historicalState = options.historicalState || null;
        this.historicalLastPlayed = options.historicalLastPlayed || null;
        
        // Pre-computed formatted historical date for JSON serialization
        this.formattedHistoricalDate = this.formatDate(options.historicalLastPlayed);
    }
    
    /**
     * Format date from YYYY-MM-DD to M/d/yy format
     * @param {string} dateString - Date in YYYY-MM-DD format
     * @returns {string|null} Formatted date as M/d/yy or null if invalid
     */
    formatDate(dateString) {
        if (!dateString) return null;
        
        try {
            // Parse date string directly to avoid timezone issues
            const parts = dateString.split('-');
            if (parts.length !== 3) return null;
            
            const year = parseInt(parts[0]);
            const month = parseInt(parts[1]);
            const day = parseInt(parts[2]);
            
            if (isNaN(year) || isNaN(month) || isNaN(day)) return null;
            if (month < 1 || month > 12 || day < 1 || day > 31) return null;
            
            const shortYear = year.toString().slice(-2);
            return `${month}/${day}/${shortYear}`;
        } catch (error) {
            return null;
        }
    }
    
    get gapDisplayText() {
        if (this.gap === 0) {
            return "Most recent";
        } else if (this.gap === 1) {
            return "1 show ago";
        } else {
            return `${this.gap} shows ago`;
        }
    }
    
    get tourVenueDisplayText() {
        if (!this.tourVenue) return null;
        
        // If multi-night run, include night indicator
        if (this.tourVenueRun && this.tourVenueRun.totalNights > 1) {
            return `${this.tourVenue}, N${this.tourVenueRun.nightNumber}`;
        }
        
        // Single night, just venue name
        return this.tourVenue;
    }
}

/**
 * Venue run information for multi-night shows
 * Mirrors Swift VenueRun struct
 */
export class VenueRun {
    constructor(venue, city, state, nightNumber, totalNights, showDates) {
        this.venue = venue;
        this.city = city;
        this.state = state;
        this.nightNumber = nightNumber;
        this.totalNights = totalNights;
        this.showDates = showDates;
    }
    
    get runDisplayText() {
        if (this.totalNights > 1) {
            return `N${this.nightNumber}/${this.totalNights}`;
        }
        return "";
    }
}

/**
 * Combined tour statistics for display
 * Mirrors Swift TourSongStatistics struct
 */
export class TourSongStatistics {
    constructor(longestSongs, rarestSongs, mostPlayedSongs, tourName, mostCommonSongsNotPlayed = [], setSongStats = {}, openersClosers = {}, repeats = {}) {
        this.longestSongs = longestSongs;
        this.rarestSongs = rarestSongs;
        this.mostPlayedSongs = mostPlayedSongs;
        this.mostCommonSongsNotPlayed = mostCommonSongsNotPlayed;
        this.setSongStats = setSongStats;
        this.openersClosers = openersClosers;
        this.repeats = repeats;
        this.tourName = tourName;
    }

    get hasData() {
        return this.longestSongs.length > 0 ||
               this.rarestSongs.length > 0 ||
               this.mostPlayedSongs.length > 0 ||
               this.mostCommonSongsNotPlayed.length > 0 ||
               Object.keys(this.setSongStats).length > 0 ||
               Object.keys(this.openersClosers).length > 0 ||
               (this.repeats?.shows?.length > 0);
    }
}