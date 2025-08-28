# PhishQS

**PhishQS** (Phish Quick Setlist) is a minimalist iOS app built with SwiftUI that provides fast, intuitive access to Phish setlists and show data. Designed with a focus on speed, simplicity, and minimal taps to get the information you need.

## Overview

PhishQS follows a hierarchical navigation pattern: **Year → Month → Day → Setlist**, allowing users to quickly drill down to any show in Phish history. The app prioritizes performance and user experience with features like tour statistics, song durations, venue information, and enhanced setlist displays.

## Core Features

### **Setlist Navigation**
- **Quick Browse**: Navigate by year (1983-2025), month, and day
- **Latest Show**: Instant access to the most recent show
- **Search by Date**: Fast date-based show lookup
- **Minimal Interface**: Designed for speed with minimal taps required

### **Enhanced Show Data**
- **Complete Setlists**: Full song lists with set breaks and encore information  
- **Song Durations**: Individual song timing data where available
- **Venue Details**: Show locations, venue runs (N1/N2/N3 for multi-night stands)
- **Tour Context**: Tour position information (Show X/Y of tour)

### **Tour Analytics**
- **Tour Statistics**: Insights and metrics for current tour
- **Performance Data**: Song duration analysis and tour-wide statistics
- **Visual Enhancements**: Color-coded displays for enhanced readability

## Architecture

### **Technology Stack**
- **SwiftUI**: Modern iOS interface framework
- **Swift Concurrency**: Async/await for responsive network operations
- **MVVM Pattern**: Clean separation of concerns with ViewModels
- **Protocol-Oriented Design**: Testable, modular architecture

### **Data Sources**
- **Phish.net API**: Primary source for setlist data and show information
- **Phish.in API**: Song durations, tour metadata, and venue run details
- **Multi-API Integration**: Combines multiple data sources for enhanced user experience

### **Performance Optimizations**
- **Intelligent Caching**: Multi-level caching strategy for fast data access
- **Background Processing**: Non-blocking data fetching and calculations
- **Memory Management**: Efficient handling of large datasets

## Development

### **Project Structure**
```
PhishQS/
├── Features/           # Feature-based organization (MVVM pairs)
├── Services/           # API clients and network layer
├── Models/            # Data models and business logic
├── Utilities/         # Shared utilities and extensions
└── Resources/         # App resources and configuration
```

### **Requirements**
- **iOS**: 18.4+
- **Xcode**: 16.0+
- **Swift**: 5.9+

### **Build Instructions**
```bash
# Build for iOS device
xcodebuild -project PhishQS.xcodeproj -scheme PhishQS -destination 'generic/platform=iOS' build

# Open in Xcode
open PhishQS.xcodeproj
```

### **Testing**
```bash
# Run unit tests
xcodebuild test -scheme PhishQS -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Contributing

This project follows standard iOS development practices with emphasis on:
- **Clean Architecture**: MVVM with dependency injection
- **Swift Best Practices**: Modern Swift patterns and conventions  
- **Performance First**: Optimized for speed and responsiveness
- **User Experience**: Minimal taps, fast loading, intuitive navigation

## API Keys

The app requires a Phish.net API key. Add your key to `Resources/Secrets.plist`:
```xml
<key>PhishNetAPIKey</key>
<string>your_api_key_here</string>
```

## Status

🚧 **Active Development** - Core functionality implemented, ongoing feature development and optimizations

## License

MIT License - See LICENSE file for details
