import Foundation

struct UptimeHistoryResponse: Codable {
    let data: [UptimeHistoryResult]
}

struct UptimeHistoryResult: Codable, Identifiable {
    let createdAt: Date
    let location: String?
    let performance: Int?
    let statusCode: Int?

    var id: String { "\(createdAt.timeIntervalSince1970)-\(location ?? "")" }

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case location
        case performance
        case statusCode = "status_code"
    }
}

struct UptimeAlertsResponse: Codable {
    let data: [UptimeAlert]
}

struct UptimeAlert: Codable, Identifiable {
    let alertId: String
    let status: String
    let statusCode: Int
    let triggeredAt: Date?

    var id: String { "\(alertId)-\(status)-\(triggeredAt?.timeIntervalSince1970 ?? 0)" }

    enum CodingKeys: String, CodingKey {
        case alertId = "id"
        case status
        case statusCode = "status_code"
        case triggeredAt = "triggered_at"
    }
}
