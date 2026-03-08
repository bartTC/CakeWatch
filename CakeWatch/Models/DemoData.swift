import Foundation

enum DemoData {
    static let accountId = "demo-account"
    static let accountName = "Demo"

    static let account = Account(id: accountId, name: accountName, apiKey: "demo")

    static let checks: [UptimeCheckOverview] = [
        UptimeCheckOverview(
            id: "1001", name: "Acme Corp Website", websiteUrl: "https://www.acmecorp.com",
            testType: "HTTP", checkRate: 300, paused: false, status: "up", tags: ["production", "web"], uptime: 100.0,
            accountId: accountId, accountName: accountName
        ),
        UptimeCheckOverview(
            id: "1002", name: "Payment Gateway", websiteUrl: "https://pay.acmecorp.com",
            testType: "HTTP", checkRate: 60, paused: false, status: "up", tags: ["production", "critical"], uptime: 100.0,
            accountId: accountId, accountName: accountName
        ),
        UptimeCheckOverview(
            id: "1003", name: "Staging API", websiteUrl: "https://api-staging.acmecorp.com",
            testType: "HTTP", checkRate: 900, paused: false, status: "down", tags: ["staging"], uptime: 97.2,
            accountId: accountId, accountName: accountName
        ),
        UptimeCheckOverview(
            id: "1004", name: "Blog CDN", websiteUrl: "https://blog.acmecorp.com",
            testType: "HTTP", checkRate: 600, paused: false, status: "up", tags: ["production"], uptime: 100.0,
            accountId: accountId, accountName: accountName
        ),
        UptimeCheckOverview(
            id: "1005", name: "Mail Server", websiteUrl: "mail.acmecorp.com",
            testType: "SMTP", checkRate: 300, paused: false, status: "up", tags: ["production", "email"], uptime: 100.0,
            accountId: accountId, accountName: accountName
        ),
        UptimeCheckOverview(
            id: "1006", name: "DNS Primary", websiteUrl: "ns1.acmecorp.com",
            testType: "DNS", checkRate: 600, paused: false, status: "up", tags: ["infrastructure"], uptime: 100.0,
            accountId: accountId, accountName: accountName
        ),
        UptimeCheckOverview(
            id: "1007", name: "Database Monitor", websiteUrl: "db.internal.acmecorp.com",
            testType: "TCP", checkRate: 300, paused: true, status: "up", tags: ["internal"], uptime: 100.0,
            accountId: accountId, accountName: accountName
        ),
        UptimeCheckOverview(
            id: "1008", name: "Dev Server", websiteUrl: "dev.acmecorp.com",
            testType: "PING", checkRate: 1800, paused: false, status: "down", tags: ["development"], uptime: 98.7,
            accountId: accountId, accountName: accountName
        ),
    ]

    static func detail(for id: String) -> UptimeCheckDetail? {
        guard let overview = checks.first(where: { $0.id == id }) else { return nil }
        return UptimeCheckDetail(
            id: overview.id,
            name: overview.name,
            websiteUrl: overview.websiteUrl,
            testType: overview.testType,
            checkRate: overview.checkRate,
            paused: overview.paused,
            status: overview.status,
            tags: overview.tags,
            uptime: overview.uptime,
            confirmation: 3,
            timeout: 30,
            triggerRate: 5,
            lastTestedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-120)),
            followRedirects: true,
            enableSslAlert: overview.testType == "HTTP",
            statusCodes: overview.testType == "HTTP" ? ["200", "204", "301"] : nil,
            contactGroups: ["Default Alerts"],
            regions: ["london", "new_york", "tokyo"],
            accountId: accountId,
            accountName: accountName
        )
    }

    static func history(for id: String) -> [UptimeHistoryResult] {
        let now = Date()
        let count = 48
        return (0..<count).map { i in
            let time = now.addingTimeInterval(Double(-i) * 1800) // every 30 min
            let basePerf: Int
            switch id {
            case "1003": basePerf = 450 // staging API is slower
            case "1002": basePerf = 120 // payment gateway is fast
            default: basePerf = 250
            }
            let jitter = Int.random(in: -80...80)
            return UptimeHistoryResult(
                createdAt: time,
                location: ["london", "new_york", "tokyo", "singapore"].randomElement(),
                performance: max(50, basePerf + jitter),
                statusCode: id == "1003" && i < 3 ? 503 : 200
            )
        }
    }

    // Deterministic seed based on check id so periods are stable across launches
    static func periods(for id: String) -> [UptimePeriod] {
        let now = Date()
        let day: TimeInterval = 86400
        let hour: TimeInterval = 3600

        if id == "1003" {
            // Currently down — Staging API
            return [
                UptimePeriod(status: "down", createdAt: now.addingTimeInterval(-45 * 60), endedAt: nil, duration: nil),
                period(now, daysAgo: 3, durationMin: 25),
                period(now, daysAgo: 12, durationMin: 8),
                period(now, daysAgo: 28, durationMin: 45),
                period(now, daysAgo: 67, durationMin: 120),
                period(now, daysAgo: 95, durationMin: 15),
                period(now, daysAgo: 140, durationMin: 35),
                period(now, daysAgo: 188, durationMin: 90),
                period(now, daysAgo: 230, durationMin: 10),
                period(now, daysAgo: 290, durationMin: 55),
                period(now, daysAgo: 340, durationMin: 5),
            ]
        }

        if id == "1008" {
            // Currently down — Dev Server
            return [
                UptimePeriod(status: "down", createdAt: now.addingTimeInterval(-12 * 60), endedAt: nil, duration: nil),
                period(now, daysAgo: 8, durationMin: 40),
                period(now, daysAgo: 21, durationMin: 15),
                period(now, daysAgo: 55, durationMin: 90),
                period(now, daysAgo: 102, durationMin: 6),
                period(now, daysAgo: 160, durationMin: 25),
                period(now, daysAgo: 200, durationMin: 120),
                period(now, daysAgo: 260, durationMin: 10),
                period(now, daysAgo: 310, durationMin: 50),
                period(now, daysAgo: 355, durationMin: 8),
            ]
        }

        // Other checks: currently up, with ~10 past incidents over the year
        return [
            UptimePeriod(status: "up", createdAt: now.addingTimeInterval(-5 * 86400), endedAt: nil, duration: nil),
            period(now, daysAgo: 5, durationMin: 3),
            period(now, daysAgo: 18, durationMin: 12),
            period(now, daysAgo: 42, durationMin: 7),
            period(now, daysAgo: 78, durationMin: 22),
            period(now, daysAgo: 105, durationMin: 45),
            period(now, daysAgo: 153, durationMin: 2),
            period(now, daysAgo: 190, durationMin: 18),
            period(now, daysAgo: 240, durationMin: 60),
            period(now, daysAgo: 295, durationMin: 8),
            period(now, daysAgo: 350, durationMin: 30),
        ]
    }

    /// Helper to create a resolved downtime period
    private static func period(_ now: Date, daysAgo: Int, durationMin: Int) -> UptimePeriod {
        let start = now.addingTimeInterval(-Double(daysAgo) * 86400)
        let durationSec = Double(durationMin) * 60
        return UptimePeriod(
            status: "down",
            createdAt: start,
            endedAt: start.addingTimeInterval(durationSec),
            duration: durationMin * 60 * 1000 // milliseconds
        )
    }
}
