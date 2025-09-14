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

    // Read tour dashboard to find which tour contains this date
    const dashboardPath = join(__dirname, '..', '..', 'Server', 'Data', 'tour-dashboard-data.json');
    const dashboardData = JSON.parse(readFileSync(dashboardPath, 'utf8'));

    // Check current tour first
    let tourSlug = null;
    let showFile = null;

    // Check if date is in current tour
    const currentTourDate = dashboardData.currentTour.tourDates.find(td => td.date === date);
    if (currentTourDate && currentTourDate.showFile) {
      showFile = currentTourDate.showFile;
    }

    // Check future tours if not found in current tour
    if (!showFile && dashboardData.futureTours) {
      for (const tour of dashboardData.futureTours) {
        const futureDate = tour.tourDates.find(td => td.date === date);
        if (futureDate && futureDate.showFile) {
          showFile = futureDate.showFile;
          break;
        }
      }
    }

    if (!showFile) {
      return res.status(404).json({ error: `Show data not found for date: ${date}` });
    }

    // Construct the full path to the show file
    const showPath = join(__dirname, '..', '..', 'Server', 'Data', showFile);

    if (!existsSync(showPath)) {
      return res.status(404).json({ error: `Show file not found: ${showFile}` });
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