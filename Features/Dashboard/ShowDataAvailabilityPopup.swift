//
//  ShowDataAvailabilityPopup.swift
//  PhishQS
//
//  Popup showing which shows have song duration data available
//

import SwiftUI

struct ShowDataAvailabilityPopup: View {
    let tourData: TourDashboardDataClient.TourDashboardData
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Song Duration Data Availability")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Shows with duration data contribute to longest songs statistics")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()

                Divider()

                // Show list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(playedShows, id: \.date) { show in
                            ShowAvailabilityRow(
                                show: show,
                                durationsAvailable: getDurationsAvailable(for: show.date)
                            )

                            if show.date != playedShows.last?.date {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var playedShows: [TourDashboardDataClient.TourDashboardData.TourDate] {
        tourData.currentTour.tourDates.filter { $0.played }
    }

    private func getDurationsAvailable(for date: String) -> Bool {
        return tourData.updateTracking.individualShows[date]?.durationsAvailable ?? false
    }
}

struct ShowAvailabilityRow: View {
    let show: TourDashboardDataClient.TourDashboardData.TourDate
    let durationsAvailable: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.body)
                    .fontWeight(.medium)

                Text("\(show.venue), \(show.city), \(show.state)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            Text(durationsAvailable ? "✓" : "✗")
                .font(.title2)
                .foregroundColor(durationsAvailable ? .green : .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: show.date) else {
            return show.date
        }

        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleTourData = TourDashboardDataClient.TourDashboardData(
        currentTour: TourDashboardDataClient.TourDashboardData.CurrentTour(
            name: "2025 Late Summer Tour",
            year: "2025",
            totalShows: 8,
            playedShows: 7,
            startDate: "2025-09-12",
            endDate: "2025-09-21",
            tourDates: [
                TourDashboardDataClient.TourDashboardData.TourDate(
                    date: "2025-09-12",
                    venue: "Highland Festival Grounds",
                    city: "Louisville",
                    state: "KY",
                    played: true,
                    showNumber: 1,
                    showFile: "show1.json"
                ),
                TourDashboardDataClient.TourDashboardData.TourDate(
                    date: "2025-09-13",
                    venue: "Coca-Cola Amphitheater",
                    city: "Birmingham",
                    state: "AL",
                    played: true,
                    showNumber: 2,
                    showFile: "show2.json"
                )
            ]
        ),
        latestShow: TourDashboardDataClient.TourDashboardData.LatestShow(
            date: "2025-09-13",
            venue: "Test Venue",
            city: "Test City",
            state: "TS",
            tourPosition: TourDashboardDataClient.TourDashboardData.TourPosition(
                showNumber: 2,
                totalShows: 8,
                tourName: "2025 Late Summer Tour"
            )
        ),
        futureTours: [],
        metadata: TourDashboardDataClient.TourDashboardData.Metadata(
            lastUpdated: "2025-09-21",
            dataVersion: "1.0",
            updateReason: "test",
            nextShow: nil
        ),
        updateTracking: TourDashboardDataClient.TourDashboardData.UpdateTracking(
            lastAPICheck: "2025-09-21",
            latestShowFromAPI: "2025-09-13",
            pendingDurationChecks: [],
            individualShows: [
                "2025-09-12": TourDashboardDataClient.TourDashboardData.ShowStatus(
                    exists: true,
                    lastUpdated: "2025-09-14",
                    durationsAvailable: false,
                    dataComplete: false,
                    needsUpdate: true
                ),
                "2025-09-13": TourDashboardDataClient.TourDashboardData.ShowStatus(
                    exists: true,
                    lastUpdated: "2025-09-16",
                    durationsAvailable: true,
                    dataComplete: true,
                    needsUpdate: false
                )
            ]
        )
    )

    return ShowDataAvailabilityPopup(
        tourData: sampleTourData,
        isPresented: .constant(true)
    )
}