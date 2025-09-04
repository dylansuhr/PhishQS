//
//  SharedUIComponents.swift
//  PhishQS
//
//  Created by Claude on 12/3/25.
//

import SwiftUI

// MARK: - Badge Component

/// Reusable badge component for displaying small status indicators
struct BadgeView: View {
    let text: String
    let style: BadgeStyle
    
    enum BadgeStyle {
        case blue
        case gray
        case orange
        case green
        
        var backgroundColor: Color {
            switch self {
            case .blue: return .blue.opacity(0.1)
            case .gray: return .gray.opacity(0.1)
            case .orange: return .orange.opacity(0.1)
            case .green: return .green.opacity(0.1)
            }
        }
        
        var textColor: Color {
            switch self {
            case .blue: return .blue
            case .gray: return .gray
            case .orange: return .orange
            case .green: return .green
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(style.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(style.backgroundColor)
            .cornerRadius(6)
    }
}

// MARK: - Tour Info Display Component

/// Reusable component for displaying tour context information (city/state and tour position)
struct TourInfoDisplayView: View {
    let city: String?
    let state: String?
    let tourPosition: TourShowPosition?
    let date: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Date with tour position badge
            HStack(spacing: 8) {
                Text(DateUtilities.formatDateForDisplay(date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let tourPosition = tourPosition {
                    BadgeView(
                        text: "\(tourPosition.showNumber)/\(tourPosition.totalShows)", 
                        style: .blue
                    )
                }
                
                Spacer()
            }
            
            // City and state
            if let cityStateText = cityStateDisplayText {
                Text(cityStateText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Formatted city and state display text
    private var cityStateDisplayText: String? {
        guard let city = city else { return nil }
        
        if let state = state {
            return "\(city), \(state)"
        } else {
            return city
        }
    }
}

// MARK: - Tour Statistics Row Components

/// Generic base component for tour statistics rows
struct TourStatisticsRowBase<T: TourContextProvider, MetricView: View>: View {
    let position: Int
    let item: T
    let positionColor: Color
    let metricView: () -> MetricView
    
    init(position: Int, item: T, positionColor: Color, @ViewBuilder metricView: @escaping () -> MetricView) {
        self.position = position
        self.item = item
        self.positionColor = positionColor
        self.metricView = metricView
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Position number
            Text("\(position)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(positionColor)
                .frame(width: 20, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                // Song name (assuming all TourContextProvider items have a songName)
                if let item = item as? any SongNameProvider {
                    Text(item.songName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Date only (tour position feature temporarily disabled)
                HStack(spacing: 8) {
                    Text(DateUtilities.formatDateForDisplay(item.showDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // FEATURE TEMPORARILY DISABLED: Tour position badge (e.g., "4/23")
                    // To re-enable: uncomment the block below
                    // This displays the show number within the tour (e.g., show 4 of 23)
                    /*
                    if let tourPosition = item.tourPosition {
                        BadgeView(
                            text: "\(tourPosition.showNumber)/\(tourPosition.totalShows)", 
                            style: .blue
                        )
                    }
                    */
                    
                    Spacer()
                }
                
                // Venue information with run info if available
                if let venueText = venueDisplayText(for: item) {
                    Text(venueText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                // City and state below venue
                if let cityStateText = cityStateDisplayText(city: item.city, state: item.state) {
                    Text(cityStateText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(1)
            
            Spacer(minLength: 8)
            
            // Custom metric view (duration, gap, play count, etc.)
            metricView()
                .layoutPriority(2)
        }
    }
    
    /// Helper function to get venue display text with run info for different model types
    private func venueDisplayText(for item: T) -> String? {
        // Handle TrackDuration with venueDisplayText property
        if let trackDuration = item as? TrackDuration {
            return trackDuration.venueDisplayText
        }
        
        // Handle SongGapInfo with tourVenueDisplayText property
        if let songGapInfo = item as? SongGapInfo {
            return songGapInfo.tourVenueDisplayText
        }
        
        // MostPlayedSong no longer has venue info - return nil
        if item is MostPlayedSong {
            return nil
        }
        
        // Fallback for other types that conform to TourContextProvider
        return item.venue
    }
    
    /// Helper function to format city and state display text
    private func cityStateDisplayText(city: String?, state: String?) -> String? {
        guard let city = city else { return nil }
        
        if let state = state {
            return "\(city), \(state)"
        } else {
            return city
        }
    }
}

/// Protocol to provide song name for generic row component
protocol SongNameProvider {
    var songName: String { get }
}

// Make our statistics models conform to SongNameProvider
extension TrackDuration: SongNameProvider {}
extension SongGapInfo: SongNameProvider {}
extension MostPlayedSong: SongNameProvider {}

/// Specialized row for longest songs
struct LongestSongRowModular: View {
    let position: Int
    let song: TrackDuration
    
    var body: some View {
        TourStatisticsRowBase(position: position, item: song, positionColor: .blue) {
            Text(song.formattedDuration)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

/// Specialized row for rarest songs
struct RarestSongRowModular: View {
    let position: Int
    let song: SongGapInfo
    
    var body: some View {
        TourStatisticsRowBase(position: position, item: song, positionColor: .orange) {
            VStack(alignment: .trailing, spacing: 2) {
                // Gap number
                if song.gap == 0 {
                    Text("Recent")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                } else {
                    Text("\(song.gap)")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                // Last played date (the date that created this gap)
                if song.gap > 0 {
                    if let historicalDate = song.historicalLastPlayed {
                        Text(historicalDate)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text(song.lastPlayed)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

/// Specialized row for most played songs (simplified: only song name and count)
struct MostPlayedSongRowModular: View {
    let position: Int
    let song: MostPlayedSong
    
    var body: some View {
        HStack(spacing: 12) {
            // Position number
            Text("\(position)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.green)
                .frame(width: 20, alignment: .center)
            
            // Song name only
            Text(song.songName)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            
            Spacer(minLength: 8)
            
            // Play count only
            Text("\(song.playCount)")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.green)
                .layoutPriority(2)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Badge samples
        HStack(spacing: 8) {
            BadgeView(text: "23/23", style: .blue)
            BadgeView(text: "N3/3", style: .gray)
            BadgeView(text: "47", style: .orange)
            BadgeView(text: "8", style: .green)
        }
        
        // Tour info samples
        let sampleTourPosition = TourShowPosition(
            tourName: "Summer Tour 2025",
            showNumber: 4,
            totalShows: 23,
            tourYear: "2025"
        )
        
        VStack(alignment: .leading, spacing: 16) {
            TourInfoDisplayView(
                city: "Pittsburgh", 
                state: "PA", 
                tourPosition: sampleTourPosition, 
                date: "2025-06-24"
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        
        // Modular row samples
        VStack(spacing: 12) {
            // Sample longest song
            let sampleLongest = TrackDuration(
                id: "1", songName: "What's Going Through Your Mind", songId: nil, 
                durationSeconds: 1383, showDate: "2025-06-24", setNumber: "2", 
                venue: "Petersen Events Center", venueRun: nil, 
                city: "Pittsburgh", state: "PA", tourPosition: sampleTourPosition
            )
            LongestSongRowModular(position: 1, song: sampleLongest)
            
            // Sample rarest song
            let sampleRarest = SongGapInfo(
                songId: 251, songName: "Fluffhead", gap: 47, 
                lastPlayed: "2023-08-15", timesPlayed: 87, 
                tourVenue: "Petersen Events Center", tourVenueRun: nil, 
                tourDate: "2025-06-24", tourCity: "Pittsburgh", tourState: "PA", 
                tourPosition: sampleTourPosition
            )
            RarestSongRowModular(position: 1, song: sampleRarest)
            
            // Sample most played song  
            let sampleMostPlayed = MostPlayedSong(
                songId: 473, songName: "You Enjoy Myself", playCount: 8
            )
            MostPlayedSongRowModular(position: 1, song: sampleMostPlayed)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        
        Spacer()
    }
    .padding()
}