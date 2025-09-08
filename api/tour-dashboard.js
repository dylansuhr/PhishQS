import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default function handler(req, res) {
  try {
    // Read tour dashboard control file from Server/Data directory
    const dashboardPath = join(__dirname, '..', 'Server', 'Data', 'tour-dashboard-data.json');
    const dashboardData = JSON.parse(readFileSync(dashboardPath, 'utf8'));
    
    // Set cache headers for performance
    res.setHeader('Cache-Control', 's-maxage=3600');
    res.status(200).json(dashboardData);
  } catch (error) {
    console.error('Error reading tour dashboard data:', error);
    res.status(500).json({ error: 'Failed to load tour dashboard data' });
  }
}