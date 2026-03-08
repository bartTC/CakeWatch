import Foundation

enum KeychainHelper {
    private static let key = "accounts"

    static func loadAccounts() -> [Account]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([Account].self, from: data)
    }

    static func saveAccounts(_ accounts: [Account]) {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func deleteAccounts() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
