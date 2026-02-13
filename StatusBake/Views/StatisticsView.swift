import SwiftUI
import Charts

struct StatisticsView: View {
    let checkId: String
    let history: [UptimeHistoryResult]
    let alerts: [UptimeAlert]
    let isLoading: Bool

    var body: some View {
        if isLoading {
            ProgressView("Loading statistics…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    responseTimeChart
                    alertsTable
                    HStack {
                        Spacer()
                        Link(destination: URL(string: "https://app.statuscake.com/UptimeStatus.php?tid=\(checkId)")!) {
                            Label("View on StatusCake", systemImage: "safari")
                        }
                    }
                }
                .padding()
            }
        }
    }

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

    @ViewBuilder
    private var alertsTable: some View {
        Text("Alerts").font(.headline)
        if alerts.isEmpty {
            Text("No alerts recorded.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            Table(alerts) {
                TableColumn("Triggered") { alert in
                    if let date = alert.triggeredAt {
                        Text(date, format: .dateTime)
                    } else {
                        Text("—").foregroundStyle(.secondary)
                    }
                }
                TableColumn("Status") { alert in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(alert.status == "up" ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(alert.status.capitalized)
                    }
                }
                .width(100)
                TableColumn("Status Code") { alert in
                    Text("\(alert.statusCode)")
                }
                .width(80)
            }
            .frame(minHeight: 200)
        }
    }
}
