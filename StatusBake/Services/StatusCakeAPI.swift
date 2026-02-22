import Foundation

enum APIError: LocalizedError {
    case requestFailed(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let code, let message):
            return "Request failed (\(code)): \(message)"
        }
    }
}

final class StatusCakeAPI {
    static let shared = StatusCakeAPI()

    private let baseURL = "https://api.statuscake.com/v1"
    private let session = URLSession.shared
    private let maxRetries = 3
    private var minRequestInterval: TimeInterval {
        let rps = UserDefaults.standard.integer(forKey: "maxRequestsPerSecond")
        return 1.0 / Double(rps > 0 ? rps : 4)
    }
    private var lastRequestTime: Date = .distantPast

    private func request(path: String, method: String = "GET", apiKey: String) -> URLRequest {
        var req = URLRequest(url: URL(string: baseURL + path)!)
        req.httpMethod = method
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return req
    }

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    private func throttle() async throws {
        let elapsed = Date().timeIntervalSince(lastRequestTime)
        if elapsed < minRequestInterval {
            try await Task.sleep(for: .seconds(minRequestInterval - elapsed))
        }
        lastRequestTime = Date()
    }

    private func perform(_ req: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await throttle()
        for attempt in 0..<maxRetries {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            if http.statusCode == 429 {
                let resetAfter = http.value(forHTTPHeaderField: "x-ratelimit-reset")
                    .flatMap(Double.init) ?? Double(attempt + 1)
                let delay = max(resetAfter, 1)
                try await Task.sleep(for: .seconds(delay))
                continue
            }

            try checkStatus(data: data, http: http)
            return (data, http)
        }

        // Final attempt without retry
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        try checkStatus(data: data, http: http)
        return (data, http)
    }

    private func checkStatus(data: Data, http: HTTPURLResponse) throws {
        guard !(200...299).contains(http.statusCode) else { return }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw APIError.requestFailed(statusCode: http.statusCode, message: "Invalid or missing API key.")
        }
        let body = String(data: data, encoding: .utf8) ?? "Unknown error"
        throw APIError.requestFailed(statusCode: http.statusCode, message: body)
    }

    func listChecks(apiKey: String) async throws -> [UptimeCheckOverview] {
        let (data, _) = try await perform(request(path: "/uptime?limit=100", apiKey: apiKey))
        return try decoder.decode(UptimeTestsResponse.self, from: data).data
    }

    func getCheck(id: String, apiKey: String) async throws -> UptimeCheckDetail {
        let (data, _) = try await perform(request(path: "/uptime/\(id)", apiKey: apiKey))
        return try decoder.decode(UptimeTestResponse.self, from: data).data
    }

    func updateCheck(id: String, fields: [String: String], apiKey: String) async throws {
        var req = request(path: "/uptime/\(id)", method: "PUT", apiKey: apiKey)
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = fields.map { URLQueryItem(name: $0.key, value: $0.value) }
        req.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        let (data, http) = try await perform(req)
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.requestFailed(statusCode: http.statusCode, message: body)
        }
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterNoFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private var iso8601Decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = StatusCakeAPI.isoFormatter.date(from: str) { return date }
            if let date = StatusCakeAPI.isoFormatterNoFrac.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return d
    }

    func getHistory(id: String, apiKey: String) async throws -> [UptimeHistoryResult] {
        let (data, _) = try await perform(request(path: "/uptime/\(id)/history?limit=100", apiKey: apiKey))
        return try iso8601Decoder.decode(UptimeHistoryResponse.self, from: data).data
    }

    struct PeriodsPage {
        let periods: [UptimePeriod]
        let nextURL: String?
    }

    func getPeriods(id: String, apiKey: String) async throws -> PeriodsPage {
        return try await fetchPeriodsPage(path: "/uptime/\(id)/periods?limit=100", apiKey: apiKey)
    }

    func getMorePeriods(nextURL: String, apiKey: String) async throws -> PeriodsPage {
        guard let url = URL(string: nextURL),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return PeriodsPage(periods: [], nextURL: nil)
        }
        let path = components.path.replacingOccurrences(of: "/v1", with: "") + "?" + (components.query ?? "")
        return try await fetchPeriodsPage(path: path, apiKey: apiKey)
    }

    private func fetchPeriodsPage(path: String, apiKey: String) async throws -> PeriodsPage {
        let (data, _) = try await perform(request(path: path, apiKey: apiKey))
        let response = try iso8601Decoder.decode(UptimePeriodsResponse.self, from: data)
        return PeriodsPage(periods: response.data, nextURL: response.links?.next)
    }

    func createCheck(fields: [String: String], apiKey: String) async throws -> String {
        var req = request(path: "/uptime", method: "POST", apiKey: apiKey)
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = fields.map { URLQueryItem(name: $0.key, value: $0.value) }
        req.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        let (data, http) = try await perform(req)
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.requestFailed(statusCode: http.statusCode, message: body)
        }
        struct CreateResponse: Codable {
            struct NewCheck: Codable {
                let newId: String
            }
            let data: NewCheck
        }
        let decoded = try decoder.decode(CreateResponse.self, from: data)
        return decoded.data.newId
    }

    func deleteCheck(id: String, apiKey: String) async throws {
        let (data, http) = try await perform(request(path: "/uptime/\(id)", method: "DELETE", apiKey: apiKey))
        guard http.statusCode == 204 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.requestFailed(statusCode: http.statusCode, message: body)
        }
    }
}
