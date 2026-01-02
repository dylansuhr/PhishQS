#!/usr/bin/env node
/**
 * prod-mode.js
 *
 * Restores production data after testing.
 * Reverts tour-dashboard-data.json and regenerates stats.
 *
 * Usage: npm run prod-mode
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dataDir = path.join(__dirname, '..', 'Data');

console.log('🏭 Restoring PRODUCTION MODE');
console.log('');

// Check for backup files
const dashboardPath = path.join(dataDir, 'tour-dashboard-data.json');
const statsPath = path.join(dataDir, 'tour-stats.json');
const backupDashboardPath = path.join(dataDir, 'tour-dashboard-data.json.prod');
const backupStatsPath = path.join(dataDir, 'tour-stats.json.prod');

if (!fs.existsSync(backupDashboardPath)) {
    console.log('⚠️  No production backup found (tour-dashboard-data.json.prod)');
    console.log('   You may already be in production mode.');
    process.exit(1);
}

// Restore production data
console.log('📦 Restoring production data...');
fs.copyFileSync(backupDashboardPath, dashboardPath);
fs.copyFileSync(backupStatsPath, statsPath);
console.log('   ✓ Restored tour-dashboard-data.json');
console.log('   ✓ Restored tour-stats.json');

// Remove backup files
fs.unlinkSync(backupDashboardPath);
fs.unlinkSync(backupStatsPath);
console.log('   ✓ Removed backup files');

// Verify restoration
const dashboard = JSON.parse(fs.readFileSync(dashboardPath, 'utf8'));
console.log(`\n✅ PRODUCTION MODE RESTORED`);
console.log(`   Current Tour: ${dashboard.currentTour.name}`);
console.log(`   Shows: ${dashboard.currentTour.playedShows}/${dashboard.currentTour.totalShows}`);
console.log(`   Latest Show: ${dashboard.latestShow.date}`);
