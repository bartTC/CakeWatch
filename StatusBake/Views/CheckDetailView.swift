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
    @State private var isEditingFindString = false
    @State private var editingFindString = ""
    @State private var isEditingHost = false
    @State private var editingHost = ""
    @State private var isEditingPort = false
    @State private var editingPort = ""
    @State private var isEditingUserAgent = false
    @State private var editingUserAgent = ""
    @State private var isEditingStatusCodes = false
    @State private var editingStatusCodes: [String] = []
    @State private var newStatusCode = ""
    @State private var isEditingBasicUsername = false
    @State private var editingBasicUsername = ""
    @State private var isEditingBasicPassword = false
    @State private var editingBasicPassword = ""

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
        .navigationTitle(detail.name)
        .task(id: detail.id) {
            isEditingName = false
            if selectedTab == "statistics" { onFetchStatistics?() }
        }
        .onChange(of: selectedTab) {
            if selectedTab == "statistics" { onFetchStatistics?() }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Tab", selection: $selectedTab) {
                    Text("Statistics").tag("statistics")
                    Text("Details").tag("details")
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    NSWorkspace.shared.open(URL(string: "https://app.statuscake.com/UptimeStatus.php?tid=\(detail.id)")!)
                } label: {
                    Label("Open in StatusCake", systemImage: "safari")
                }
                .help("Open in StatusCake")
                Button {
                    onUpdate?("paused", detail.paused ? "false" : "true")
                } label: {
                    Label(detail.paused ? "Resume" : "Pause", systemImage: detail.paused ? "play.fill" : "pause.fill")
                }
                .help(detail.paused ? "Resume check" : "Pause check")
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
            Toggle("Follow Redirects", isOn: Binding(
                get: { detail.followRedirects ?? false },
                set: { onUpdate?("follow_redirects", $0 ? "true" : "false") }
            ))
            Toggle("Enable SSL Alert", isOn: Binding(
                get: { detail.enableSslAlert ?? false },
                set: { onUpdate?("enable_ssl_alert", $0 ? "true" : "false") }
            ))
            editableTextField(label: "Find String", value: detail.findString ?? "", field: "find_string", isEditing: $isEditingFindString, editingValue: $editingFindString)
            Toggle("Do Not Find", isOn: Binding(
                get: { detail.doNotFind ?? false },
                set: { onUpdate?("do_not_find", $0 ? "true" : "false") }
            ))
            Toggle("Include Header", isOn: Binding(
                get: { detail.includeHeader ?? false },
                set: { onUpdate?("include_header", $0 ? "true" : "false") }
            ))
            editableTextField(label: "Host", value: detail.host ?? "", field: "host", isEditing: $isEditingHost, editingValue: $editingHost)
            editableTextField(label: "Port", value: detail.port.map { "\($0)" } ?? "", field: "port", isEditing: $isEditingPort, editingValue: $editingPort)
            editableTextField(label: "User Agent", value: detail.userAgent ?? "", field: "user_agent", isEditing: $isEditingUserAgent, editingValue: $editingUserAgent)
            statusCodesField
            Toggle("Use Cookie Jar", isOn: Binding(
                get: { detail.useJar ?? false },
                set: { onUpdate?("use_jar", $0 ? "true" : "false") }
            ))
            editableTextField(label: "Basic Auth Username", value: detail.basicUsername ?? "", field: "basic_username", isEditing: $isEditingBasicUsername, editingValue: $editingBasicUsername)
            editableTextField(label: "Basic Auth Password", value: detail.basicPassword ?? "", field: "basic_password", isEditing: $isEditingBasicPassword, editingValue: $editingBasicPassword)
        } header: {
            Text("Advanced").font(.headline)
        }
    }

    @ViewBuilder
    private var statusCodesField: some View {
        let codes = detail.statusCodes ?? []
        if isEditingStatusCodes {
            Section {
                ForEach(editingStatusCodes, id: \.self) { code in
                    HStack {
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button {
                            editingStatusCodes.removeAll { $0 == code }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    TextField("Add code", text: $newStatusCode)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit {
                            let trimmed = newStatusCode.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty && !editingStatusCodes.contains(trimmed) {
                                editingStatusCodes.append(trimmed)
                                newStatusCode = ""
                            }
                        }
                }
                HStack {
                    Button("Cancel") {
                        isEditingStatusCodes = false
                        newStatusCode = ""
                    }
                    Spacer()
                    Button("Save") {
                        let csv = editingStatusCodes.joined(separator: ",")
                        if csv != codes.joined(separator: ",") {
                            onUpdate?("status_codes_csv", csv)
                        }
                        isEditingStatusCodes = false
                        newStatusCode = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } header: {
                Text("Status Codes").font(.headline)
            }
        } else {
            LabeledContent {
                HStack(alignment: .top) {
                    if codes.isEmpty {
                        Text("—").foregroundStyle(.tertiary)
                    } else {
                        FlowLayout(spacing: 4) {
                            ForEach(codes, id: \.self) { code in
                                Text(code)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    Button {
                        editingStatusCodes = codes
                        isEditingStatusCodes = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            } label: {
                Text("Status Codes")
            }
        }
    }

    @ViewBuilder
    private func editableTextField(label: String, value: String, field: String, isEditing: Binding<Bool>, editingValue: Binding<String>) -> some View {
        LabeledContent(label) {
            if isEditing.wrappedValue {
                TextField("", text: editingValue)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if editingValue.wrappedValue != value {
                            onUpdate?(field, editingValue.wrappedValue)
                        }
                        isEditing.wrappedValue = false
                    }
                    .onExitCommand { isEditing.wrappedValue = false }
            } else {
                HStack(spacing: 4) {
                    Text(value.isEmpty ? "—" : value)
                        .foregroundStyle(value.isEmpty ? .tertiary : .primary)
                    Image(systemName: "pencil")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
                .onTapGesture(count: 2) {
                    editingValue.wrappedValue = value
                    isEditing.wrappedValue = true
                }
            }
        }
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
