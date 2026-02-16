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
    #if os(macOS)
    @State var isEditingName = false
    @State var editingName = ""
    @State var isEditingStatusCodes = false
    @State var editingStatusCodes: [String] = []
    @State var newStatusCode = ""
    @State var isEditingTags = false
    @State var editingTags: [String] = []
    @State var newTag = ""
    #endif

    var body: some View {
        Group {
            if selectedTab == "statistics" {
                StatisticsView(checkId: detail.id, checkName: detail.name, websiteUrl: detail.websiteUrl, history: history, alerts: alerts, isLoading: isLoadingStatistics, uptime: detail.uptime)
            } else {
                Form {
                    generalSection
                    configurationSection
                    advancedSection
                }
                .formStyle(.grouped)
            }
        }
        .task(id: detail.id) {
            #if os(macOS)
            isEditingName = false
            #endif
            if selectedTab == "statistics" { onFetchStatistics?() }
        }
        .onChange(of: selectedTab) {
            if selectedTab == "statistics" { onFetchStatistics?() }
        }
    }

    @ViewBuilder
    private var generalSection: some View {
        Section {
            nameField
            LabeledContent("Status") {
                HStack {
                    Circle()
                        .fill(detail.status == "up" ? .green : .red)
                        .frame(width: 10, height: 10)
                    Text(detail.status.capitalized)
                }
            }
            LabeledContent("URL") {
                if let url = URL(string: detail.websiteUrl) {
                    Link(detail.websiteUrl, destination: url)
                } else {
                    Text(detail.websiteUrl)
                }
            }
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
            tagsField
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
            Toggle("Follow Redirects", isOn: Binding(
                get: { detail.followRedirects ?? false },
                set: { onUpdate?("follow_redirects", $0 ? "true" : "false") }
            ))
            Toggle("Enable SSL Alert", isOn: Binding(
                get: { detail.enableSslAlert ?? false },
                set: { onUpdate?("enable_ssl_alert", $0 ? "true" : "false") }
            ))
            editableField(label: "Find String", value: detail.findString ?? "", field: "find_string")
            Toggle("Do Not Find", isOn: Binding(
                get: { detail.doNotFind ?? false },
                set: { onUpdate?("do_not_find", $0 ? "true" : "false") }
            ))
            Toggle("Include Header", isOn: Binding(
                get: { detail.includeHeader ?? false },
                set: { onUpdate?("include_header", $0 ? "true" : "false") }
            ))
            editableField(label: "Host", value: detail.host ?? "", field: "host")
            editableField(label: "Port", value: detail.port.map { "\($0)" } ?? "", field: "port")
            editableField(label: "User Agent", value: detail.userAgent ?? "", field: "user_agent")
            statusCodesField
            Toggle("Use Cookie Jar", isOn: Binding(
                get: { detail.useJar ?? false },
                set: { onUpdate?("use_jar", $0 ? "true" : "false") }
            ))
            editableField(label: "Basic Auth Username", value: detail.basicUsername ?? "", field: "basic_username")
            editableField(label: "Basic Auth Password", value: detail.basicPassword ?? "", field: "basic_password")
        } header: {
            Text("Advanced").font(.headline)
        }
    }
}

extension View {
    @ViewBuilder
    func onEscapeKey(perform action: @escaping () -> Void) -> some View {
        #if os(macOS)
        self.onExitCommand(perform: action)
        #else
        self
        #endif
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight + (i > 0 ? spacing : 0)
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            if i > 0 { y += spacing }
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var x: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(subview)
            x += size.width + spacing
        }
        return rows
    }
}
