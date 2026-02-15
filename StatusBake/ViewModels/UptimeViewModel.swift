import Foundation

@Observable
final class UptimeViewModel {
    var checks: [UptimeCheckOverview] = []
    var selectedChecks: Set<String> = []
    var isLoading = false
    var error: String?
    var detail: UptimeCheckDetail?
    var selectedDetails: [UptimeCheckDetail] = []
    var showDeleteConfirmation = false
    var showCreateSheet = false

    // Batch operations
    var isBatchOperating = false
    var batchProgress = 0.0
    var batchTotal = 0
    var batchCompleted = 0

    // Multi-select detail fetching
    var isFetchingDetails = false
    var fetchDetailsProgress = 0.0
    var fetchDetailsTotal = 0
    var fetchDetailsCompleted = 0

    // Statistics
    var history: [UptimeHistoryResult] = []
    var alerts: [UptimeAlert] = []
    var isLoadingStatistics = false

    private let api = StatusCakeAPI.shared

    func fetchChecks() async {
        isLoading = true
        do {
            checks = try await api.listChecks()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func fetchDetail(id: String) async {
        do {
            detail = try await api.getCheck(id: id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func fetchSelectedDetails() async {
        selectedDetails = []
        let ids = selectedChecks
        fetchDetailsTotal = ids.count
        fetchDetailsCompleted = 0
        fetchDetailsProgress = 0
        isFetchingDetails = true

        for id in ids {
            guard !Task.isCancelled else { break }
            if let detail = try? await api.getCheck(id: id) {
                selectedDetails.append(detail)
            }
            fetchDetailsCompleted += 1
            fetchDetailsProgress = Double(fetchDetailsCompleted) / Double(fetchDetailsTotal)
        }

        if !Task.isCancelled {
            isFetchingDetails = false
        }
    }

    func fetchStatistics(id: String) async {
        isLoadingStatistics = true
        async let h = api.getHistory(id: id)
        async let a = api.getAlerts(id: id)
        do {
            history = try await h
            alerts = try await a
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingStatistics = false
    }

    func createCheck(fields: [String: String]) async {
        do {
            let newId = try await api.createCheck(fields: fields)
            await fetchChecks()
            selectedChecks = [newId]
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateField(id: String, fields: [String: String]) async {
        do {
            try await api.updateCheck(id: id, fields: fields)
            await fetchDetail(id: id)
            await fetchChecks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func batchUpdate(fields: [String: String]) async {
        await runBatchOperation(ids: selectedChecks) { id in
            try await self.api.updateCheck(id: id, fields: fields)
        }
        if error == nil {
            await fetchSelectedDetails()
            await fetchChecks()
        }
    }

    func deleteSelected() async {
        let ids = selectedChecks
        await runBatchOperation(ids: ids) { id in
            try await self.api.deleteCheck(id: id)
        }
        selectedChecks.removeAll()
        detail = nil
        if error == nil {
            await fetchChecks()
        }
    }

    private func runBatchOperation(ids: Set<String>, operation: @escaping (String) async throws -> Void) async {
        isBatchOperating = true
        batchTotal = ids.count
        batchCompleted = 0
        batchProgress = 0
        var errors: [String] = []

        for id in ids {
            do {
                try await operation(id)
            } catch {
                let name = checks.first(where: { $0.id == id })?.name ?? id
                errors.append("\(name): \(error.localizedDescription)")
            }
            batchCompleted += 1
            batchProgress = Double(batchCompleted) / Double(batchTotal)
        }

        isBatchOperating = false
        if !errors.isEmpty {
            self.error = errors.joined(separator: "\n")
        }
    }
}
