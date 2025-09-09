import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default function handler(req, res) {
  try {
    // Read pre-computed statistics from Server/Data directory (single source of truth)
    const statsPath = join(__dirname, '..', 'Server', 'Data', 'tour-stats.json');
    const stats = JSON.parse(readFileSync(statsPath, 'utf8'));
    
    // Set cache headers for performance
    res.setHeader('Cache-Control', 's-maxage=3600');
    res.status(200).json(stats);
  } catch (error) {
    console.error('Error reading tour statistics:', error);
    res.status(500).json({ error: 'Failed to load tour statistics' });
  }
}