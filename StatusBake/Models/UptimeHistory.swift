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

struct PaginationLinks: Codable {
    let next: String?
}

struct UptimePeriodsResponse: Codable {
    let data: [UptimePeriod]
    let links: PaginationLinks?
}

struct UptimePeriod: Codable, Identifiable {
    let status: String
    let createdAt: Date
    let endedAt: Date?
    let duration: Int?

    var id: String { "\(createdAt.timeIntervalSince1970)-\(status)" }

    enum CodingKeys: String, CodingKey {
        case status
        case createdAt = "created_at"
        case endedAt = "ended_at"
        case duration
    }
}
