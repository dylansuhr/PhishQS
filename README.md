# PhishQS

PhishQS (Phish Quick Setlist) is a hybrid iOS/Node.js project that provides fast access to Phish setlists and tour statistics. The iOS app offers a minimalist interface for browsing shows, while the Node.js server delivers pre-computed tour statistics via Vercel serverless functions.

## Project Architecture

### iOS App
- **Minimalist setlist browser** with year/month/day navigation
- **Tour dashboard** with latest show and statistics cards
- **Multi-API integration** combining Phish.net (setlists, gaps) and Phish.in (durations, tours)
- **Optimized caching** to minimize API calls and improve performance
- Built with **Swift/UIKit** for iOS 16.0+

### Server Components
- **Vercel serverless functions** for tour statistics API
- **Modular calculator architecture** for extensible statistics types
- **Pre-computed statistics** replacing 60+ second iOS calculations with ~140ms server responses
- **Configuration-driven** system with no hardcoded values
- **Multi-environment support** (development, production, preview)

## Current Features

### iOS App
- Browse setlists by year/month/day with minimal taps
- Latest setlist display with venue runs (N1/N2/N3) and tour context
- Tour statistics dashboard showing:
  - Longest songs (by performance duration)
  - Rarest songs (by gap - shows since last played)
  - Most played songs (by tour frequency)
- Enhanced setlist details with song durations and gaps
- Efficient multi-API data combining

### Server/API
- `GET /api/tour-statistics` - Pre-computed tour statistics
- Real-time data generation from live API sources
- Modular calculator system for easy statistics expansion
- Automatic tour detection and statistics generation
- Response caching for optimal performance

## Development Commands

### Server Development
```bash
npm run dev                # Start Vercel development server
npm run generate-stats     # Generate tour statistics from live APIs
npm run deploy             # Deploy to Vercel production
```

### iOS Development
- Open `PhishQS.xcodeproj` in Xcode
- Build and run on iOS Simulator or device
- UI tests available in `Tests/PhishQSUITests/`

## Technical Highlights

### Performance Optimizations
- **Server-side pre-computation**: Tour statistics calculated once, served instantly
- **Multi-API strategy**: Combines Phish.net + Phish.in for comprehensive data
- **Progressive gap tracking**: Efficient algorithm for rarest song calculations
- **Smart caching**: Reduces redundant API calls across the system

### Architecture Benefits
- **Extensible**: New tour statistics can be added without iOS changes
- **Maintainable**: Modular calculator system with clear separation of concerns
- **Configurable**: Environment-specific settings with no hardcoded values
- **Future-proof**: Registry pattern supports unlimited statistics types

## APIs Used
- **Phish.net API v5**: Setlist data, gap calculations, official Phish database
- **Phish.in API v2**: Track durations, tour organization, venue runs, recordings

## Requirements
- **iOS**: 16.0+, Xcode 15+
- **Server**: Node.js 18+, Vercel CLI
- **APIs**: Phish.net API key required for statistics generation

## Deployment
- **iOS**: Standard Xcode build and App Store distribution
- **Server**: Deployed to Vercel at `https://phish-qs.vercel.app`
- **Statistics**: Auto-generated via GitHub Actions or manual script execution

## Status
🚀 **Active Development** - Core functionality complete, ongoing feature expansion

## License
MIT
