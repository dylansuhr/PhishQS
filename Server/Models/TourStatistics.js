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
 * Track duration information with venue context
 * Mirrors Swift TrackDuration struct
 */
export class TrackDuration {
    constructor(id, songName, songId, durationSeconds, showDate, setNumber, venue, venueRun = null) {
        this.id = id;
        this.songName = songName;
        this.songId = songId;
        this.durationSeconds = durationSeconds;
        this.showDate = showDate;
        this.setNumber = setNumber;
        this.venue = venue;
        this.venueRun = venueRun;
    }
    
    get formattedDuration() {
        const minutes = Math.floor(this.durationSeconds / 60);
        const seconds = this.durationSeconds % 60;
        return `${minutes}:${seconds.toString().padStart(2, '0')}`;
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
        this.lastPlayed = lastPlayed;
        this.timesPlayed = timesPlayed;
        this.tourVenue = options.tourVenue || null;
        this.tourVenueRun = options.tourVenueRun || null;
        this.tourDate = options.tourDate || null;
        this.historicalVenue = options.historicalVenue || null;
        this.historicalCity = options.historicalCity || null;
        this.historicalState = options.historicalState || null;
        this.historicalLastPlayed = options.historicalLastPlayed || null;
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
    constructor(longestSongs, rarestSongs, mostPlayedSongs, tourName) {
        this.longestSongs = longestSongs;
        this.rarestSongs = rarestSongs;
        this.mostPlayedSongs = mostPlayedSongs;
        this.tourName = tourName;
    }
    
    get hasData() {
        return this.longestSongs.length > 0 || 
               this.rarestSongs.length > 0 || 
               this.mostPlayedSongs.length > 0;
    }
}