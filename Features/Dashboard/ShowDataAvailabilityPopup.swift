//
//  ShowDataAvailabilityPopup.swift
//  PhishQS
//
//  Popup showing which shows have song duration data available
//  Uses single source of truth from tour-statistics API
//

import SwiftUI

struct ShowDataAvailabilityPopup: View {
    let showDurationAvailability: [ShowDurationAvailability]
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
                        ForEach(showDurationAvailability) { show in
                            ShowAvailabilityRow(show: show)

                            if show.date != showDurationAvailability.last?.date {
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
}

struct ShowAvailabilityRow: View {
    let show: ShowDurationAvailability

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(show.formattedDate)
                    .font(.body)
                    .fontWeight(.medium)

                Text(show.venueDisplayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            Text(show.durationsAvailable ? "✓" : "✗")
                .font(.title2)
                .foregroundColor(show.durationsAvailable ? .green : .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    let sampleAvailability = [
        ShowDurationAvailability(
            date: "2025-12-28",
            venue: "Madison Square Garden",
            city: "New York",
            state: "NY",
            durationsAvailable: true
        ),
        ShowDurationAvailability(
            date: "2025-12-29",
            venue: "Madison Square Garden",
            city: "New York",
            state: "NY",
            durationsAvailable: false
        )
    ]

    return ShowDataAvailabilityPopup(
        showDurationAvailability: sampleAvailability,
        isPresented: .constant(true)
    )
}