import Foundation
import Security

enum KeychainHelper {
    private static let service = "elephanthouse.StatusBake"
    private static let accountsKey = "accounts"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountsKey,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }

    static func loadAccounts() -> [Account]? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode([Account].self, from: data)
    }

    static func saveAccounts(_ accounts: [Account]) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }

        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess {
            SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        } else {
            var add = baseQuery
            add[kSecValueData as String] = data
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    static func deleteAccounts() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
