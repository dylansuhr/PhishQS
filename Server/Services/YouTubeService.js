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
     * @param {number} maxResults - Maximum videos to return (default 50)
     * @returns {Promise<YouTubeVideo[]>}
     */
    async fetchTourVideos(startDate, endDate, maxResults = 50) {
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

            LoggingService.info(`Found ${uploadedVideos.length} uploaded videos, fetching details...`);

            // Step 2: Get video details (duration, view count)
            const videoIds = uploadedVideos.map(item => item.id.videoId).join(',');
            const videoDetails = await this.getVideoDetails(videoIds);

            // Step 3: Combine search results with details
            const videos = uploadedVideos.map(item => {
                const details = videoDetails.find(d => d.id === item.id.videoId);
                return new YouTubeVideo(
                    item.id.videoId,
                    item.snippet.title,
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
}

export default YouTubeService;
