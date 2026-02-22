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

    // Accounts
    var accounts: [Account] = []

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
    var periods: [UptimePeriod] = []
    var periodsNextURL: String?
    var isLoadingStatistics = false
    var isLoadingMorePeriods = false

    private let api = StatusCakeAPI.shared

    // MARK: - Account Management

    func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: "accounts"),
           let decoded = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = decoded
        } else if let legacyKey = UserDefaults.standard.string(forKey: "apiKey"), !legacyKey.isEmpty {
            // Migrate legacy single API key
            let account = Account(name: "Default", apiKey: legacyKey)
            accounts = [account]
            saveAccounts()
            UserDefaults.standard.removeObject(forKey: "apiKey")
        }
    }

    func saveAccounts() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: "accounts")
        }
    }

    func accountForCheck(_ checkId: String) -> Account? {
        if let check = checks.first(where: { $0.id == checkId }) {
            return accounts.first { $0.id == check.accountId }
        }
        if let d = detail, d.id == checkId {
            return accounts.first { $0.id == d.accountId }
        }
        return nil
    }

    private func apiKeyForCheck(_ checkId: String) -> String? {
        // Check in overview list
        if let check = checks.first(where: { $0.id == checkId }) {
            return accounts.first { $0.id == check.accountId }?.apiKey
        }
        // Check in detail
        if let d = detail, d.id == checkId {
            return accounts.first { $0.id == d.accountId }?.apiKey
        }
        // Check in selected details
        if let d = selectedDetails.first(where: { $0.id == checkId }) {
            return accounts.first { $0.id == d.accountId }?.apiKey
        }
        return nil
    }

    // MARK: - Fetching

    func fetchChecks() async {
        isLoading = true
        var allChecks: [UptimeCheckOverview] = []
        var errors: [String] = []

        for account in accounts {
            do {
                var accountChecks = try await api.listChecks(apiKey: account.apiKey)
                for i in accountChecks.indices {
                    accountChecks[i].accountId = account.id
                    accountChecks[i].accountName = account.name
                }
                allChecks.append(contentsOf: accountChecks)
            } catch {
                errors.append("\(account.name): \(error.localizedDescription)")
            }
        }

        checks = allChecks
        if !errors.isEmpty {
            self.error = errors.joined(separator: "\n")
        }
        isLoading = false
    }

    func fetchDetail(id: String) async {
        guard let apiKey = apiKeyForCheck(id) else {
            self.error = "No account found for this check."
            return
        }
        do {
            var d = try await api.getCheck(id: id, apiKey: apiKey)
            if let check = checks.first(where: { $0.id == id }) {
                d.accountId = check.accountId
                d.accountName = check.accountName
            }
            detail = d
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
            if let apiKey = apiKeyForCheck(id) {
                if var d = try? await api.getCheck(id: id, apiKey: apiKey) {
                    if let check = checks.first(where: { $0.id == id }) {
                        d.accountId = check.accountId
                        d.accountName = check.accountName
                    }
                    selectedDetails.append(d)
                }
            }
            fetchDetailsCompleted += 1
            fetchDetailsProgress = Double(fetchDetailsCompleted) / Double(fetchDetailsTotal)
        }

        if !Task.isCancelled {
            isFetchingDetails = false
        }
    }

    func fetchStatistics(id: String) async {
        guard let apiKey = apiKeyForCheck(id) else {
            self.error = "No account found for this check."
            return
        }
        isLoadingStatistics = true
        async let h = api.getHistory(id: id, apiKey: apiKey)
        async let p = api.getPeriods(id: id, apiKey: apiKey)
        do {
            history = try await h
            let periodsPage = try await p
            periods = periodsPage.periods
            periodsNextURL = periodsPage.nextURL
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingStatistics = false
    }

    func loadMorePeriods(id: String) async {
        guard let nextURL = periodsNextURL, let apiKey = apiKeyForCheck(id) else { return }
        isLoadingMorePeriods = true
        do {
            let page = try await api.getMorePeriods(nextURL: nextURL, apiKey: apiKey)
            periods.append(contentsOf: page.periods)
            periodsNextURL = page.nextURL
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingMorePeriods = false
    }

    func createCheck(fields: [String: String], accountId: String) async {
        guard let account = accounts.first(where: { $0.id == accountId }) else {
            self.error = "Account not found."
            return
        }
        do {
            let newId = try await api.createCheck(fields: fields, apiKey: account.apiKey)
            await fetchChecks()
            selectedChecks = [newId]
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateField(id: String, fields: [String: String]) async {
        guard let apiKey = apiKeyForCheck(id) else {
            self.error = "No account found for this check."
            return
        }
        do {
            try await api.updateCheck(id: id, fields: fields, apiKey: apiKey)
            await fetchDetail(id: id)
            await fetchChecks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func batchUpdate(fields: [String: String]) async {
        // Check if selected checks span multiple accounts
        let accountIds = Set(selectedChecks.compactMap { id in
            checks.first(where: { $0.id == id })?.accountId
        })
        if accountIds.count > 1 {
            self.error = "Cannot batch update checks from different accounts. Please select checks from a single account."
            return
        }

        await runBatchOperation(ids: selectedChecks) { id in
            guard let apiKey = self.apiKeyForCheck(id) else { return }
            try await self.api.updateCheck(id: id, fields: fields, apiKey: apiKey)
        }
        if error == nil {
            await fetchSelectedDetails()
            await fetchChecks()
        }
    }

    func deleteSelected() async {
        // Check if selected checks span multiple accounts
        let accountIds = Set(selectedChecks.compactMap { id in
            checks.first(where: { $0.id == id })?.accountId
        })
        if accountIds.count > 1 {
            self.error = "Cannot delete checks from different accounts at once. Please select checks from a single account."
            return
        }

        let ids = selectedChecks
        await runBatchOperation(ids: ids) { id in
            guard let apiKey = self.apiKeyForCheck(id) else { return }
            try await self.api.deleteCheck(id: id, apiKey: apiKey)
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
