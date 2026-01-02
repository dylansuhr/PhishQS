import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default function handler(req, res) {
  try {
    // Read pre-computed statistics from Server/Data directory (single source of truth)
    const statsPath = join(__dirname, '..', 'Server', 'Data', 'tour-stats.json');
    const stats = JSON.parse(readFileSync(statsPath, 'utf8'));

    // Read YouTube videos from separate file (decoupled from stats generation)
    const youtubePath = join(__dirname, '..', 'Server', 'Data', 'youtube-videos.json');
    let youtubeVideos = [];

    if (existsSync(youtubePath)) {
      const youtubeData = JSON.parse(readFileSync(youtubePath, 'utf8'));
      youtubeVideos = youtubeData.videos || [];
    }

    // Merge YouTube videos into response
    const response = {
      ...stats,
      youtubeVideos: youtubeVideos
    };

    // Set cache headers for performance
    res.setHeader('Cache-Control', 's-maxage=3600');
    res.status(200).json(response);
  } catch (error) {
    console.error('Error reading tour statistics:', error);
    res.status(500).json({ error: 'Failed to load tour statistics' });
  }
}