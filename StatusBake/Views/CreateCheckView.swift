import SwiftUI

struct CreateCheckView: View {
    var onCreate: (([String: String]) async -> Void)?
    @Environment(\.dismiss) var dismiss

    // Required
    @State var name = ""
    @State var testType = "HTTP"
    @State var websiteUrl = ""
    @State var checkRate = 300

    // Monitoring
    @State var timeout = 15
    @State var triggerRate = 0
    @State var confirmation = 2
    @State var paused = false
    @State var followRedirects = false
    @State var enableSslAlert = false

    // Content matching
    @State var findString = ""
    @State var doNotFind = false
    @State var includeHeader = false

    // Advanced
    @State var tags = ""
    @State var statusCodesCsv = ""
    @State var userAgent = ""
    @State var host = ""
    @State var port = ""
    @State var basicUsername = ""
    @State var basicPassword = ""
    @State var customHeader = ""
    @State var useJar = false

    // DNS
    @State var dnsServer = ""
    @State var dnsIps = ""

    @State var isCreating = false

    var isValid: Bool {
        !name.isEmpty && !websiteUrl.isEmpty
    }

    var showContentMatching: Bool {
        testType == "HTTP" || testType == "HEAD"
    }

    @ViewBuilder
    var formContent: some View {
        requiredSection
        monitoringSection
        if showContentMatching { contentMatchingSection }
        advancedSection
        if testType == "DNS" { dnsSection }
    }

    @ViewBuilder
    private var requiredSection: some View {
        Section("Required") {
            TextField("Name", text: $name)
            Picker("Test Type", selection: $testType) {
                ForEach(testTypeOptions, id: \.self) { Text($0).tag($0) }
            }
            TextField("Website URL", text: $websiteUrl)
            Picker("Check Rate", selection: $checkRate) {
                ForEach(checkRateOptions, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
        }
    }

    @ViewBuilder
    private var monitoringSection: some View {
        Section("Monitoring") {
            Toggle("Paused", isOn: $paused)
            Picker("Timeout", selection: $timeout) {
                ForEach(timeoutOptions, id: \.self) { Text("\($0)s").tag($0) }
            }
            Picker("Trigger Rate", selection: $triggerRate) {
                ForEach(triggerRateOptions, id: \.self) { min in
                    Text(min == 0 ? "Immediately" : "\(min) min").tag(min)
                }
            }
            Picker("Confirmation", selection: $confirmation) {
                ForEach(confirmationRange, id: \.self) { count in
                    Text("\(count) server\(count == 1 ? "" : "s")").tag(count)
                }
            }
            Toggle("Follow Redirects", isOn: $followRedirects)
            Toggle("Enable SSL Alert", isOn: $enableSslAlert)
        }
    }

    @ViewBuilder
    private var contentMatchingSection: some View {
        Section("Content Matching") {
            TextField("Find String", text: $findString)
            Toggle("Do Not Find", isOn: $doNotFind)
            Toggle("Include Header", isOn: $includeHeader)
        }
    }

    @ViewBuilder
    private var advancedSection: some View {
        Section("Advanced") {
            TextField("Tags (comma-separated)", text: $tags)
            TextField("Status Codes (comma-separated)", text: $statusCodesCsv)
            TextField("User Agent", text: $userAgent)
            TextField("Host", text: $host)
            if testType == "TCP" {
                TextField("Port", text: $port)
            }
            TextField("Basic Auth Username", text: $basicUsername)
            SecureField("Basic Auth Password", text: $basicPassword)
            TextField("Custom Header (JSON)", text: $customHeader)
            Toggle("Use Cookie Jar", isOn: $useJar)
        }
    }

    @ViewBuilder
    private var dnsSection: some View {
        Section("DNS") {
            TextField("DNS Server", text: $dnsServer)
            TextField("DNS IPs (comma-separated)", text: $dnsIps)
        }
    }

    func create() {
        isCreating = true
        var fields: [String: String] = [
            "name": name,
            "test_type": testType,
            "website_url": websiteUrl,
            "check_rate": "\(checkRate)",
            "timeout": "\(timeout)",
            "trigger_rate": "\(triggerRate)",
            "confirmation": "\(confirmation)",
        ]
        if paused { fields["paused"] = "true" }
        if followRedirects { fields["follow_redirects"] = "true" }
        if enableSslAlert { fields["enable_ssl_alert"] = "true" }
        if !findString.isEmpty { fields["find_string"] = findString }
        if doNotFind { fields["do_not_find"] = "true" }
        if includeHeader { fields["include_header"] = "true" }
        if !tags.isEmpty { fields["tags"] = tags }
        if !statusCodesCsv.isEmpty { fields["status_codes_csv"] = statusCodesCsv }
        if !userAgent.isEmpty { fields["user_agent"] = userAgent }
        if !host.isEmpty { fields["host"] = host }
        if !port.isEmpty { fields["port"] = port }
        if !basicUsername.isEmpty { fields["basic_username"] = basicUsername }
        if !basicPassword.isEmpty { fields["basic_password"] = basicPassword }
        if !customHeader.isEmpty { fields["custom_header"] = customHeader }
        if useJar { fields["use_jar"] = "true" }
        if !dnsServer.isEmpty { fields["dns_server"] = dnsServer }
        if !dnsIps.isEmpty { fields["dns_ips"] = dnsIps }

        Task {
            await onCreate?(fields)
            dismiss()
        }
    }
}
