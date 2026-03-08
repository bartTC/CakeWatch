import Foundation

struct UptimeTestsResponse: Codable {
    let data: [UptimeCheckOverview]
}

struct UptimeTestResponse: Codable {
    let data: UptimeCheckDetail
}

struct UptimeCheckOverview: Codable, Identifiable {
    var id: String
    var name: String
    var websiteUrl: String
    var testType: String
    var checkRate: Int
    var paused: Bool
    var status: String
    var tags: [String]
    var uptime: Double?

    var accountId: String = ""
    var accountName: String = ""

    var sortableUptime: Double { uptime ?? -1 }
    var sortableStatus: Int { paused ? 2 : status == "up" ? 0 : 1 }

    enum CodingKeys: String, CodingKey {
        case id, name, websiteUrl, testType, checkRate, paused, status, tags, uptime
    }
}

struct UptimeCheckDetail: Codable, Identifiable {
    var id: String
    var name: String
    var websiteUrl: String
    var testType: String
    var checkRate: Int
    var paused: Bool
    var status: String
    var tags: [String]
    var uptime: Double?
    var confirmation: Int?
    var timeout: Int?
    var triggerRate: Int?
    var lastTestedAt: String?
    var followRedirects: Bool?
    var enableSslAlert: Bool?
    var findString: String?
    var doNotFind: Bool?
    var host: String?
    var port: Int?
    var userAgent: String?
    var statusCodes: [String]?
    var processing: Bool?
    var includeHeader: Bool?
    var useJar: Bool?
    var basicUsername: String?
    var basicPassword: String?
    var customHeader: String?
    var postBody: String?
    var postRaw: String?
    var finalEndpoint: String?
    var dnsIps: [String]?
    var dnsServer: String?
    var statusCodesCsv: String?
    var contactGroups: [String]?
    var regions: [String]?

    var accountId: String = ""
    var accountName: String = ""

    enum CodingKeys: String, CodingKey {
        case id, name, websiteUrl, testType, checkRate, paused, status, tags, uptime
        case confirmation, timeout, triggerRate, lastTestedAt, followRedirects, enableSslAlert
        case findString, doNotFind, host, port, userAgent, statusCodes, processing
        case includeHeader, useJar, basicUsername, basicPassword, customHeader
        case postBody, postRaw, finalEndpoint, dnsIps, dnsServer, statusCodesCsv
        case contactGroups, regions
    }
}
