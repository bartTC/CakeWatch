import Testing
import Foundation
@testable import CakeWatch

// MARK: - UptimeCheckOverview Decoding

struct OverviewDecodingTests {
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    @Test func decodesFullOverview() throws {
        let json = """
        {
            "data": [{
                "id": "123",
                "name": "My Site",
                "website_url": "https://example.com",
                "test_type": "HTTP",
                "check_rate": 300,
                "paused": false,
                "status": "up",
                "tags": ["prod", "web"],
                "uptime": 99.95
            }]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(UptimeTestsResponse.self, from: json)
        #expect(response.data.count == 1)
        let check = response.data[0]
        #expect(check.id == "123")
        #expect(check.name == "My Site")
        #expect(check.websiteUrl == "https://example.com")
        #expect(check.testType == "HTTP")
        #expect(check.checkRate == 300)
        #expect(check.paused == false)
        #expect(check.status == "up")
        #expect(check.tags == ["prod", "web"])
        #expect(check.uptime == 99.95)
    }

    @Test func decodesNullUptime() throws {
        let json = """
        {
            "data": [{
                "id": "1",
                "name": "Test",
                "website_url": "https://test.com",
                "test_type": "HTTP",
                "check_rate": 60,
                "paused": false,
                "status": "up",
                "tags": [],
                "uptime": null
            }]
        }
        """.data(using: .utf8)!

        let check = try decoder.decode(UptimeTestsResponse.self, from: json).data[0]
        #expect(check.uptime == nil)
        #expect(check.sortableUptime == -1)
    }

    @Test func decodesEmptyList() throws {
        let json = """
        {"data": []}
        """.data(using: .utf8)!

        let response = try decoder.decode(UptimeTestsResponse.self, from: json)
        #expect(response.data.isEmpty)
    }

    @Test func accountFieldsDefaultToEmpty() throws {
        let json = """
        {
            "data": [{
                "id": "1",
                "name": "Test",
                "website_url": "https://test.com",
                "test_type": "HTTP",
                "check_rate": 60,
                "paused": false,
                "status": "up",
                "tags": [],
                "uptime": null
            }]
        }
        """.data(using: .utf8)!

        let check = try decoder.decode(UptimeTestsResponse.self, from: json).data[0]
        #expect(check.accountId == "")
        #expect(check.accountName == "")
    }

    @Test func sortableStatusValues() {
        var check = UptimeCheckOverview(
            id: "1", name: "Test", websiteUrl: "https://test.com",
            testType: "HTTP", checkRate: 300, paused: false, status: "up", tags: []
        )
        #expect(check.sortableStatus == 0)

        check.status = "down"
        #expect(check.sortableStatus == 1)

        check.paused = true
        #expect(check.sortableStatus == 2)
    }
}

// MARK: - UptimeCheckDetail Decoding

struct DetailDecodingTests {
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    @Test func decodesFullDetail() throws {
        let json = """
        {
            "data": {
                "id": "456",
                "name": "API Server",
                "website_url": "https://api.example.com",
                "test_type": "HTTP",
                "check_rate": 60,
                "paused": false,
                "status": "up",
                "tags": ["api"],
                "uptime": 100.0,
                "confirmation": 2,
                "timeout": 30,
                "trigger_rate": 5,
                "last_tested_at": "2025-01-15T12:00:00Z",
                "follow_redirects": true,
                "enable_ssl_alert": false,
                "find_string": "OK",
                "do_not_find": false,
                "host": "api.example.com",
                "port": 443,
                "user_agent": "CakeWatch/1.0",
                "status_codes": ["200", "201"],
                "processing": false,
                "include_header": false,
                "use_jar": true,
                "basic_username": "user",
                "basic_password": "pass",
                "custom_header": "X-Custom: value",
                "post_body": "key=value",
                "post_raw": "",
                "final_endpoint": "https://api.example.com/health",
                "dns_ips": ["1.1.1.1"],
                "dns_server": "8.8.8.8",
                "status_codes_csv": "200,201",
                "contact_groups": ["group1"],
                "regions": ["US", "EU"]
            }
        }
        """.data(using: .utf8)!

        let detail = try decoder.decode(UptimeTestResponse.self, from: json).data
        #expect(detail.id == "456")
        #expect(detail.confirmation == 2)
        #expect(detail.timeout == 30)
        #expect(detail.triggerRate == 5)
        #expect(detail.followRedirects == true)
        #expect(detail.enableSslAlert == false)
        #expect(detail.findString == "OK")
        #expect(detail.port == 443)
        #expect(detail.statusCodes == ["200", "201"])
        #expect(detail.useJar == true)
        #expect(detail.dnsIps == ["1.1.1.1"])
        #expect(detail.regions == ["US", "EU"])
    }

    @Test func decodesMinimalDetail() throws {
        let json = """
        {
            "data": {
                "id": "789",
                "name": "Minimal",
                "website_url": "https://min.com",
                "test_type": "PING",
                "check_rate": 300,
                "paused": true,
                "status": "down",
                "tags": []
            }
        }
        """.data(using: .utf8)!

        let detail = try decoder.decode(UptimeTestResponse.self, from: json).data
        #expect(detail.id == "789")
        #expect(detail.paused == true)
        #expect(detail.confirmation == nil)
        #expect(detail.timeout == nil)
        #expect(detail.findString == nil)
        #expect(detail.statusCodes == nil)
        #expect(detail.regions == nil)
    }
}

// MARK: - UptimeHistory Decoding

struct HistoryDecodingTests {
    private var iso8601Decoder: JSONDecoder {
        let d = JSONDecoder()
        let isoFormatter: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        let isoFormatterNoFrac: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = isoFormatter.date(from: str) { return date }
            if let date = isoFormatterNoFrac.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return d
    }

    @Test func decodesHistoryWithFractionalSeconds() throws {
        let json = """
        {
            "data": [{
                "created_at": "2025-01-15T12:30:45.123Z",
                "location": "US",
                "performance": 250,
                "status_code": 200
            }]
        }
        """.data(using: .utf8)!

        let result = try iso8601Decoder.decode(UptimeHistoryResponse.self, from: json).data[0]
        #expect(result.location == "US")
        #expect(result.performance == 250)
        #expect(result.statusCode == 200)
    }

    @Test func decodesHistoryWithoutFractionalSeconds() throws {
        let json = """
        {
            "data": [{
                "created_at": "2025-01-15T12:30:45Z",
                "location": "EU",
                "performance": 100,
                "status_code": 200
            }]
        }
        """.data(using: .utf8)!

        let result = try iso8601Decoder.decode(UptimeHistoryResponse.self, from: json).data[0]
        #expect(result.location == "EU")
        #expect(result.performance == 100)
    }

    @Test func decodesHistoryWithNullFields() throws {
        let json = """
        {
            "data": [{
                "created_at": "2025-01-15T12:00:00Z",
                "location": null,
                "performance": null,
                "status_code": null
            }]
        }
        """.data(using: .utf8)!

        let result = try iso8601Decoder.decode(UptimeHistoryResponse.self, from: json).data[0]
        #expect(result.location == nil)
        #expect(result.performance == nil)
        #expect(result.statusCode == nil)
    }

    @Test func historyIdIsUnique() throws {
        let json = """
        {
            "data": [
                {"created_at": "2025-01-15T12:00:00Z", "location": "US", "performance": 100, "status_code": 200},
                {"created_at": "2025-01-15T12:00:00Z", "location": "EU", "performance": 150, "status_code": 200},
                {"created_at": "2025-01-15T12:01:00Z", "location": "US", "performance": 110, "status_code": 200}
            ]
        }
        """.data(using: .utf8)!

        let results = try iso8601Decoder.decode(UptimeHistoryResponse.self, from: json).data
        let ids = Set(results.map(\.id))
        #expect(ids.count == 3)
    }
}

// MARK: - UptimePeriod Decoding

struct PeriodDecodingTests {
    private var iso8601Decoder: JSONDecoder {
        let d = JSONDecoder()
        let isoFormatter: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        let isoFormatterNoFrac: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = isoFormatter.date(from: str) { return date }
            if let date = isoFormatterNoFrac.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return d
    }

    @Test func decodesPeriodsWithPagination() throws {
        let json = """
        {
            "data": [{
                "status": "down",
                "created_at": "2025-01-15T10:00:00Z",
                "ended_at": "2025-01-15T10:05:00Z",
                "duration": 300
            }],
            "links": {
                "next": "https://api.statuscake.com/v1/uptime/123/periods?limit=100&after=abc"
            }
        }
        """.data(using: .utf8)!

        let response = try iso8601Decoder.decode(UptimePeriodsResponse.self, from: json)
        #expect(response.data.count == 1)
        #expect(response.data[0].status == "down")
        #expect(response.data[0].duration == 300)
        #expect(response.data[0].endedAt != nil)
        #expect(response.links?.next != nil)
    }

    @Test func decodesPeriodsWithoutPagination() throws {
        let json = """
        {
            "data": [{
                "status": "up",
                "created_at": "2025-01-15T10:05:00Z",
                "ended_at": null,
                "duration": null
            }],
            "links": {
                "next": null
            }
        }
        """.data(using: .utf8)!

        let response = try iso8601Decoder.decode(UptimePeriodsResponse.self, from: json)
        #expect(response.data[0].endedAt == nil)
        #expect(response.data[0].duration == nil)
        #expect(response.links?.next == nil)
    }

    @Test func decodesPeriodsWithNoLinks() throws {
        let json = """
        {
            "data": []
        }
        """.data(using: .utf8)!

        let response = try iso8601Decoder.decode(UptimePeriodsResponse.self, from: json)
        #expect(response.data.isEmpty)
        #expect(response.links == nil)
    }
}

// MARK: - Account

struct AccountTests {
    @Test func encodesAndDecodes() throws {
        let account = Account(name: "Production", apiKey: "abc123")
        let data = try JSONEncoder().encode(account)
        let decoded = try JSONDecoder().decode(Account.self, from: data)
        #expect(decoded.id == account.id)
        #expect(decoded.name == "Production")
        #expect(decoded.apiKey == "abc123")
    }

    @Test func generatesUniqueIds() {
        let a = Account(name: "A", apiKey: "key1")
        let b = Account(name: "B", apiKey: "key2")
        #expect(a.id != b.id)
    }
}

// MARK: - CreateCheck Response Decoding

struct CreateCheckResponseTests {
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    @Test func decodesNewCheckId() throws {
        let json = """
        {
            "data": {
                "new_id": "999"
            }
        }
        """.data(using: .utf8)!

        struct CreateResponse: Codable {
            struct NewCheck: Codable {
                let newId: String
            }
            let data: NewCheck
        }
        let response = try decoder.decode(CreateResponse.self, from: json)
        #expect(response.data.newId == "999")
    }
}

// MARK: - APIError

struct APIErrorTests {
    @Test func invalidURLDescription() {
        let error = APIError.invalidURL("bad://url")
        #expect(error.errorDescription == "Invalid URL: bad://url")
    }

    @Test func requestFailedDescription() {
        let error = APIError.requestFailed(statusCode: 404, message: "Not Found")
        #expect(error.errorDescription == "Request failed (404): Not Found")
    }
}
