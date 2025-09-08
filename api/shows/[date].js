import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default function handler(req, res) {
  try {
    const { date } = req.query;
    
    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return res.status(400).json({ error: 'Invalid date format. Expected YYYY-MM-DD' });
    }
    
    // Construct path to show file based on current tour structure
    // For now, assume 2025 Early Summer Tour - this could be enhanced to be dynamic
    const showPath = join(__dirname, '..', '..', 'Server', 'Data', 'tours', '2025-early-summer-tour', `show-${date}.json`);
    
    if (!existsSync(showPath)) {
      return res.status(404).json({ error: `Show data not found for date: ${date}` });
    }
    
    const showData = JSON.parse(readFileSync(showPath, 'utf8'));
    
    // Set cache headers for performance
    res.setHeader('Cache-Control', 's-maxage=3600');
    res.status(200).json(showData);
  } catch (error) {
    console.error('Error reading show data:', error);
    res.status(500).json({ error: 'Failed to load show data' });
  }
}