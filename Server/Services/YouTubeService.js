/**
 * YouTubeService.js
 *
 * Service for fetching YouTube videos from the official Phish channel
 * for the current tour date range.
 *
 * Uses YouTube Data API v3 to search for videos published between
 * tour start and end dates.
 */

import LoggingService from './LoggingService.js';

// Official Phish YouTube channel ID
const PHISH_CHANNEL_ID = 'UCDEPOd0RCvw8iSTqFpSBZLA';

/**
 * YouTube video data structure matching iOS model
 */
class YouTubeVideo {
    constructor(videoId, title, thumbnailUrl, publishedAt, duration, viewCount) {
        this.videoId = videoId;
        this.title = title;
        this.thumbnailUrl = thumbnailUrl;
        this.publishedAt = publishedAt;
        this.duration = duration;
        this.viewCount = viewCount;
    }
}

/**
 * Service for fetching Phish YouTube videos
 */
export class YouTubeService {
    constructor(apiKey) {
        this.apiKey = apiKey || process.env.YOUTUBE_API_KEY;
        this.baseUrl = 'https://www.googleapis.com/youtube/v3';
    }

    /**
     * Fetch videos from Phish channel within a date range
     *
     * @param {string} startDate - Tour start date (YYYY-MM-DD)
     * @param {string} endDate - Tour end date (YYYY-MM-DD)
     * @param {Set<string>} validShowDates - Set of valid tour dates (YYYY-MM-DD)
     * @param {number} maxResults - Maximum videos to return (default 50)
     * @returns {Promise<YouTubeVideo[]>}
     */
    async fetchTourVideos(startDate, endDate, validShowDates, maxResults = 50) {
        if (!this.apiKey) {
            LoggingService.warn('YouTube API key not configured - skipping video fetch');
            return [];
        }

        try {
            LoggingService.info(`Fetching YouTube videos from ${startDate} to ${endDate}...`);

            // Convert dates to RFC 3339 format for YouTube API
            const publishedAfter = `${startDate}T00:00:00Z`;
            const publishedBefore = `${endDate}T23:59:59Z`;

            // Step 1: Search for videos from Phish channel in date range
            const searchResults = await this.searchVideos(publishedAfter, publishedBefore, maxResults);

            if (searchResults.length === 0) {
                LoggingService.info('No videos found in date range');
                return [];
            }

            // Filter out live streams - only include regular uploaded videos
            // liveBroadcastContent: 'none' = uploaded video, 'live' = currently live, 'upcoming' = scheduled
            const uploadedVideos = searchResults.filter(item =>
                item.snippet.liveBroadcastContent === 'none'
            );

            const liveCount = searchResults.length - uploadedVideos.length;
            if (liveCount > 0) {
                LoggingService.info(`Filtered out ${liveCount} live stream(s)`);
            }

            if (uploadedVideos.length === 0) {
                LoggingService.info('No uploaded videos found (only live streams in date range)');
                return [];
            }

            // Filter by show date - only include videos matching tour schedule
            const tourVideos = uploadedVideos.filter(item =>
                this.isValidTourVideo(item.snippet.title, validShowDates)
            );

            const filteredCount = uploadedVideos.length - tourVideos.length;
            if (filteredCount > 0) {
                LoggingService.info(`Filtered ${filteredCount} video(s) not matching tour dates`);
            }

            if (tourVideos.length === 0) {
                LoggingService.info('No videos match current tour dates');
                return [];
            }

            LoggingService.info(`Found ${tourVideos.length} videos matching tour dates, fetching details...`);

            // Step 2: Get video details (duration, view count)
            const videoIds = tourVideos.map(item => item.id.videoId).join(',');
            const videoDetails = await this.getVideoDetails(videoIds);

            // Step 3: Combine search results with details
            const videos = tourVideos.map(item => {
                const details = videoDetails.find(d => d.id === item.id.videoId);
                return new YouTubeVideo(
                    item.id.videoId,
                    this.decodeHtmlEntities(item.snippet.title),
                    this.getBestThumbnail(item.snippet.thumbnails),
                    item.snippet.publishedAt,
                    details?.contentDetails?.duration || 'PT0S',
                    parseInt(details?.statistics?.viewCount || '0', 10)
                );
            });

            // Sort by publish date (newest first)
            videos.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));

            LoggingService.success(`Successfully fetched ${videos.length} YouTube videos`);
            return videos;

        } catch (error) {
            LoggingService.error('Error fetching YouTube videos:', error.message);
            return [];
        }
    }

    /**
     * Search for videos from Phish channel
     */
    async searchVideos(publishedAfter, publishedBefore, maxResults) {
        const params = new URLSearchParams({
            part: 'snippet',
            channelId: PHISH_CHANNEL_ID,
            type: 'video',
            order: 'date',
            publishedAfter,
            publishedBefore,
            maxResults: maxResults.toString(),
            key: this.apiKey
        });

        const url = `${this.baseUrl}/search?${params}`;
        const response = await fetch(url);

        if (!response.ok) {
            const error = await response.json();
            throw new Error(`YouTube search API error: ${error.error?.message || response.statusText}`);
        }

        const data = await response.json();
        return data.items || [];
    }

    /**
     * Get video details (duration, statistics)
     */
    async getVideoDetails(videoIds) {
        const params = new URLSearchParams({
            part: 'contentDetails,statistics',
            id: videoIds,
            key: this.apiKey
        });

        const url = `${this.baseUrl}/videos?${params}`;
        const response = await fetch(url);

        if (!response.ok) {
            const error = await response.json();
            throw new Error(`YouTube videos API error: ${error.error?.message || response.statusText}`);
        }

        const data = await response.json();
        return data.items || [];
    }

    /**
     * Get the best available thumbnail URL (prefer maxres, fallback to high)
     */
    getBestThumbnail(thumbnails) {
        if (thumbnails.maxres) return thumbnails.maxres.url;
        if (thumbnails.high) return thumbnails.high.url;
        if (thumbnails.medium) return thumbnails.medium.url;
        if (thumbnails.default) return thumbnails.default.url;
        return '';
    }

    /**
     * Decode HTML entities in text (e.g., &#39; to ')
     */
    decodeHtmlEntities(text) {
        const entities = {
            '&#39;': "'",
            '&quot;': '"',
            '&lt;': '<',
            '&gt;': '>',
            '&amp;': '&'
        };
        return text.replace(/&#?\w+;/g, match => entities[match] || match);
    }

    /**
     * Extract show date from video title
     * Supports multiple date formats: MM/DD/YYYY, YYYY-MM-DD, month names, NYE
     * @param {string} title - Video title
     * @returns {string|null} Date in YYYY-MM-DD format, or null if no date found
     */
    extractDateFromTitle(title) {
        // Pattern 1: Slash format (MM/DD/YYYY or M/D/YYYY)
        const slashPattern = /(\d{1,2})\/(\d{1,2})\/(\d{4})/;
        const slashMatch = title.match(slashPattern);
        if (slashMatch) {
            const month = parseInt(slashMatch[1], 10);
            const day = parseInt(slashMatch[2], 10);
            const year = parseInt(slashMatch[3], 10);

            // Validate date components
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1983) {
                const date = new Date(year, month - 1, day);
                // Verify date is valid (handles Feb 30 etc.)
                if (date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day) {
                    return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
                }
            }
        }

        // Pattern 2: ISO format (YYYY-MM-DD)
        const isoPattern = /(\d{4})-(\d{2})-(\d{2})/;
        const isoMatch = title.match(isoPattern);
        if (isoMatch) {
            const year = parseInt(isoMatch[1], 10);
            const month = parseInt(isoMatch[2], 10);
            const day = parseInt(isoMatch[3], 10);

            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1983) {
                const date = new Date(year, month - 1, day);
                if (date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day) {
                    return isoMatch[0]; // Already in YYYY-MM-DD format
                }
            }
        }

        // Pattern 3: Month name format (December 31, 2025 or Dec 31 2025)
        const monthNames = {
            'january': 1, 'jan': 1,
            'february': 2, 'feb': 2,
            'march': 3, 'mar': 3,
            'april': 4, 'apr': 4,
            'may': 5,
            'june': 6, 'jun': 6,
            'july': 7, 'jul': 7,
            'august': 8, 'aug': 8,
            'september': 9, 'sep': 9, 'sept': 9,
            'october': 10, 'oct': 10,
            'november': 11, 'nov': 11,
            'december': 12, 'dec': 12
        };

        const monthPattern = /(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)\s+(\d{1,2}),?\s+(\d{4})/i;
        const monthMatch = title.match(monthPattern);
        if (monthMatch) {
            const monthName = monthMatch[1].toLowerCase();
            const month = monthNames[monthName];
            const day = parseInt(monthMatch[2], 10);
            const year = parseInt(monthMatch[3], 10);

            if (month && day >= 1 && day <= 31 && year >= 1983) {
                const date = new Date(year, month - 1, day);
                if (date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day) {
                    return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
                }
            }
        }

        // Pattern 4: Special cases (New Year's Eve or NYE)
        const nyePattern = /(?:new year'?s? eve|nye)\s+(\d{4})/i;
        const nyeMatch = title.match(nyePattern);
        if (nyeMatch) {
            const year = parseInt(nyeMatch[1], 10);
            if (year >= 1983) {
                return `${year}-12-31`;
            }
        }

        // No date found
        return null;
    }

    /**
     * Check if video title contains a date in the tour schedule
     * @param {string} title - Video title
     * @param {Set<string>} validShowDates - Set of valid tour dates (YYYY-MM-DD)
     * @returns {boolean} True if video should be included
     */
    isValidTourVideo(title, validShowDates) {
        const parsedDate = this.extractDateFromTitle(title);

        if (!parsedDate) {
            LoggingService.warn(`No date found in title: "${title}"`);
            return false;
        }

        const isValid = validShowDates.has(parsedDate);

        if (!isValid) {
            LoggingService.info(`Date ${parsedDate} not in tour schedule - filtering out: "${title}"`);
        }

        return isValid;
    }
}

export default YouTubeService;
