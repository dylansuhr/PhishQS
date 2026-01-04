//
//  RepeatsGraphCard.swift
//  PhishQS
//
//  Tour repeats and average gap graph card with tabbed interface
//  - Repeats %: percentage of songs repeated from earlier in tour
//  - Avg Gap: average shows since each song was last played (higher = rarer show)
//

import SwiftUI
import Charts

// MARK: - Metric Tab Enum

enum MetricTab: String, CaseIterable {
    case repeats = "Repeats %"
    case gap = "Avg Gap"
}

struct RepeatsGraphCard: View {
    let repeats: RepeatsStats

    @State private var selectedTab: MetricTab = .repeats
    @State private var selectedShow: RepeatShowData?
    @State private var hasInitialized = false

    // Colors for the metrics
    private let repeatsColor = Color.appHeaderBlue
    private let gapColor = Color.orange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("REPEATS & AVERAGE SONG GAP")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            // Tab selector
            Picker("Metric", selection: $selectedTab) {
                ForEach(MetricTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            // Content based on selected tab
            switch selectedTab {
            case .repeats:
                repeatsTabContent
            case .gap:
                gapTabContent
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .cardShadow, radius: 3, x: 0, y: 2)
        .onAppear {
            if !hasInitialized {
                selectedShow = repeats.shows.last
                hasInitialized = true
            }
        }
    }

    // MARK: - Repeats Tab Content

    private var repeatsTabContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if repeats.hasRepeats {
                // Show metadata and chart
                if let show = selectedShow {
                    selectedShowDetail(show, highlightMetric: .repeats)
                }
                repeatsChart
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            } else {
                // No repeats message
                noRepeatsMessage
            }
        }
    }

    // MARK: - Gap Tab Content

    private var gapTabContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let show = selectedShow {
                selectedShowDetail(show, highlightMetric: .gap)
            }
            gapChart
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
    }

    // MARK: - No Repeats Message

    private var noRepeatsMessage: some View {
        VStack(spacing: 12) {
            Text("NO REPEATS")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.appHeaderBlue)

            Text("Every song unique across \(repeats.totalShows) shows")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Repeats Chart

    private var repeatsChart: some View {
        Chart {
            ForEach(repeats.shows) { show in
                LineMark(
                    x: .value("Date", show.date),
                    y: .value("Repeats", show.repeatPercentage)
                )
                .foregroundStyle(repeatsColor.gradient)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", show.date),
                    y: .value("Repeats", show.repeatPercentage)
                )
                .foregroundStyle(repeatsColor)
                .symbolSize(selectedShow?.id == show.id ? 120 : 50)
            }

            if let show = selectedShow {
                RuleMark(x: .value("Selected", show.date))
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisTick()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text("\(Int(val))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: 0...(calculateRepeatsYAxisMax()))
        .frame(height: 180)
        .chartOverlay { proxy in
            chartOverlayGesture(proxy: proxy)
        }
    }

    // MARK: - Gap Chart

    private var gapChart: some View {
        Chart {
            ForEach(repeats.shows) { show in
                LineMark(
                    x: .value("Date", show.date),
                    y: .value("Avg Gap", show.averageGap)
                )
                .foregroundStyle(gapColor.gradient)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", show.date),
                    y: .value("Avg Gap", show.averageGap)
                )
                .foregroundStyle(gapColor)
                .symbolSize(selectedShow?.id == show.id ? 120 : 50)
            }

            if let show = selectedShow {
                RuleMark(x: .value("Selected", show.date))
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisTick()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text("\(Int(val))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: 0...(calculateGapYAxisMax()))
        .frame(height: 180)
        .chartOverlay { proxy in
            chartOverlayGesture(proxy: proxy)
        }
    }

    // MARK: - Chart Overlay Gesture

    private func chartOverlayGesture(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateSelection(at: value.location, proxy: proxy, geometry: geometry)
                        }
                        .onEnded { _ in }
                )
                .onTapGesture { location in
                    updateSelection(at: location, proxy: proxy, geometry: geometry)
                }
        }
    }

    // MARK: - Selected Show Detail

    private func selectedShowDetail(_ show: RepeatShowData, highlightMetric: MetricTab) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header row: Date and Tour Position
            HStack {
                Text(show.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if let tourPosition = show.tourPositionText {
                    Text("Show \(tourPosition)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(show.venueDisplayText)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(show.cityStateText)
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 4)

            // Stats row based on highlighted metric
            if highlightMetric == .repeats {
                repeatsStatsRow(show)
            } else {
                gapStatsRow(show)
            }
        }
        .padding(12)
        .background(Color.pageBackground)
        .cornerRadius(8)
    }

    private func repeatsStatsRow(_ show: RepeatShowData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Songs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(show.totalSongs)")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            VStack(alignment: .center, spacing: 2) {
                Text("Repeats")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(show.repeats)")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Repeated")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(show.repeatPercentageText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(repeatsColor)
            }
        }
    }

    private func gapStatsRow(_ show: RepeatShowData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Songs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(show.totalSongs)")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Avg Song Gap")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(show.averageGapText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(gapColor)
            }
        }
    }

    // MARK: - Helper Methods

    private func calculateRepeatsYAxisMax() -> Double {
        let maxValue = repeats.maxPercentage
        return max(10, ceil(maxValue / 10) * 10)
    }

    private func calculateGapYAxisMax() -> Double {
        let maxValue = repeats.maxAverageGap
        return max(10, ceil(maxValue / 10) * 10)
    }

    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x

        guard !repeats.shows.isEmpty else { return }

        let plotWidth = geometry[proxy.plotFrame!].width
        let showCount = repeats.shows.count
        let segmentWidth = plotWidth / CGFloat(showCount - 1)

        let index = min(max(0, Int(round(xPosition / segmentWidth))), showCount - 1)
        selectedShow = repeats.shows[index]
    }
}

// MARK: - Preview

#Preview("With Repeats") {
    ScrollView {
        RepeatsGraphCard(
            repeats: RepeatsStats(
                shows: [
                    RepeatShowData(date: "2025-07-20", venue: "MSG", city: "New York", state: "NY", venueRun: "N1", totalSongs: 20, repeats: 0, repeatPercentage: 0, averageGap: 12.5, showNumber: 1, totalTourShows: 4),
                    RepeatShowData(date: "2025-07-21", venue: "MSG", city: "New York", state: "NY", venueRun: "N2", totalSongs: 22, repeats: 5, repeatPercentage: 22.7, averageGap: 15.2, showNumber: 2, totalTourShows: 4),
                    RepeatShowData(date: "2025-07-22", venue: "MSG", city: "New York", state: "NY", venueRun: "N3", totalSongs: 21, repeats: 8, repeatPercentage: 38.1, averageGap: 18.7, showNumber: 3, totalTourShows: 4),
                    RepeatShowData(date: "2025-07-23", venue: "MSG", city: "New York", state: "NY", venueRun: "N4", totalSongs: 23, repeats: 10, repeatPercentage: 43.5, averageGap: 14.3, showNumber: 4, totalTourShows: 4)
                ],
                hasRepeats: true,
                maxPercentage: 43.5,
                maxAverageGap: 18.7,
                totalShows: 4
            )
        )
        .padding()
    }
    .background(Color.pageBackground)
}

#Preview("No Repeats") {
    ScrollView {
        RepeatsGraphCard(
            repeats: RepeatsStats(
                shows: [
                    RepeatShowData(date: "2025-12-28", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N1", totalSongs: 18, repeats: 0, repeatPercentage: 0, averageGap: 15.2, showNumber: 1, totalTourShows: 4),
                    RepeatShowData(date: "2025-12-29", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N2", totalSongs: 19, repeats: 0, repeatPercentage: 0, averageGap: 18.9, showNumber: 2, totalTourShows: 4),
                    RepeatShowData(date: "2025-12-30", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N3", totalSongs: 18, repeats: 0, repeatPercentage: 0, averageGap: 16.4, showNumber: 3, totalTourShows: 4),
                    RepeatShowData(date: "2025-12-31", venue: "Madison Square Garden", city: "New York", state: "NY", venueRun: "N4", totalSongs: 27, repeats: 0, repeatPercentage: 0, averageGap: 17.4, showNumber: 4, totalTourShows: 4)
                ],
                hasRepeats: false,
                maxPercentage: 0,
                maxAverageGap: 18.9,
                totalShows: 4
            )
        )
        .padding()
    }
    .background(Color.pageBackground)
}
