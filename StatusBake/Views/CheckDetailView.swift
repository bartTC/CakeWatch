import SwiftUI

struct CheckDetailView: View {
    let detail: UptimeCheckDetail
    var onDelete: (() -> Void)?
    var onUpdate: ((_ field: String, _ value: String) -> Void)?
    var history: [UptimeHistoryResult] = []
    var alerts: [UptimeAlert] = []
    var isLoadingStatistics = false
    var onFetchStatistics: (() -> Void)?
    @Binding var selectedTab: String
    @State private var isEditingName = false
    @State private var editingName = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Details", systemImage: "info.circle", value: "details") {
                Form {
                    generalSection
                    configurationSection
                    advancedSection
                }
                .formStyle(.grouped)
            }
            Tab("Statistics", systemImage: "chart.xyaxis.line", value: "statistics") {
                StatisticsView(checkId: detail.id, history: history, alerts: alerts, isLoading: isLoadingStatistics)
            }
        }
        .navigationTitle(detail.name)
        .onChange(of: detail.id) {
            isEditingName = false
            if selectedTab == "statistics" { onFetchStatistics?() }
        }
        .onChange(of: selectedTab) {
            if selectedTab == "statistics" { onFetchStatistics?() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Spacer()
                Button {
                    NSWorkspace.shared.open(URL(string: "https://app.statuscake.com/UptimeStatus.php?tid=\(detail.id)")!)
                } label: {
                    Label("Open in StatusCake", systemImage: "safari")
                }
                .help("Open in StatusCake")
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .help("Delete check")
            }
        }
    }

    @ViewBuilder
    private var generalSection: some View {
        Section {
            LabeledContent("Name") {
                if isEditingName {
                    TextField("", text: $editingName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if editingName != detail.name {
                                onUpdate?("name", editingName)
                            }
                            isEditingName = false
                        }
                        .onExitCommand {
                            isEditingName = false
                        }
                } else {
                    HStack(spacing: 4) {
                        Text(detail.name)
                        Image(systemName: "pencil")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .onTapGesture(count: 2) {
                        editingName = detail.name
                        isEditingName = true
                    }
                }
            }
            LabeledContent("Status") {
                HStack {
                    Circle()
                        .fill(detail.status == "up" ? .green : .red)
                        .frame(width: 10, height: 10)
                    Text(detail.status.capitalized)
                }
            }
            LabeledContent("URL", value: detail.websiteUrl)
            LabeledContent("Type", value: detail.testType)
            if let uptime = detail.uptime {
                LabeledContent("Uptime", value: String(format: "%.2f%%", uptime))
            }
            if let lastTested = detail.lastTestedAt {
                LabeledContent("Last Tested", value: lastTested)
            }
            Picker("Enabled", selection: Binding(
                get: { detail.paused ? "true" : "false" },
                set: { onUpdate?("paused", $0) }
            )) {
                Text("Yes").tag("false")
                Text("No").tag("true")
            }
            if !detail.tags.isEmpty {
                LabeledContent("Tags", value: detail.tags.joined(separator: ", "))
            }
        } header: {
            Text("General").font(.headline)
        }
    }

    @ViewBuilder
    private var configurationSection: some View {
        Section {
            Picker(selection: Binding(
                get: { detail.checkRate },
                set: { onUpdate?("check_rate", "\($0)") }
            )) {
                ForEach(checkRateOptions, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            } label: {
                HelpLabel(title: "Check Rate", helpText: "Number of seconds between checks")
            }

            Picker(selection: Binding(
                get: { detail.timeout ?? 15 },
                set: { onUpdate?("timeout", "\($0)") }
            )) {
                ForEach(timeoutOptions, id: \.self) { sec in
                    Text("\(sec)s").tag(sec)
                }
            } label: {
                HelpLabel(title: "Timeout", helpText: "The number of seconds to wait to receive the first byte")
            }

            Picker(selection: Binding(
                get: { detail.triggerRate ?? 0 },
                set: { onUpdate?("trigger_rate", "\($0)") }
            )) {
                ForEach(triggerRateOptions, id: \.self) { min in
                    Text(min == 0 ? "Immediately" : "\(min) min").tag(min)
                }
            } label: {
                HelpLabel(title: "Trigger Rate", helpText: "The number of minutes to wait before sending an alert")
            }

            Picker(selection: Binding(
                get: { detail.confirmation ?? 2 },
                set: { onUpdate?("confirmation", "\($0)") }
            )) {
                ForEach(confirmationRange, id: \.self) { count in
                    Text("\(count) server\(count == 1 ? "" : "s")").tag(count)
                }
            } label: {
                HelpLabel(title: "Confirmation", helpText: "Number of confirmation servers to confirm downtime before an alert is triggered")
            }
        } header: {
            Text("Configuration").font(.headline)
        }
    }

    @ViewBuilder
    private var advancedSection: some View {
        Section {
            if let followRedirects = detail.followRedirects {
                LabeledContent("Follow Redirects", value: followRedirects ? "Yes" : "No")
            }
            if let sslAlert = detail.enableSslAlert {
                LabeledContent("SSL Alert", value: sslAlert ? "Enabled" : "Disabled")
            }
            if let findString = detail.findString, !findString.isEmpty {
                LabeledContent("Find String", value: findString)
                if let doNotFind = detail.doNotFind {
                    LabeledContent("Do Not Find", value: doNotFind ? "Yes" : "No")
                }
            }
            if let host = detail.host, !host.isEmpty {
                LabeledContent("Host", value: host)
            }
            if let port = detail.port {
                LabeledContent("Port", value: "\(port)")
            }
            if let userAgent = detail.userAgent, !userAgent.isEmpty {
                LabeledContent("User Agent", value: userAgent)
            }
        } header: {
            Text("Advanced").font(.headline)
        }
    }
}
