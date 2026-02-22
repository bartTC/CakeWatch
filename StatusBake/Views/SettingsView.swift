import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("maxRequestsPerSecond") var maxRequestsPerSecond = 4

    @State var accounts: [Account] = []
    @State var editingAccount: Account?
    @State var isAddingAccount = false
    @State var editName = ""
    @State var editApiKey = ""
    @State var testResult: String?
    @State var isTesting = false

    var onAccountsChanged: (() -> Void)? = nil

    func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: "accounts"),
           let decoded = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = decoded
        }
    }

    func saveAccounts() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: "accounts")
        }
        onAccountsChanged?()
    }

    func startAdd() {
        editingAccount = nil
        editName = ""
        editApiKey = ""
        testResult = nil
        isAddingAccount = true
    }

    func startEdit(_ account: Account) {
        editingAccount = account
        editName = account.name
        editApiKey = account.apiKey
        testResult = nil
        isAddingAccount = true
    }

    func saveEdit() {
        if let existing = editingAccount,
           let index = accounts.firstIndex(where: { $0.id == existing.id }) {
            accounts[index].name = editName
            accounts[index].apiKey = editApiKey
        } else {
            accounts.append(Account(name: editName, apiKey: editApiKey))
        }
        saveAccounts()
        isAddingAccount = false
        editingAccount = nil
    }

    func deleteAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
    }

    func testConnection(apiKey: String) {
        isTesting = true
        testResult = nil
        Task {
            do {
                let checks = try await StatusCakeAPI.shared.listChecks(apiKey: apiKey)
                testResult = "Connected — \(checks.count) checks found."
            } catch {
                testResult = "Error: \(error.localizedDescription)"
            }
            isTesting = false
        }
    }

    var isEditValid: Bool {
        !editName.isEmpty && !editApiKey.isEmpty
    }

    func maskedKey(_ key: String) -> String {
        guard key.count > 6 else { return String(repeating: "•", count: key.count) }
        return String(key.prefix(3)) + String(repeating: "•", count: key.count - 6) + String(key.suffix(3))
    }

    @ViewBuilder
    var preferencesSection: some View {
        Section("Preferences") {
            Picker("Max Requests/Second", selection: $maxRequestsPerSecond) {
                Text("1/s (Free — safest)").tag(1)
                Text("2/s (Free — recommended)").tag(2)
                Text("3/s").tag(3)
                Text("4/s (Paid — recommended)").tag(4)
                Text("5/s (Paid — maximum)").tag(5)
            }
        }
    }
}
