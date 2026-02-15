import Foundation

struct UptimeTestsResponse: Codable {
    let data: [UptimeCheckOverview]
}

struct UptimeTestResponse: Codable {
    let data: UptimeCheckDetail
}

struct UptimeCheckOverview: Codable, Identifiable {
    let id: String
    let name: String
    let websiteUrl: String
    let testType: String
    let checkRate: Int
    let paused: Bool
    let status: String
    let tags: [String]
    let uptime: Double?

    var sortableUptime: Double { uptime ?? -1 }
    var sortableStatus: Int { paused ? 2 : status == "up" ? 0 : 1 }
}

struct UptimeCheckDetail: Codable, Identifiable {
    let id: String
    let name: String
    let websiteUrl: String
    let testType: String
    let checkRate: Int
    let paused: Bool
    let status: String
    let tags: [String]
    let uptime: Double?
    let confirmation: Int?
    let timeout: Int?
    let triggerRate: Int?
    let lastTestedAt: String?
    let followRedirects: Bool?
    let enableSslAlert: Bool?
    let findString: String?
    let doNotFind: Bool?
    let host: String?
    let port: Int?
    let userAgent: String?
    let statusCodes: [String]?
    let processing: Bool?
    let includeHeader: Bool?
    let useJar: Bool?
    let basicUsername: String?
    let basicPassword: String?
    let customHeader: String?
    let postBody: String?
    let postRaw: String?
    let finalEndpoint: String?
    let dnsIps: [String]?
    let dnsServer: String?
    let statusCodesCsv: String?
    let contactGroups: [String]?
    let regions: [String]?
}
