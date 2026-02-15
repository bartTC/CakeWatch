import SwiftUI

struct ContentView: View {
    @State private var viewModel = UptimeViewModel()
    @AppStorage("apiKey") private var apiKey = ""
    @State private var showSettings = false
    @State private var filterText = ""
    @State private var sortOrder = [KeyPathComparator(\UptimeCheckOverview.name)]
    @State private var selectedDetailTab = "statistics"
    @State private var fetchDetailsTask: Task<Void, Never>?

    private var sortedChecks: [UptimeCheckOverview] {
        filteredChecks.sorted(using: sortOrder)
    }

    private var filteredChecks: [UptimeCheckOverview] {
        if filterText.isEmpty { return viewModel.checks }
        return viewModel.checks.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
    }

    var body: some View {
        NavigationSplitView {
            Table(sortedChecks, selection: $viewModel.selectedChecks, sortOrder: $sortOrder) {
                TableColumn("", value: \.sortableStatus) { check in
                    Circle()
                        .fill(check.paused ? .gray : check.status == "up" ? .green : .red)
                        .frame(width: 8, height: 8)
                }
                .width(20)

                TableColumn("Name", value: \.name) { check in
                    Text(check.name)
                        .foregroundStyle(check.paused ? .secondary : .primary)
                        .opacity(check.paused ? 0.6 : 1.0)
                }

                TableColumn("Uptime", value: \.sortableUptime) { check in
                    if let uptime = check.uptime {
                        if check.paused {
                            Text(String(format: "%.1f%%", uptime))
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            HStack(spacing: 4) {
                                Spacer()
                                Circle()
                                    .fill(uptimeColor(uptime))
                                    .frame(width: 6, height: 6)
                                Text(String(format: "%.1f%%", uptime))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .width(100)
            }
            .searchable(text: $filterText, placement: .sidebar, prompt: "Filter checks")
            .onChange(of: filterText) { viewModel.selectedChecks.removeAll() }
            .navigationSplitViewColumnWidth(min: 300, ideal: 400)
            .toolbar {
                ToolbarItem {
                    Button(action: { viewModel.showCreateSheet = true }) {
                        Label("New Check", systemImage: "plus")
                    }
                    .help("Create new check")
                }
                ToolbarItem {
                    Button(action: { Task { await viewModel.fetchChecks() } }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .help("Refresh checks")
                }
                ToolbarItem {
                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                    .help("Settings")
                }
            }
        } detail: {
            if viewModel.selectedChecks.count > 1 && viewModel.isFetchingDetails {
                VStack(spacing: 12) {
                    Text("Loading \(viewModel.fetchDetailsCompleted) of \(viewModel.fetchDetailsTotal) checks…")
                        .font(.headline)
                    ProgressView(value: viewModel.fetchDetailsProgress)
                        .frame(width: 200)
                    Button("Cancel") {
                        fetchDetailsTask?.cancel()
                        viewModel.isFetchingDetails = false
                        viewModel.selectedChecks.removeAll()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.selectedChecks.count > 1 && !viewModel.selectedDetails.isEmpty {
                BatchConfigView(details: viewModel.selectedDetails, onBatchUpdate: { field, value in
                    Task { await viewModel.batchUpdate(fields: [field: value]) }
                }, onDelete: {
                    viewModel.showDeleteConfirmation = true
                })
            } else if let detail = viewModel.detail {
                CheckDetailView(detail: detail, onDelete: {
                    viewModel.showDeleteConfirmation = true
                }, onUpdate: { field, value in
                    Task { await viewModel.updateField(id: detail.id, fields: [field: value]) }
                }, history: viewModel.history, alerts: viewModel.alerts, isLoadingStatistics: viewModel.isLoadingStatistics, onFetchStatistics: {
                    Task { await viewModel.fetchStatistics(id: detail.id) }
                }, selectedTab: $selectedDetailTab)
            } else {
                Text("Select a check")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $viewModel.showDeleteConfirmation) {
            let names = viewModel.checks.filter { viewModel.selectedChecks.contains($0.id) }.map(\.name)
            VStack(alignment: .leading, spacing: 12) {
                Text(names.count == 1 ? "Delete Check" : "Delete \(names.count) Checks")
                    .font(.headline)
                Text("The following will be permanently deleted:")
                    .foregroundStyle(.secondary)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(names, id: \.self) { name in
                            Text(name)
                            if name != names.last {
                                Divider()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 300)
                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        viewModel.showDeleteConfirmation = false
                    }
                    .keyboardShortcut(.cancelAction)
                    Button("Delete", role: .destructive) {
                        viewModel.showDeleteConfirmation = false
                        Task { await viewModel.deleteSelected() }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .frame(width: 350)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: showSettings) {
            if !showSettings { Task { await viewModel.fetchChecks() } }
        }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreateCheckView { fields in
                await viewModel.createCheck(fields: fields)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onAppear {
            if apiKey.isEmpty {
                showSettings = true
            } else {
                Task { await viewModel.fetchChecks() }
            }
        }
        .onChange(of: viewModel.selectedChecks) {
            if viewModel.selectedChecks.count == 1, let id = viewModel.selectedChecks.first {
                viewModel.selectedDetails = []
                Task { await viewModel.fetchDetail(id: id) }
            } else if viewModel.selectedChecks.count > 1 {
                viewModel.detail = nil
                fetchDetailsTask?.cancel()
                fetchDetailsTask = Task { await viewModel.fetchSelectedDetails() }
            } else {
                viewModel.detail = nil
                viewModel.selectedDetails = []
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
            if viewModel.isBatchOperating {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("Updating \(viewModel.batchCompleted) of \(viewModel.batchTotal)...")
                            .font(.headline)
                        ProgressView(value: viewModel.batchProgress)
                            .frame(width: 200)
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .disabled(viewModel.isBatchOperating)
    }

    private func uptimeColor(_ uptime: Double) -> Color {
        if uptime >= 100 { return .green }
        if uptime >= 99 { return .yellow }
        if uptime >= 90 { return .orange }
        return .red
    }
}
