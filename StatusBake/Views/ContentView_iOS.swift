import SwiftUI

#if os(iOS)
struct IOSContentView: View {
    @State private var viewModel = UptimeViewModel()
    @AppStorage("apiKey") private var apiKey = ""
    @State private var showSettings = false
    @State private var filterText = ""
    @State private var selectedDetailTab = "statistics"

    private var filteredChecks: [UptimeCheckOverview] {
        let checks = if filterText.isEmpty { viewModel.checks } else {
            viewModel.checks.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
        }
        return checks.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List(filteredChecks) { check in
                NavigationLink(value: check.id) {
                    HStack {
                        Circle()
                            .fill(check.paused ? .gray : check.status == "up" ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(check.name)
                            .foregroundStyle(check.paused ? .secondary : .primary)
                            .opacity(check.paused ? 0.6 : 1.0)
                        Spacer()
                        if let uptime = check.uptime {
                            if !check.paused {
                                Circle()
                                    .fill(uptimeColor(uptime))
                                    .frame(width: 6, height: 6)
                            }
                            Text(String(format: "%.1f%%", uptime))
                                .foregroundStyle(check.paused ? .tertiary : .secondary)
                                .font(.callout)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.fetchChecks() }
            .searchable(text: $filterText, prompt: "Filter checks")
            .navigationTitle("StatusBake")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { checkId in
                IOSCheckDetailContainer(checkId: checkId, viewModel: viewModel, selectedDetailTab: $selectedDetailTab)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.showCreateSheet = true }) {
                        Label("New Check", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { Task { await viewModel.fetchChecks() } }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showDeleteConfirmation) {
            DeleteConfirmationSheet(viewModel: viewModel)
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
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

/// Container that fetches detail and displays CheckDetailView when navigating on iOS.
private struct IOSCheckDetailContainer: View {
    let checkId: String
    @Bindable var viewModel: UptimeViewModel
    @Binding var selectedDetailTab: String

    var body: some View {
        Group {
            if let detail = viewModel.detail, detail.id == checkId {
                VStack(spacing: 0) {
                    Picker("Tab", selection: $selectedDetailTab) {
                        Text("Statistics").tag("statistics")
                        Text("Details").tag("details")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    CheckDetailView(detail: detail, onDelete: {
                        viewModel.showDeleteConfirmation = true
                    }, onUpdate: { field, value in
                        Task { await viewModel.updateField(id: detail.id, fields: [field: value]) }
                    }, history: viewModel.history, alerts: viewModel.alerts, isLoadingStatistics: viewModel.isLoadingStatistics, onFetchStatistics: {
                        Task { await viewModel.fetchStatistics(id: detail.id) }
                    }, selectedTab: $selectedDetailTab)
                    .frame(maxHeight: .infinity)
                    .refreshable {
                        await viewModel.fetchDetail(id: checkId)
                        if selectedDetailTab == "statistics" {
                            await viewModel.fetchStatistics(id: checkId)
                        }
                    }
                }
                .navigationTitle(detail.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Menu {
                            Link(destination: URL(string: "https://app.statuscake.com/UptimeStatus.php?tid=\(detail.id)")!) {
                                Label("Open in StatusCake", systemImage: "safari")
                            }
                            Button {
                                Task { await viewModel.updateField(id: detail.id, fields: ["paused": detail.paused ? "false" : "true"]) }
                            } label: {
                                Label(detail.paused ? "Resume" : "Pause", systemImage: detail.paused ? "play.fill" : "pause.fill")
                            }
                            Button(role: .destructive) {
                                viewModel.showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Label("Actions", systemImage: "ellipsis.circle")
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            viewModel.selectedChecks = [checkId]
            await viewModel.fetchDetail(id: checkId)
        }
    }
}
#endif
