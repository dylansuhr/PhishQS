//
//  TourOverviewCard.swift
//  PhishQS
//
//  Tour overview information card for future features
//  Extracted from TourMetricCards.swift for better organization
//

import SwiftUI

struct TourOverviewCard: View {
    let tourName: String?
    let showCount: Int?
    let totalSongs: Int?

    var body: some View {
        MetricCard("Tour Overview") {
            VStack(alignment: .leading, spacing: 12) {
                if let tourName = tourName {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Tour")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Text(tourName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }

                HStack {
                    if showCount != nil {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(showCount!)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)

                            Text("Shows")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if totalSongs != nil {
                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(totalSongs!)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)

                            Text("Unique Songs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}