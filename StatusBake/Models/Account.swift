import Foundation

struct Account: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var apiKey: String
}
