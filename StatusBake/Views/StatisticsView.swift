import SwiftUI
import Charts

struct StatisticsView: View {
    let checkId: String
    let checkName: String
    let websiteUrl: String
    let history: [UptimeHistoryResult]
    let periods: [UptimePeriod]
    let hasMorePeriods: Bool
    let isLoadingMorePeriods: Bool
    var onLoadMorePeriods: (() -> Void)?
    let isLoading: Bool
    var uptime: Double?

    // MARK: - Computed Properties

    private var performanceValues: [Int] {
        history.compactMap(\.performance)
    }

    private var avgResponseTime: Double? {
        guard !performanceValues.isEmpty else { return nil }
        return Double(performanceValues.reduce(0, +)) / Double(performanceValues.count)
    }

    private var minResponseTime: Int? { performanceValues.min() }
    private var maxResponseTime: Int? { performanceValues.max() }

    private var p95ResponseTime: Int? {
        guard !performanceValues.isEmpty else { return nil }
        let sorted = performanceValues.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }

    private var currentStatus: String? {
        periods.first?.status
    }

    private var downtimePeriods: [UptimePeriod] {
        periods.filter { $0.status == "down" }
    }

    private var totalDowntime: TimeInterval {
        downtimePeriods.compactMap { $0.duration.map { Double($0) / 1000.0 } }.reduce(0, +)
    }

    private var meanTimeToRecovery: TimeInterval? {
        let durations = downtimePeriods.compactMap { $0.duration.map { Double($0) / 1000.0 } }
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    // MARK: - Body

    var body: some View {
        if isLoading {
            ProgressView("Loading statistics…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(checkName).font(.title2.bold())
                        if let url = URL(string: websiteUrl) {
                            Link(websiteUrl, destination: url)
                                .font(.subheadline)
                        } else {
                            Text(websiteUrl)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Divider()
                    responseTimeChart
                    Divider()
                    downtimeTimeline
                }
                .padding()
            }
        }
    }

    // MARK: - Response Time Chart

    @ViewBuilder
    private var responseTimeChart: some View {
        Text("Response Times").font(.headline)
        if history.isEmpty {
            Text("No history data available.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            Chart(history) { entry in
                if let ms = entry.performance {
                    LineMark(
                        x: .value("Time", entry.createdAt),
                        y: .value("Response (ms)", ms)
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxisLabel("ms")
            .frame(height: 200)
        }
    }

    // MARK: - Downtime Timeline

    @ViewBuilder
    private var downtimeTimeline: some View {
        Text("Downtime History").font(.headline)
        if downtimePeriods.isEmpty {
            Text("No downtime recorded.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Current status
                HStack(spacing: 10) {
                    Circle()
                        .fill(currentStatus == "down" ? .red : .green)
                        .frame(width: 12, height: 12)
                    Text("Currently \(currentStatus == "down" ? "Down" : "Up")")
                        .font(.body.bold())
                        .foregroundStyle(currentStatus == "down" ? .red : .green)
                }
                // Downtime periods
                let maxDuration = downtimePeriods.compactMap(\.duration).max() ?? 1
                ForEach(downtimePeriods) { period in
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(width: 2, height: 40)
                            .padding(.leading, 5)
                    }
                    HStack(spacing: 10) {
                        Circle()
                            .fill(.red)
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                if let durationMs = period.duration {
                                    Text("Down for \(formatDuration(Double(durationMs) / 1000.0))")
                                        .font(.body)
                                } else {
                                    Text("Down since \(period.createdAt, format: .dateTime)")
                                        .font(.body)
                                }
                                Spacer()
                                Text(period.createdAt, format: .dateTime)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            // Severity bar
                            if let durationMs = period.duration {
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(.red.opacity(0.6))
                                        .frame(width: max(geo.size.width * 0.5 * (Double(durationMs) / Double(maxDuration)), 4))
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                }
                if hasMorePeriods {
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(width: 2, height: 40)
                            .padding(.leading, 5)
                    }
                    if isLoadingMorePeriods {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Button("Load More") {
                            onLoadMorePeriods?()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let years = total / 31_536_000
        let days = (total % 31_536_000) / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60

        if years > 0 {
            return "\(years)y \(days)d \(hours)h"
        } else if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(total)s"
        }
    }
}

// MARK: - StatCell

private struct StatCell: View {
    let label: String
    let value: String
    var valueColor: Color?

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(valueColor ?? .primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}
